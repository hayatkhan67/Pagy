# 📘 Pagy Cookbook

Pagy is a lightweight and customizable pagination package for Flutter. It supports both `ListView` and `GridView` with shimmer placeholders, filters, and custom mapping.

> For a complete working demo, check out the [example project](https://github.com/hayatkhan67/pagy/tree/main/example).

---

## 🔧 Configuration

Set your base configuration **once** in the main function:

```dart
import 'package:pagy/pagy.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pagy/pagy.dart';

import 'interceptor.dart';
import 'views/nav_screen.dart';

void main() {
  PagyConfig().initialize(
    // 🌐 Your base API URL
    baseUrl: "https://your-api.com/",

    // 📩 The key your API uses for current page
    pageKey: 'page',

    // 📩 The key your API uses for page size
    limitKey: 'limit',

    // 🐞 Show API logs in console
    apiLogs: true,

    // 🔀 How pagination payload is sent
    paginationMode: PaginationPayloadMode.queryParams,

    // 🔁 Pixels from bottom before loading next page
    scrollOffset: 200,

    // 🛠️ Optional custom logger
    customLogger: (message, {name}) {
      debugPrint('${name ?? '[Pagy]'} $message');
    },

    // 🔐 Optional interceptor for auth/error handling
    interceptor: DioInterceptor(
      onTokenBlacklisted: () {
        // Example: logout or refresh token
      },
    ),
  );

  runApp(const ProviderScope(child: PagyExampleApp()));
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
  late PagyController<PropertyModel> pagyController;

  @override
  void initState() {
    super.initState();
    pagyController = PagyController(
      // 📍 Endpoint (relative if baseUrl is in PagyConfig)
      endPoint: "properties",

      // 🧱 Convert API map → model
      fromMap: PropertyModel.fromJson,

      // 🔢 Items per page
      limit: 4,

      // 📦 Parse API response
      responseMapper: (response) {
        return PagyResponseParser(
          list: response['data'],
          totalPages: response['pagination']['totalPages'],
        );
      },

      // 🔀 Optional override if not in PagyConfig
      paginationMode: PaginationPayloadMode.queryParams,
    );

    // 🚀 Load first page
    pagyController.loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PagyListView<PropertyModel>(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemSpacing: 3,
        controller: pagyController,

        // ✨ Shimmer while loading
        shimmerEffect: true,
        placeholderItemCount: 2,
        placeholderItemModel: PropertyModel(),

        // 🔨 Your item UI
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
import '../widgets/categories_name_row.dart';
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
      endPoint: "properties",
      fromMap: PropertyModel.fromJson,
      limit: 3,
      responseMapper: (response) {
        return PagyResponseParser(
          list: response['data'],
          totalPages: response['pagination']['totalPages'],
        );
      },
    );
    pagyController.loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        CategoriesNameRow(
          itemList: types,
          onChanged: (value) {
            log("Filter applied: $value");
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
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemSpacing: 3,
            controller: pagyController,
            shimmerEffect: true,
            placeholderItemCount: 10,
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

## 🌱 Riverpod Example (Anime List)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pagy/pagy.dart';

import '../models/anime_model.dart';
import '../widgets/anime_card_widget.dart';

/// 🎮 Step 1: Create a Riverpod provider for PagyController
final animeControllerProvider = Provider<PagyController<AnimeModel>>((ref) {
  final controller = PagyController<AnimeModel>(
    endPoint: "anime",
    fromMap: AnimeModel.fromJson,
    limit: 10,
    responseMapper: (response) {
      return PagyResponseParser(
        list: response['data'],
        totalPages: response['pagination']['totalPages'],
      );
    },
  );

  // 🚀 Load initial data
  controller.loadData();

  return controller;
});

/// 🎬 Step 2: Consume the provider in your UI
class AnimeScreen extends ConsumerWidget {
  const AnimeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagyController = ref.watch(animeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Anime List")),
      body: PagyGridView<AnimeModel>(
        controller: pagyController,
        padding: const EdgeInsets.all(14),
        shimmerEffect: true,
        placeholderItemCount: 6,
        placeholderItemModel: AnimeModel(),
        itemBuilder: (context, item) {
          return AnimeCardWidget(data: item);
        },
      ),
    );
  }
}
```
