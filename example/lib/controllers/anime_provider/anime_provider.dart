import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pagy/pagy.dart';

import '../../models/anime_model.dart';
import 'anime_state.dart';

/// `AnimeController`
///
/// A Riverpod `StateNotifier` responsible for managing paginated
/// anime data using [PagyController].
///
/// It handles:
/// - API data fetching (via `PagyController`)
/// - List mutations (add, update, replace, reset)
/// - Pagination (load more / refresh)
class AnimeController extends StateNotifier<AnimeState> {
  /// Initializes the controller with initial Pagy state
  /// and automatically loads the first page of data.
  AnimeController() : super(_initialState()) {
    // Start loading data
    state.pagyController.loadData();

    // Sync anime list whenever PagyController updates
    state.pagyController.listen((v) {
      state = state.copyWith(animeList: List<AnimeModel>.from(v));
    });
  }

  static AnimeState _initialState() {
    final pagy = PagyController<AnimeModel>(
      endPoint: "anime",
      fromMap: AnimeModel.fromJson,
      limit: 5,
      responseMapper: (response) {
        return PagyResponseParser(
          list: response['data'],
          totalPages: response['pagination']['totalPages'],
        );
      },
      paginationMode: PaginationPayloadMode.queryParams,
    );

    return AnimeState(pagyController: pagy, animeList: const []);
  }

  /// Updates the title of an [AnimeModel] at a given [index].
  ///
  /// - Creates a copy with the new title.
  /// - Updates `updatedAt` timestamp.
  void updateAnimeTitle(int index, String newTitle) {
    final oldAnime = state.pagyController.items[index];
    final updatedAnime = oldAnime.copyWith(
      title: newTitle,
      updatedAt: DateTime.now(),
    );
    state.pagyController.updateItemAt(index, updatedAnime);
  }

  /// Inserts a new [AnimeModel] at the given [index].
  void addAnimeAt(int index, AnimeModel anime) {
    state.pagyController.insertAt(index, anime);
  }

  /// Adds a new [AnimeModel] at the start of the list.
  void addAnimeFirst(AnimeModel anime) {
    state.pagyController.addItem(anime, atStart: true);
  }

  /// Replaces an anime entry that matches the given [id]
  /// with [newAnime].
  void replaceAnime(String id, AnimeModel newAnime) {
    state.pagyController.replaceWhere((anime) => anime.id == id, newAnime);
  }

  /// Reloads the first page of data.
  void reload() {
    state.pagyController.loadData();
  }

  /// Clears the list and resets pagination state.
  void resetList() {
    state.pagyController.reset();
  }

  /// Loads the next page of data (pagination).
  void loadNextPage() {
    state.pagyController.loadData(refresh: false);
  }

  /// Properly disposes [PagyController] when no longer needed.
  @override
  void dispose() {
    state.pagyController.dispose();
    super.dispose();
  }
}

/// Riverpod provider for [AnimeController].
///
/// Use `ref.watch(animeProvider)` in UI to access [AnimeState].
/// Use `ref.read(animeProvider.notifier)` to call controller methods.
final animeProvider = StateNotifierProvider<AnimeController, AnimeState>((ref) {
  return AnimeController();
});
