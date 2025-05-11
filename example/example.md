# 📘 Pagy Cookbook

Pagy is a lightweight and customizable pagination package for Flutter. It supports both `ListView` and `GridView` with shimmer placeholders, filters, and custom mapping.

> For a complete working demo, check out the [example project](https://github.com/hayatkhan67/pagy/tree/main/example).

---

## 🔧 Configuration

Set your base configuration **once** in the main function:

```dart
import 'package:flutter/material.dart';
import 'package:pagy/pagy.dart';

import 'views/nav_screen.dart';

void main() {
  PagyConfig().initialize(
    baseUrl: "https://pug-elegant-jennet.ngrok-free.app/",
    pageKey: 'page',
    limitKey: 'limit',
  );

  runApp(const PagyExampleApp());
}
```

---

## 📄 Basic ListView Example

```dart
import 'package:flutter/material.dart';
import 'package:pagy/pagy.dart';

import '../models/property_model.dart';
import '../widgets/property_card_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PagyController<PropertyModel> pagyController = PagyController(
    endPoint: "api/properties",
    fromMap: PropertyModel.fromJson,
    limit: 3,
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
    pagyController.loadData();
  }

  @override
  void dispose() {
    pagyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PagyListView<PropertyModel>(
        itemsGap: 3,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        controller: pagyController,
        placeholderItemCount: 3,
        shimmerEffect: true,
        placeholderItemModel: PropertyModel(),
        itemBuilder: (context, item) {
          return PropertyCardWidget(data: item);
        },
      ),
    );
  }
}
```

---

## 🔍 ListView with Filter Example

```dart
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:pagy/pagy.dart';

import '../models/property_model.dart';
import '../utils/constant_data.dart';
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
      fromMap: PropertyModel.fromJson,
      limit: 3,
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
            log('Selected tag: $value');
            if (value.toLowerCase() == 'all') {
              pagyController.loadData();
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
            controller: pagyController,
            placeholderItemCount: 10,
            shimmerEffect: true,
            placeholderItemModel: PropertyModel(),
            itemBuilder: (context, item) {
              return PropertyCardWidget(data: item);
            },
          ),
        ),
      ],
    );
  }
}
```

---

## 🧱 GridView Example

```dart
PagyGridView<AnimeModel>(
  padding: const EdgeInsets.symmetric(horizontal: 14),
  controller: pagyController,
  shimmerEffect: true,
  placeholderItemCount: 3,
  placeholderItemModel: AnimeModel(),
  itemBuilder: (context, item) {
    return AnimeCardWidget(data: item);
  },
);
```
