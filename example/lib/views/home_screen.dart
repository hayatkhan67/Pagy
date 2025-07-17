import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:pagy/pagy.dart';

import '../utils/constant_data.dart';
import '../models/property_model.dart';
import '../widgets/catergorie_name_row.dart';
import '../widgets/property_card_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PagyController<PropertyModel> pagyController;

  @override
  void initState() {
    super.initState();
    pagyController = PagyController(
      endPoint: "api/properties",
      requestType: PagyApiRequestType.post,
      fromMap: PropertyModel.fromJson,
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
    return Column(
      children: [
        const SizedBox(height: 10),
        CatergorieNameRow(
          itemList: types,
          onChanged: (value) {
            log(name: 'selected tag', value.toString());
            if (value.toLowerCase() == 'all') {
              pagyController.loadData();
              return;
            } else {
              pagyController.loadData(queryParameter: {'type': value});
            }
          },
        ),
        const SizedBox(height: 10),
        Expanded(
          child: PagyListView<PropertyModel>(
            itemsGap: 3,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            separatorBuilder: (context, index) => const Divider(),
            controller: pagyController,
            // placeholderItemCount: 10,
            // shimmerEffect: true,
            // placeholderItemModel: PropertyModel(),
            itemBuilder: (context, item) {
              return PropertyCardWidget(data: item);
            },
          ),
        ),
      ],
    );
  }
}
