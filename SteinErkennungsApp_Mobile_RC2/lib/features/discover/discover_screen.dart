import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/providers.dart';
import '../../shared/app_scaffold.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  var query = '';

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(catalogProvider);
    return AppScaffold(
      title: 'Entdecken',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Name suchen',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => query = value),
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: repo.search(query),
              builder: (context, snapshot) {
                final stones = snapshot.data ?? const [];
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  itemCount: stones.length,
                  itemBuilder: (context, i) {
                    final s = stones[i];
                    return ListTile(
                      title: Text(s.nameDe),
                      subtitle: Text(
                        [s.category, s.scientificName]
                            .whereType<String>()
                            .where((e) => e.isNotEmpty)
                            .join(' · '),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
