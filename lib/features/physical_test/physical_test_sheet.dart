import 'package:flutter/material.dart';

import '../../services/physical_refiner.dart';

class PhysicalTestSheet extends StatefulWidget {
  const PhysicalTestSheet({super.key});

  @override
  State<PhysicalTestSheet> createState() => _PhysicalTestSheetState();
}

class _PhysicalTestSheetState extends State<PhysicalTestSheet> {
  String hardness = '';
  String streak = '';
  String magnetism = '';
  String transparency = '';
  final density = TextEditingController();

  static const hardnessHelp = {
    '1': 'Mohs 1: extrem weich, typischer Referenzwert Talk. Bereits mit sehr geringem Druck ritzbar.',
    '2': 'Mohs 2: weich, z. B. Gips. Mit dem Fingernagel meist gut ritzbar.',
    '2.5': 'Etwa Fingernagel-Grenzbereich. Ein sauberer Test sollte an einer unauffaelligen Stelle erfolgen.',
    '3': 'Mohs 3: Calcit-Referenz. Deutlich weicher als Glas.',
    '4': 'Mohs 4: Fluorit-Referenz. Haerter als Calcit, aber noch deutlich unter Glas.',
    '5': 'Mohs 5: mittlere Haerte. Messerstahl kann je nach Legierung als grober Vergleich dienen.',
    '5.5': 'Etwa Glas-Grenzbereich. Ein Mineral oberhalb davon kann normales Fensterglas ritzen.',
    '6': 'Mohs 6: typischer Feldspatbereich; ritzt Glas meist deutlich.',
    '6.5': 'Zwischen Feldspat und Quarz; typisch fuer mehrere Silikate.',
    '7': 'Mohs 7: Quarz-Referenz. Quarz ritzt Glas deutlich.',
    '7.5': 'Zwischen Quarz und Topas; relativ hart.',
    '8': 'Mohs 8: Topas-Referenz.',
    '9': 'Mohs 9: Korund-Referenz; sehr hart.',
    '10': 'Mohs 10: Diamant; hoechste Stufe der Mohs-Skala.',
  };

  static const streakHelp = {
    'weiß': 'Weisser Strich bedeutet, dass das fein abgeriebene Mineralpulver weiss erscheint. Viele Silikate zeigen einen weissen Strich.',
    'grau': 'Grauer Strich: Pulver erscheint grau. Immer auf unglasierter heller Porzellantafel pruefen.',
    'schwarz': 'Schwarzer Strich ist diagnostisch wichtig, z. B. bei Magnetit. Nicht mit schwarzer Oberflaechenfarbe verwechseln.',
    'braunschwarz': 'Braun-schwarzer Strich kann bei Sulfiden oder Eisenmineralen vorkommen.',
    'rotbraun': 'Rotbrauner Strich ist ein starkes Merkmal von Haematit, auch wenn die Probe selbst metallisch grau aussieht.',
    'gelbbraun': 'Gelb-brauner Strich kann bei verwitterten Eisenmineralen vorkommen.',
    'grün': 'Gruener Strich kann z. B. bei Malachit auftreten.',
    'grünlich schwarz': 'Gruenlich-schwarzer Strich ist typisch fuer einige Sulfide, z. B. Pyrit.',
    'blau': 'Blauer Strich ist selten und kann bei bestimmten Kupfermineralen auftreten.',
    'hellblau': 'Hellblauer Pulverstrich kann bei einigen blauen Mineralgemengen vorkommen.',
    'gelb': 'Gelber Strich ist selten; Verunreinigungen und Verwitterung beachten.',
    'rot': 'Roter Strich ist diagnostisch relevant, aber von rotbraun sauber unterscheiden.',
    'keine': 'Kein brauchbarer Strich: sehr harte Proben ritzen die Porzellantafel eher, als dass sie genug Pulver abgeben.',
  };

  String _help(Map<String, String> map, String value, String fallback) =>
      map[value] ?? fallback;

