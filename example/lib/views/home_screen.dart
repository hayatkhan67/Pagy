import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:pagy/pagy.dart';
import '../models/property_model.dart';
import '../utils/constant_data.dart';
import '../widgets/categories_name_row.dart';
import '../widgets/property_card_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PagyController<PropertyModel> pagyController;
  bool preserveFilters = false;

  @override
  void initState() {
    super.initState();
    pagyController = PagyController(
      endPoint: "properties",
      requestType: PagyApiRequestType.post,
      fromMap: PropertyModel.fromJson,
      limit: 4,
      responseParser: (response) {
        return PagyResponseParser(
          list: response['data'],
          totalPages: response['pagination']['totalPages'],
        );
      },
      payloadMode: PaginationPayloadMode.queryParams,
    );

    pagyController.loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Text("Preserve Filters on Refresh:"),
              const Spacer(),
              Switch(
                value: preserveFilters,
                onChanged: (v) => setState(() => preserveFilters = v),
              ),
            ],
          ),
        ),
        CategoriesNameRow(
          itemList: types,
          onChanged: (value) {
            log(name: 'selected tag', value.toString());
            if (value.toLowerCase() == 'all') {
              pagyController.clearFilters();
              pagyController.loadData();
              return;
            } else {
              pagyController.loadData(queryParameter: {'type': value});
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // Simulate an error to show stacktrace support
                  pagyController.controller.value = pagyController.state
                      .copyWith(
                        error: PagyError.unknown(
                          message: "Simulated Error for Debugging",
                          stackTrace: StackTrace.current,
                        ),
                        isFetching: false,
                      );
                },
                icon: const Icon(Icons.bug_report, size: 18),
                label: const Text("Show Stacktrace"),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => pagyController.clearFilters(),
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text("Clear Filters"),
              ),
            ],
          ),
        ),
        Expanded(
          child: PagyListView<PropertyModel>(
            itemSpacing: 3,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            separatorBuilder: (context, index) => const Divider(),
            controller: pagyController,
            placeholderItemCount: 10,
            shimmerEffect: true,
            placeholderItemModel: PropertyModel(),
            refreshIndicatorBuilder: (context, child, _) {
              return RefreshIndicator(
                backgroundColor: Colors.blueAccent,
                color: Colors.white,
                onRefresh: () =>
                    pagyController.refresh(preserveFilters: preserveFilters),
                child: child,
              );
            },
            itemBuilder: (context, item) {
              return PropertyCardWidget(data: item);
            },
          ),
        ),
      ],
    );
  }
}
