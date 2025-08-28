import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pagy/pagy.dart';
import '../../models/anime_model.dart';
import 'anime_state.dart';

class AnimeController extends StateNotifier<AnimeState> {
  AnimeController() : super(_initialState()) {
    // Auto load first page
    state.pagyController.loadData();
  }

  /// Build initial state with Pagy setup
  static AnimeState _initialState() {
    final pagy = PagyController<AnimeModel>(
      endPoint: "anime",
      fromMap: AnimeModel.fromJson,
      limit: 5,
      responseMapper: (response) {
        log(response.runtimeType.toString(), name: 'Anime API');
        return PagyResponseParser(
          list: response['data'],
          totalPages: response['pagination']['totalPages'],
        );
      },
      paginationMode: PaginationPayloadMode.queryParams,
    );
    return AnimeState(pagyController: pagy);
  }

  /// 🔹 Select anime for details
  void selectAnime(AnimeModel anime) {
    state = state.copyWith(selectedAnime: anime);
  }

  /// 🔹 Update anime title at a specific index
  void updateAnimeTitle(int index, String newTitle) {
    modifyPagy((pagyState) {
      if (index < 0 || index >= pagyState.data.length) return pagyState;

      final oldAnime = pagyState.data[index];
      final updatedAnime = oldAnime.copyWith(
        title: newTitle,
        updatedAt: DateTime.now(),
      );

      final updatedList = [...pagyState.data];
      updatedList[index] = updatedAnime;

      return pagyState.copyWith(data: updatedList);
    });
  }

  /// 🔹 Add a new Anime locally
  void addAnimeAt(int index, AnimeModel anime) {
    modifyPagy((pagyState) {
      final list = [...pagyState.data];
      if (index < 0 || index > list.length) {
        list.add(anime);
      } else {
        list.insert(index, anime);
      }
      return pagyState.copyWith(data: list);
    });
  }

  /// 🔹 Reload current page
  void reload() {
    state.pagyController.loadData();
  }

  /// 🔹 Clear search
  void clearSearch() {
    state = state.copyWith(searchQuery: '');
    reload();
  }

  /// 🔹 Load next page
  void loadNextPage() {
    state.pagyController.loadData(refresh: false);
  }

  /// 🔹 Direct advanced modification (for full control)
  void modifyPagy(ValueUpdater<PagyState<AnimeModel>> updater) {
    state.pagyController.modifyDirect(updater);
  }

  @override
  void dispose() {
    state.pagyController.dispose();
    super.dispose();
  }
}

/// Riverpod provider
final animeProvider = StateNotifierProvider<AnimeController, AnimeState>((ref) {
  return AnimeController();
});
