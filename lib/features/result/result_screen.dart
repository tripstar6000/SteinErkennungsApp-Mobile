import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../services/physical_refiner.dart';
import '../../services/providers.dart';
import '../physical_test/physical_test_sheet.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({
    super.key,
    required this.result,
    required this.imagePaths,
    this.latitude,
    this.longitude,
  });

  final ScanResult result;
  final List<String> imagePaths;
  final double? latitude;
  final double? longitude;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  List<PhysicalRefinement>? refined;

  Future<void> _physicalTest() async {
    final input = await showModalBottomSheet<PhysicalInputs>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const PhysicalTestSheet(),
    );
    if (input == null || !input.hasAny) return;
    final result = await ref
        .read(physicalRefinerProvider)
        .refine(widget.result.candidates, input);
    if (mounted) setState(() => refined = result);
  }

  Future<void> _save() async {
    if (widget.result.candidates.isEmpty) return;
    final top = widget.result.candidates.first;
    await ref.read(databaseProvider).saveScan(
          topCandidate: top.name,
          visualFit: top.visualFit,
          imagePaths: widget.imagePaths,
          latitude: widget.latitude,
          longitude: widget.longitude,
          rawResult: {
            'source': widget.result.source,
            'candidates': [
              for (final c in widget.result.candidates)
                {'name': c.name, 'visualFit': c.visualFit, 'reason': c.reason}
            ],
          },
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan lokal gespeichert.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final comparisons = {
      for (final c in widget.result.comparisons) c.candidateName: c,
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Moegliche Bestimmung')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            'Quelle: ${widget.result.source == 'local_tflite' ? 'Offline-TFLite' : 'Online-KI'}',
          ),
          if (widget.result.region.supplied)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Standort-Ranking${widget.result.region.regionName.isEmpty ? '' : ' · ${widget.result.region.regionName}'}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(widget.result.region.reason),
                    for (final item in widget.result.region.ranking)
                      ListTile(
                        dense: true,
                        title: Text((item['name'] ?? '').toString()),
                        subtitle: Text(
                          '${item['level'] ?? 'none'} · ${item['explanation'] ?? ''}',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          for (var i = 0; i < widget.result.candidates.length; i++)
            _CandidateCard(
              rank: i + 1,
              candidate: widget.result.candidates[i],
              comparison: comparisons[widget.result.candidates[i].name],
            ),
          if (widget.result.uncertainty.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Unsicherheit: ${widget.result.uncertainty}'),
              ),
            ),
          FilledButton.icon(
            onPressed: _physicalTest,
            icon: const Icon(Icons.science_outlined),
            label: const Text('Physischer Nachtest'),
          ),
          if (refined != null) ...[
            const SizedBox(height: 12),
            Text(
              'Foto-Kandidaten physisch neu bewertet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final item in refined!)
              ListTile(
                title: Text(
                  '${item.name} · ${item.adjustedFit}/100',
                ),
                subtitle: Text(item.reasons.join(' ')),
              ),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Ergebnis lokal speichern'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Traditionelle/esoterische Angaben sind keine wissenschaftlich '
            'belegten Heilwirkungen und kein Ersatz fuer medizinische Behandlung.',
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.rank,
    required this.candidate,
    this.comparison,
  });

  final int rank;
  final ScanPrediction candidate;
  final CandidateComparison? comparison;

  @override
  Widget build(BuildContext context) {
    final refs = [
      if (comparison?.reference case final r?) r,
      ...?comparison?.gallery,
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$rank. ${candidate.name} · ${candidate.visualFit}/100',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(candidate.reason),
            if (comparison != null) ...[
              const SizedBox(height: 8),
              Chip(label: Text(comparison!.referenceStatus)),
              Text('Einschaetzung: ${comparison!.verdict}'),
              if (comparison!.supports.isNotEmpty)
                Text('Dafuer: ${comparison!.supports.join(' · ')}'),
              if (comparison!.contradicts.isNotEmpty)
                Text('Dagegen: ${comparison!.contradicts.join(' · ')}'),
              if (refs.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: refs.length.clamp(0, 4),
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, index) {
                      final ref = refs[index];
                      return SizedBox(
                        width: 120,
                        child: Column(
                          children: [
                            Expanded(
                              child: Image.network(
                                ref.src,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image),
                              ),
                            ),
                            Text(
                              ref.license,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Traditionelle / esoterische Zuschreibung',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(comparison!.traditionalSummary),
              for (final claim in comparison!.traditionalClaims)
                Text('• $claim'),
              const Text(
                'Nicht wissenschaftlich als Heilwirkung belegt.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
