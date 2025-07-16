import 'package:flutter/material.dart';
import 'package:pagy/pagy.dart';

import '../models/anime_model.dart';
import '../widgets/anime_card_widget.dart';

class AnimeScreen extends StatefulWidget {
  const AnimeScreen({super.key});

  @override
  State<AnimeScreen> createState() => _AnimeScreenState();
}

class _AnimeScreenState extends State<AnimeScreen> {
  PagyController<AnimeModel> pagyController = PagyController(
    endPoint: "api/anime",
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

  @override
  void initState() {
    super.initState();

    ///load Data
    pagyController.loadData();
  }

  @override
  void dispose() {
    super.dispose();
    pagyController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PagyGridView<AnimeModel>(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      controller: pagyController,
      // shimmerEffect: true,
      // placeholderItemCount: 3,
      // placeholderItemModel: AnimeModel(),
      itemBuilder: (context, item) {
        return AnimeCardWidget(data: item);
      },
    );
  }
}
