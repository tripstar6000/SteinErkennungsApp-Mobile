import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:steinerkennungsapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App startet und zeigt zentrale Navigation', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    expect(find.text('SteinErkennungsApp'), findsWidgets);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Sammlung'), findsOneWidget);
    expect(find.text('Einstellungen'), findsOneWidget);
  });
}