  @override
  void dispose() {
    density.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              'Physischer Nachtest',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: hardness.isEmpty ? null : hardness,
              decoration: const InputDecoration(labelText: 'Haerte (Mohs)'),
              items: [
                for (final value in [
                  '1','2','2.5','3','4','5','5.5','6','6.5','7','7.5','8','9','10'
                ])
                  DropdownMenuItem(value: value, child: Text(value))
              ],
              onChanged: (v) => setState(() => hardness = v ?? ''),
            ),
            _Help(_help(
              hardnessHelp,
              hardness,
              'Waehle nur einen Wert, wenn du einen Ritztest nachvollziehbar durchgefuehrt hast.',
            )),
            DropdownButtonFormField(
              value: streak.isEmpty ? null : streak,
              decoration: const InputDecoration(labelText: 'Strichfarbe'),
              items: [
                for (final value in [
                  'weiß','grau','schwarz','braunschwarz','rotbraun','gelbbraun',
                  'grün','grünlich schwarz','blau','hellblau','gelb','rot','keine'
                ])
                  DropdownMenuItem(value: value, child: Text(value))
              ],
              onChanged: (v) => setState(() => streak = v ?? ''),
            ),
            _Help(_help(
              streakHelp,
              streak,
              'Strichfarbe = Farbe des Mineralpulvers, nicht die sichtbare Aussenfarbe. '
                  'Mit einer unauffaelligen Stelle leicht ueber unglasierte weisse Porzellantafel reiben.',
            )),
            DropdownButtonFormField(
              value: magnetism.isEmpty ? null : magnetism,
              decoration: const InputDecoration(labelText: 'Magnetismus'),
              items: const [
                DropdownMenuItem(value: 'ja', child: Text('magnetisch')),
                DropdownMenuItem(value: 'nein', child: Text('nicht magnetisch')),
              ],
              onChanged: (v) => setState(() => magnetism = v ?? ''),
            ),
            _Help(
              magnetism == 'ja'
                  ? 'Die Probe reagiert reproduzierbar auf einen Magneten. Abstand und Metallanhaftungen beachten.'
                  : magnetism == 'nein'
                      ? 'Bei direkter Annaeherung an einen ausreichend starken Magneten ist keine erkennbare Reaktion feststellbar.'
                      : 'Mit einem sauberen Magneten testen; metallische Fremdteile koennen das Ergebnis verfaelschen.',
            ),
            DropdownButtonFormField(
              value: transparency.isEmpty ? null : transparency,
              decoration: const InputDecoration(labelText: 'Transparenz'),
              items: const [
                DropdownMenuItem(value: 'opak', child: Text('opak')),
                DropdownMenuItem(value: 'durchscheinend', child: Text('durchscheinend')),
                DropdownMenuItem(value: 'transparent', child: Text('transparent')),
              ],
              onChanged: (v) => setState(() => transparency = v ?? ''),
            ),
            _Help(
              transparency == 'opak'
                  ? 'Opak: Auch an einer duennen Kante dringt praktisch kein Licht durch.'
                  : transparency == 'durchscheinend'
                      ? 'Durchscheinend: Licht ist sichtbar, Formen hinter der Probe aber nicht klar.'
                      : transparency == 'transparent'
                          ? 'Transparent: Licht und Strukturen hinter einer ausreichend duennen Probe sind erkennbar.'
                          : 'Am besten gegen eine helle, gleichmaessige Lichtquelle pruefen.',
            ),
            TextField(
              controller: density,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Dichte g/cm³ (optional)',
              ),
            ),
            const _Help(
              'Dichte = Masse / Volumen. Trockenen Stein wiegen; Volumen ueber '
              'Wasserverdraengung bestimmen (1 ml = 1 cm³). Nur einen real '
              'gemessenen Wert eintragen.',
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  PhysicalInputs(
                    hardness: double.tryParse(hardness),
                    streak: streak.isEmpty ? null : streak,
                    magnetism: magnetism.isEmpty ? null : magnetism == 'ja',
                    transparency:
                        transparency.isEmpty ? null : transparency,
                    density: double.tryParse(
                      density.text.trim().replaceAll(',', '.'),
                    ),
                  ),
                );
              },
              child: const Text('Nachtest anwenden'),
            ),
          ],
        ),
      );
}

class _Help extends StatelessWidget {
  const _Help(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 12),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
}
