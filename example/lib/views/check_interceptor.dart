import 'package:flutter/material.dart';
import 'package:pagy/pagy.dart';

import '../models/property_model.dart';
import '../widgets/property_card_widget.dart';

class AnimeScreenWithInterceptor extends StatefulWidget {
  const AnimeScreenWithInterceptor({super.key});

  @override
  State<AnimeScreenWithInterceptor> createState() =>
      _AnimeScreenWithInterceptorState();
}

class _AnimeScreenWithInterceptorState
    extends State<AnimeScreenWithInterceptor> {
  late PagyController<PropertyModel> pagyController;

  @override
  void initState() {
    super.initState();
    pagyController = PagyController(
      endPoint: "properties/secured",
      requestType: PagyApiRequestType.post,
      fromMap: PropertyModel.fromJson,
      headers: {'Authorization': 'Bearer hayat'},
      limit: 4,
      responseMapper: (response) {
        return PagyResponseParser(
          list: response['data'],
          totalPages: response['pagination']['totalPages'],
        );
      },
      paginationMode: PaginationPayloadMode.queryParams,
    );

    pagyController.loadData();
  }

  @override
  Widget build(BuildContext context) {
    return PagyListView<PropertyModel>(
      itemSpacing: 10,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      // separatorBuilder: (context, index) => const Divider(),
      controller: pagyController,
      shimmerItemCount: 10,
      enableShimmer: true,
      shimmerItemModel: PropertyModel(),
      itemBuilder: (context, item) {
        return PropertyCardWidget(data: item);
      },
    );
  }
}
