from pathlib import Path
import json, re, sys

root = Path(__file__).resolve().parents[1]
required = [
    'pubspec.yaml',
    'lib/main.dart',
    'lib/app.dart',
    'assets/data/stones_de.json',
    'assets/data/physical_profiles.json',
    'README.md',
    'ARCHITECTURE.md',
    'SECURITY.md',
    'PRIVACY.md',
    'ML_MODEL.md',
]
errors = []
for rel in required:
    if not (root / rel).exists():
        errors.append(f'missing: {rel}')

catalog = json.loads((root / 'assets/data/stones_de.json').read_text(encoding='utf-8'))
if len(catalog) < 70:
    errors.append(f'catalog too small: {len(catalog)}')

pubspec = (root / 'pubspec.yaml').read_text(encoding='utf-8')
for asset in ['assets/data/', 'assets/l10n/', 'assets/ml/labels.txt']:
    if asset not in pubspec:
        errors.append(f'asset not declared: {asset}')

for dart in root.glob('lib/**/*.dart'):
    text = dart.read_text(encoding='utf-8')
    if 'API_KEY=' in text or 'sk-' in text:
        errors.append(f'possible secret in {dart.relative_to(root)}')
    if text.count('{') != text.count('}'):
        errors.append(f'brace mismatch in {dart.relative_to(root)}')

if errors:
    print('STATIC VALIDATION FAILED')
    for e in errors:
        print('-', e)
    sys.exit(1)

print(f'STATIC VALIDATION PASS: {len(catalog)} catalog entries, required files/assets present, no obvious embedded API key.')
