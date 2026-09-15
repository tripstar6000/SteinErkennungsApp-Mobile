class AppConfig {
  static const String appName = 'SteinErkennungsApp';
  static const String apiBaseUrl =
      'https://steinerkennungsapp-o1oljh.v2.appdeploy.ai';

  static const int maxScanPhotos = 3;
  static const int minScanPhotos = 2;
  static const int maxImageDimension = 1400;

  static const String modelPackageId = 'stone-classifier-v1';
  static const String modelFileName = 'stone_classifier.tflite';
  static const String modelChecksumFileName = 'stone_classifier.sha256';

  static const int reducedLocationDecimals = 2;
}
