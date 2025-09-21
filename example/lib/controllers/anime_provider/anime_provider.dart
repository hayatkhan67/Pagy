import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pagy/pagy.dart';

import '../../models/anime_model.dart';
import 'anime_state.dart';

/// {@template anime_controller}
/// A Riverpod [StateNotifier] that manages paginated anime data
/// using [PagyController].
///
/// This controller:
/// - Initializes and configures a [PagyController] for `AnimeModel`.
/// - Automatically loads the first page of data on creation.
/// - Keeps the [AnimeState] in sync with the [PagyController].
/// - Provides mutation helpers (add, update, replace, reset).
/// - Supports pagination (refresh and load more).
///
/// ### Example usage in UI:
/// ```dart
/// final animeState = ref.watch(animeProvider);
///
/// if (animeState.pagyController.state.isFetching) {
///   return const CircularProgressIndicator();
/// }
///
/// return PagyListView<AnimeModel>(
///   controller: animeState.pagyController,
///   itemBuilder: (context, index) {
///     final anime = animeState.animeList[index];
///     return Text(anime.title);
///   },
/// );
/// ```
/// {@endtemplate}
class AnimeController extends StateNotifier<AnimeState> {
  /// Creates an [AnimeController] with an initial [PagyController].
  ///
  /// On initialization:
  /// - Loads the first page of data immediately.
  /// - Sets up a listener to update the [AnimeState] whenever
  ///   the [PagyController] emits new data.
  AnimeController() : super(_initialState()) {
    // Start loading data
    state.pagyController.loadData();

    // Keep animeList synced with PagyController's data
    state.pagyController.listen((v) {
      state = state.copyWith(animeList: List<AnimeModel>.from(v));
    });
  }

  /// Internal factory for the initial [AnimeState].
  ///
  /// Configures [PagyController] for the `anime` endpoint
  /// with:
  /// - Limit of 5 per page
  /// - JSON → [AnimeModel] conversion
  /// - Custom [PagyResponseParser] mapping
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

  /// Updates the title of an [AnimeModel] at the given [index].
  ///
  /// - Creates a modified copy with the new title.
  /// - Also updates the `updatedAt` timestamp.
  void updateAnimeTitle(int index, String newTitle) {
    final oldAnime = state.pagyController.items[index];
    final updatedAnime = oldAnime.copyWith(
      title: newTitle,
      updatedAt: DateTime.now(),
    );
    state.pagyController.updateItemAt(index, updatedAnime);
  }

  /// Inserts a new [AnimeModel] at a given [index].
  void addAnimeAt(int index, AnimeModel anime) {
    state.pagyController.insertAt(index, anime);
  }

  /// Adds a new [AnimeModel] at the beginning of the list.
  void addAnimeFirst(AnimeModel anime) {
    state.pagyController.addItem(anime, atStart: true);
  }

  /// Replaces an existing anime with [newAnime] if its `id` matches.
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

  /// Loads the next page of data for pagination.
  void loadNextPage() {
    state.pagyController.loadData(refresh: false);
  }

  /// Disposes the [PagyController] properly
  /// when this notifier is destroyed.
  @override
  void dispose() {
    state.pagyController.dispose();
    super.dispose();
  }
}

/// Riverpod provider for [AnimeController].
///
/// - Use `ref.watch(animeProvider)` to access the current [AnimeState].
/// - Use `ref.read(animeProvider.notifier)` to call methods like
///   [AnimeController.reload] or [AnimeController.loadNextPage].
final animeProvider = StateNotifierProvider<AnimeController, AnimeState>((ref) {
  return AnimeController();
});
