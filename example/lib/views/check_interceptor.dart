import 'package:flutter/material.dart';
import 'package:pagy/pagy.dart';

import '../models/anime_model.dart';
import '../widgets/anime_card_widget.dart';

class AnimeScreenWithInterceptor extends StatefulWidget {
  const AnimeScreenWithInterceptor({super.key});

  @override
  State<AnimeScreenWithInterceptor> createState() =>
      _AnimeScreenWithInterceptorState();
}

class _AnimeScreenWithInterceptorState
    extends State<AnimeScreenWithInterceptor> {
  PagyController<AnimeModel> pagyController = PagyController(
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
