import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/providers.dart';
import '../../shared/app_scaffold.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    return AppScaffold(
      title: 'Sammlung',
      child: FutureBuilder(
        future: db.scans(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snapshot.data ?? const [];
          if (rows.isEmpty) {
            return const Center(child: Text('Noch keine Scans gespeichert.'));
          }
          return ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final row = rows[i];
              return ListTile(
                title: Text((row['top_candidate'] ?? 'Unbestimmt').toString()),
                subtitle: Text(
                  '${row['timestamp']} · visueller Fit ${row['visual_fit'] ?? '-'}',
                ),
                leading: Icon(
                  (row['favorite'] as int? ?? 0) == 1
                      ? Icons.star
                      : Icons.history,
                ),
                trailing: IconButton(
                  onPressed: () async {
                    await db.deleteScan(row['id'] as int);
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
