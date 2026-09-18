class AppConfig {
  static const String appName = 'SteinErkennungsApp';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-v2.appdeploy.ai/app/steinerkennungsapp-o1oljh',
  );

  static const int maxScanPhotos = 3;
  static const int minScanPhotos = 2;
  static const int maxImageDimension = 1400;

  static const String modelPackageId = 'stone-classifier-v1';
  static const String modelFileName = 'stone_classifier.tflite';
  static const String modelChecksumFileName = 'stone_classifier.sha256';

  static const int reducedLocationDecimals = 2;
}
