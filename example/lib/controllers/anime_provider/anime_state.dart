import 'package:equatable/equatable.dart';
import 'package:pagy/pagy.dart';

import '../../models/anime_model.dart';

class AnimeState extends Equatable {
  final PagyController<AnimeModel> pagyController;

  final AnimeModel? selectedAnime;
  final bool isFavoriteMode;
  final String searchQuery;

  const AnimeState({
    required this.pagyController,
    this.selectedAnime,
    this.isFavoriteMode = false,
    this.searchQuery = "",
  });

  AnimeState copyWith({
    PagyController<AnimeModel>? pagyController,
    AnimeModel? selectedAnime,
    bool? isFavoriteMode,
    String? searchQuery,
  }) {
    return AnimeState(
      pagyController: pagyController ?? this.pagyController,
      selectedAnime: selectedAnime ?? this.selectedAnime,
      isFavoriteMode: isFavoriteMode ?? this.isFavoriteMode,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
    pagyController,
    selectedAnime,
    isFavoriteMode,
    searchQuery,
  ];
}
