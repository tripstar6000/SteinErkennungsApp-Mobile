import 'package:flutter_test/flutter_test.dart';
import 'package:steinerkennungsapp/core/app_config.dart';

void main() {
  test('Standortpraezision ist auf zwei Dezimalstellen konfiguriert', () {
    expect(AppConfig.reducedLocationDecimals, 2);
  });
}
