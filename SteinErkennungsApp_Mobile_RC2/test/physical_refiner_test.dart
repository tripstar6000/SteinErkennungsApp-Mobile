import 'package:flutter_test/flutter_test.dart';
import 'package:steinerkennungsapp/domain/models.dart';
import 'package:steinerkennungsapp/services/physical_refiner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Quarz wird durch Mohs 7 gestuetzt', () async {
    final refiner = PhysicalRefiner();
    final result = await refiner.refine(
      const [
        ScanPrediction(
          name: 'Quarz',
          visualFit: 60,
          reason: 'test',
        ),
        ScanPrediction(
          name: 'Calcit',
          visualFit: 60,
          reason: 'test',
        ),
      ],
      const PhysicalInputs(hardness: 7),
    );

    expect(result.first.name, 'Quarz');
    expect(result.first.adjustedFit, greaterThan(60));
  });
}
