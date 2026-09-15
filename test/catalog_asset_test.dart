import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Kernkatalog ist lesbar und enthaelt mindestens 70 Eintraege', () async {
    final raw = await rootBundle.loadString('assets/data/stones_de.json');
    final data = jsonDecode(raw) as List;
    expect(data.length, greaterThanOrEqualTo(70));
  });
}
