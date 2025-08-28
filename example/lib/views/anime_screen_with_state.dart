import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pagy/pagy.dart';

import '../controllers/anime_provider/anime_provider.dart';
import '../models/anime_model.dart';
import '../widgets/anime_card_widget.dart';

class AnimeScreenTest extends ConsumerWidget {
  const AnimeScreenTest({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(animeProvider);
    final notifier = ref.read(animeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Anime Explorer"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => notifier.clearSearch(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Anime Grid List
          Expanded(
            child: PagyGridView<AnimeModel>(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              controller: state.pagyController,
              shimmerEffect: true,
              placeholderItemCount: 6,
              placeholderItemModel: AnimeModel(),
              itemBuilder: (context, item) {
                return GestureDetector(
                  onTap: () => notifier.selectAnime(item),
                  child: AnimeCardWidget(data: item),
                );
              },
            ),
          ),

          // 🔘 Trigger Buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 12,
              children: [
                ElevatedButton(
                  onPressed: () {
                    notifier.addAnimeAt(
                      0,
                      AnimeModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: "🔥 New Local Anime",
                        image: "",
                        type: "Local",
                        createdAt: DateTime.now(),
                      ),
                    );
                  },
                  child: const Text("Add Anime @0"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (state.pagyController.items.isNotEmpty) {
                      notifier.updateAnimeTitle(0, "Updated Title ✨");
                    }
                  },
                  child: const Text("Update Index 0"),
                ),
                ElevatedButton(
                  onPressed: notifier.loadNextPage,
                  child: const Text("Load More"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
