import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pagy/pagy.dart';

import '../controllers/anime_provider/anime_provider.dart';
import '../models/anime_model.dart';
import '../widgets/anime_card_widget.dart';

/// 🖼️ Example screen showing how to use Pagy with Riverpod
/// - Listens to paginated anime data
/// - Provides action buttons for testing
/// - Shows dynamic FloatingActionButton based on Pagy state
class AnimeScreenTest extends ConsumerWidget {
  const AnimeScreenTest({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(animeProvider);

    final notifier = ref.read(animeProvider.notifier);
    log('🔄 Full screen rebuild ${state.animeList.length}');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Anime Explorer"),
        actions: [
          IconButton(
            tooltip: "Reload current page",
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.reload(),
          ),
          IconButton(
            tooltip: "Reset list (clear all)",
            icon: const Icon(Icons.clear),
            onPressed: () => notifier.resetList(),
          ),
        ],
      ),

      /// 🪄 Dynamic FAB — automatically rebuilds with PagyObserver
      floatingActionButton: PagyObserver<AnimeModel>(
        controller: state.pagyController,
        builder: (context, pagyState) {
          log('🎯 PagyObserver rebuild');

          if (pagyState.data.isEmpty) {
            return FloatingActionButton.extended(
              heroTag: "fab_add",
              onPressed: () {
                notifier.addAnimeAt(
                  0,
                  AnimeModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: "✨ First Anime",
                    image: "",
                    type: "Local",
                    createdAt: DateTime.now(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text("Add First"),
            );
          } else {
            return FloatingActionButton.extended(
              heroTag: "fab_edit",
              onPressed: () {
                notifier.updateAnimeTitle(0, "Updated via FAB ✨");
              },
              icon: const Icon(Icons.edit),
              label: const Text("Edit First"),
            );
          }
        },
      ),

      body: Column(
        children: [
          /// 📚 Anime Grid List with PagyGridView
          Expanded(
            child: PagyGridView<AnimeModel>(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              controller: state.pagyController,
              shimmerEffect: true,
              placeholderItemCount: 6,
              placeholderItemModel: AnimeModel(),
              itemBuilder: (context, item) {
                return AnimeCardWidget(data: item);
              },
            ),
          ),

          /// 🔘 Trigger Buttons (testing helpers)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Quick Actions",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Add Anime @0"),
                      onPressed: () {
                        notifier.addAnimeAt(
                          0,
                          AnimeModel(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            title: "🔥 New Local Anime",
                            image: "",
                            type: "Local",
                            createdAt: DateTime.now(),
                          ),
                        );
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text("Update Index 0"),
                      onPressed: () {
                        if (state.pagyController.items.isNotEmpty) {
                          notifier.updateAnimeTitle(0, "Updated Title ✨");
                        }
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text("Load More"),
                      onPressed: notifier.loadNextPage,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
