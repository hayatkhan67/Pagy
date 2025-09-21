import 'package:equatable/equatable.dart';
import 'package:pagy/pagy.dart';

import '../../models/anime_model.dart';

class AnimeState extends Equatable {
  final PagyController<AnimeModel> pagyController;

  final AnimeModel? selectedAnime;
  final bool isFavoriteMode;
  final String searchQuery;

  ///if you want to save the pagy data list in your state, you can use this
  final List<AnimeModel> animeList;

  const AnimeState({
    required this.pagyController,
    this.selectedAnime,
    this.isFavoriteMode = false,
    this.searchQuery = "",
    this.animeList = const [],
  });

  AnimeState copyWith({
    PagyController<AnimeModel>? pagyController,
    AnimeModel? selectedAnime,
    bool? isFavoriteMode,
    String? searchQuery,
    List<AnimeModel>? animeList,
  }) {
    return AnimeState(
      pagyController: pagyController ?? this.pagyController,
      selectedAnime: selectedAnime ?? this.selectedAnime,
      isFavoriteMode: isFavoriteMode ?? this.isFavoriteMode,
      searchQuery: searchQuery ?? this.searchQuery,
      animeList: animeList ?? this.animeList,
    );
  }

  @override
  List<Object?> get props => [
    pagyController,
    selectedAnime,
    isFavoriteMode,
    searchQuery,
    animeList,
  ];
}
