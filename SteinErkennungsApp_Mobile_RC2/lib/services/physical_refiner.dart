import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/models.dart';

class PhysicalInputs {
  const PhysicalInputs({
    this.hardness,
    this.streak,
    this.magnetism,
    this.transparency,
    this.density,
  });

  final double? hardness;
  final String? streak;
  final bool? magnetism;
  final String? transparency;
  final double? density;

  bool get hasAny =>
      hardness != null ||
      (streak?.isNotEmpty ?? false) ||
      magnetism != null ||
      (transparency?.isNotEmpty ?? false) ||
      density != null;
}

class PhysicalRefinement {
  const PhysicalRefinement({
    required this.name,
    required this.originalFit,
    required this.adjustedFit,
    required this.reasons,
  });

  final String name;
  final int originalFit;
  final int adjustedFit;
  final List<String> reasons;
}

class PhysicalRefiner {
  List<Map<String, dynamic>>? _profiles;

  Future<List<Map<String, dynamic>>> _load() async {
    if (_profiles case final p?) return p;
    final raw = await rootBundle.loadString('assets/data/physical_profiles.json');
    _profiles = (jsonDecode(raw) as List)
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
    return _profiles!;
  }

  String _n(String value) => value
      .toLowerCase()
      .replaceAll('ä', 'a')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('ß', 'ss')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();

  Future<Map<String, dynamic>?> _profile(String name) async {
    final target = _n(name);
    for (final p in await _load()) {
      final aliases = (p['aliases'] as List? ?? const []).map((e) => _n(e.toString()));
      if (aliases.any((a) => a == target || a.contains(target) || target.contains(a))) {
        return p;
      }
    }
    return null;
  }

  bool _inRange(double value, List<dynamic>? range) {
    if (range == null || range.length < 2) return false;
    return value >= (range[0] as num).toDouble() &&
        value <= (range[1] as num).toDouble();
  }

  Future<List<PhysicalRefinement>> refine(
    List<ScanPrediction> candidates,
    PhysicalInputs input,
  ) async {
    final out = <PhysicalRefinement>[];
    for (final c in candidates) {
      var score = c.visualFit;
      final reasons = <String>[];
      final p = await _profile(c.name);
      if (p == null) {
        out.add(PhysicalRefinement(
          name: c.name,
          originalFit: c.visualFit,
          adjustedFit: c.visualFit,
          reasons: const ['Kein lokales physisches Profil; visueller Fit bleibt unveraendert.'],
        ));
        continue;
      }
      if (input.hardness != null && p['hardness'] is List) {
        if (_inRange(input.hardness!, (p['hardness'] as List).cast<dynamic>())) {
          score += 10;
          reasons.add('Haerte passt.');
        } else {
          score -= 16;
          reasons.add('Haerte widerspricht.');
        }
      }
      if (input.density != null && p['density'] is List) {
        if (_inRange(input.density!, (p['density'] as List).cast<dynamic>())) {
          score += 10;
          reasons.add('Dichte passt.');
        } else {
          score -= 14;
          reasons.add('Dichte widerspricht.');
        }
      }
      if (input.streak?.isNotEmpty == true) {
        final expected = (p['streak'] as List? ?? const [])
            .map((e) => _n(e.toString()))
            .toList();
        if (expected.contains(_n(input.streak!))) {
          score += 8;
          reasons.add('Strichfarbe passt.');
        } else if (expected.isNotEmpty) {
          score -= 10;
          reasons.add('Strichfarbe widerspricht.');
        }
      }
      if (input.magnetism != null && p['magnetism'] != null) {
        final expected = p['magnetism'].toString() == 'ja';
        if (input.magnetism == expected) {
          score += 8;
          reasons.add('Magnetismus passt.');
        } else {
          score -= 14;
          reasons.add('Magnetismus widerspricht.');
        }
      }
      if (input.transparency?.isNotEmpty == true) {
        final expected = (p['transparency'] as List? ?? const [])
            .map((e) => _n(e.toString()))
            .toList();
        if (expected.contains(_n(input.transparency!))) {
          score += 8;
          reasons.add('Transparenz passt.');
        } else if (expected.isNotEmpty) {
          score -= 10;
          reasons.add('Transparenz widerspricht.');
        }
      }
      out.add(PhysicalRefinement(
        name: c.name,
        originalFit: c.visualFit,
        adjustedFit: score.clamp(0, 100).toInt(),
        reasons: reasons.isEmpty ? const ['Keine verwertbaren lokalen Vergleichswerte.'] : reasons,
      ));
    }
    out.sort((a, b) => b.adjustedFit.compareTo(a.adjustedFit));
    return out;
  }
}
