import argparse
import hashlib
import json
import os
import random
from pathlib import Path

import numpy as np
import tensorflow as tf
from datasets import load_dataset

SEED = 20260915


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def image_to_np(example, size):
    image = example['image'].convert('RGB').resize((size, size))
    example['pixel_values'] = np.asarray(image, dtype=np.float32)
    return example


def discover_label_names(dataset):
    feature = dataset.features.get('label')
    names = getattr(feature, 'names', None)
    if names:
        return [str(x) for x in names]
    unique = sorted(set(int(x) for x in dataset['label']))
    return [str(x) for x in unique]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output-dir', default='assets/ml')
    parser.add_argument('--image-size', type=int, default=224)
    parser.add_argument('--epochs-head', type=int, default=3)
    parser.add_argument('--epochs-finetune', type=int, default=2)
    parser.add_argument('--batch-size', type=int, default=32)
    parser.add_argument('--max-examples', type=int, default=0,
                        help='0 = complete dataset; positive = deterministic subset for smoke runs')
    args = parser.parse_args()

    random.seed(SEED)
    np.random.seed(SEED)
    tf.random.set_seed(SEED)

    out = Path(args.output_dir)
    out.mkdir(parents=True, exist_ok=True)

    ds = load_dataset('udayl/rocks', split='train')
    if args.max_examples > 0 and args.max_examples < len(ds):
        ds = ds.shuffle(seed=SEED).select(range(args.max_examples))

    labels = discover_label_names(ds)
    class_count = len(labels)
    if class_count < 2:
        raise RuntimeError(f'Invalid class count: {class_count}')

    # Stratified split where supported.
    split1 = ds.train_test_split(
        test_size=0.20,
        seed=SEED,
        stratify_by_column='label',
    )
    split2 = split1['test'].train_test_split(
        test_size=0.50,
        seed=SEED,
        stratify_by_column='label',
    )
    train_ds, val_ds, test_ds = split1['train'], split2['train'], split2['test']

    size = args.image_size

    def generator(hf_ds):
        for row in hf_ds:
            image = row['image'].convert('RGB').resize((size, size))
            yield np.asarray(image, dtype=np.float32), int(row['label'])

    sig = (
        tf.TensorSpec(shape=(size, size, 3), dtype=tf.float32),
        tf.TensorSpec(shape=(), dtype=tf.int32),
    )

    def tfds(hf_ds, training):
        d = tf.data.Dataset.from_generator(lambda: generator(hf_ds), output_signature=sig)
        if training:
            d = d.shuffle(min(len(hf_ds), 4096), seed=SEED)
        d = d.batch(args.batch_size).prefetch(tf.data.AUTOTUNE)
        return d

    train_tf = tfds(train_ds, True)
    val_tf = tfds(val_ds, False)
    test_tf = tfds(test_ds, False)

    augmentation = tf.keras.Sequential([
        tf.keras.layers.RandomFlip('horizontal'),
        tf.keras.layers.RandomRotation(0.08),
        tf.keras.layers.RandomZoom(0.10),
        tf.keras.layers.RandomContrast(0.10),
    ], name='augmentation')

    base = tf.keras.applications.MobileNetV3Small(
        include_top=False,
        weights='imagenet',
        input_shape=(size, size, 3),
        pooling='avg',
        include_preprocessing=True,
    )
    base.trainable = False

    inputs = tf.keras.Input(shape=(size, size, 3), dtype=tf.float32, name='image_rgb_0_255')
    x = augmentation(inputs)
    x = base(x, training=False)
    x = tf.keras.layers.Dropout(0.25)(x)
    outputs = tf.keras.layers.Dense(class_count, activation='softmax', name='probabilities')(x)
    model = tf.keras.Model(inputs, outputs)

    model.compile(
        optimizer=tf.keras.optimizers.Adam(1e-3),
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy', tf.keras.metrics.SparseTopKCategoricalAccuracy(k=min(3, class_count), name='top3')],
    )
    model.fit(
        train_tf,
        validation_data=val_tf,
        epochs=args.epochs_head,
        callbacks=[tf.keras.callbacks.EarlyStopping(patience=2, restore_best_weights=True)],
        verbose=2,
    )

    base.trainable = True
    freeze_until = int(len(base.layers) * 0.80)
    for layer in base.layers[:freeze_until]:
        layer.trainable = False

    model.compile(
        optimizer=tf.keras.optimizers.Adam(1e-5),
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy', tf.keras.metrics.SparseTopKCategoricalAccuracy(k=min(3, class_count), name='top3')],
    )
    model.fit(
        train_tf,
        validation_data=val_tf,
        epochs=args.epochs_finetune,
        callbacks=[tf.keras.callbacks.EarlyStopping(patience=1, restore_best_weights=True)],
        verbose=2,
    )

    metrics = model.evaluate(test_tf, return_dict=True, verbose=2)

    # Confusion matrix on held-out test set.
    y_true = []
    y_pred = []
    for batch_x, batch_y in test_tf:
        probs = model.predict(batch_x, verbose=0)
        y_true.extend(batch_y.numpy().tolist())
        y_pred.extend(np.argmax(probs, axis=1).tolist())
    cm = tf.math.confusion_matrix(y_true, y_pred, num_classes=class_count).numpy().tolist()

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    # Dynamic-range quantization retains float32 input/output, matching app runtime.
    tflite = converter.convert()

    model_path = out / 'stone_classifier.tflite'
    labels_path = out / 'labels.txt'
    manifest_path = out / 'model_manifest.json'
    metrics_path = out / 'metrics.json'

    model_path.write_bytes(tflite)
    labels_path.write_text('\n'.join(labels) + '\n', encoding='utf-8')

    manifest = {
        'model_sha256': sha256(model_path),
        'labels_sha256': sha256(labels_path),
        'input_type': 'float32',
        'normalization': 'MobileNetV3 preprocessing embedded in model; app passes RGB float32 [0,255]',
        'class_count': class_count,
        'dataset': 'udayl/rocks',
        'dataset_license': 'MIT',
        'seed': SEED,
        'image_size': size,
        'split': {
            'train': len(train_ds),
            'validation': len(val_ds),
            'test': len(test_ds),
        },
    }
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding='utf-8')

    report = {
        'dataset': 'udayl/rocks',
        'dataset_license': 'MIT',
        'labels': labels,
        'test_metrics': {k: float(v) for k, v in metrics.items()},
        'confusion_matrix': cm,
        'note': 'Held-out split generated deterministically from the public dataset. '
                'These metrics do not replace validation on independent real-world stones/cameras.',
    }
    metrics_path.write_text(json.dumps(report, indent=2), encoding='utf-8')

    print(json.dumps(report['test_metrics'], indent=2))
    print('Model:', model_path, manifest['model_sha256'])
    print('Classes:', class_count)


if __name__ == '__main__':
    main()
