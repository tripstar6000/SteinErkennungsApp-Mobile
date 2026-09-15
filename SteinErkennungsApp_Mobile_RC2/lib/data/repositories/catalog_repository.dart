import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/models.dart';

class CatalogRepository {
  List<Stone>? _cache;

  Future<List<Stone>> all() async {
    if (_cache case final c?) return c;
    final raw = await rootBundle.loadString('assets/data/stones_de.json');
    _cache = (jsonDecode(raw) as List)
        .whereType<Map>()
        .map((e) => Stone.fromJson(e.cast<String, dynamic>()))
        .toList();
    return _cache!;
  }

  Future<List<Stone>> search(String query) async {
    final q = query.trim().toLowerCase();
    final stones = await all();
    if (q.isEmpty) return stones;
    return stones
        .where((s) =>
            s.nameDe.toLowerCase().contains(q) ||
            (s.nameEn?.toLowerCase().contains(q) ?? false) ||
            (s.scientificName?.toLowerCase().contains(q) ?? false))
        .toList();
  }
}
