# 📘 Pagy Cookbook

Pagy is a lightweight and customizable pagination package for Flutter. It supports both `ListView` and `GridView` with shimmer placeholders, filters, and custom mapping.

> For a complete working demo, check out the [example project](https://github.com/hayatkhan67/pagy/tree/main/example).

---

## 🔧 Configuration

Set your base configuration **once** in the main function:

```dart
import 'package:pagy/pagy.dart';

void main() {
  PagyConfig().initialize(
    // 🌐 Your base API URL
    baseUrl: "https://your-api.com/",

    // 📩 The key your API uses to receive the current page number
    // 👉 For example: "page", "currentPage", "p", etc.
    pageKey: 'page',

    // 📩 The key your API uses to receive the number of items per page
    // 👉 For example: "limit", "perPage", "pageSize", etc.
    limitKey: 'limit',

    // 🐞 Show API logs in the console when debugging (optional)
    apiLogs: true,

    // 🔀 How your API expects pagination data to be sent
    // 👉 Use `queryParams` if it's sent in the URL (e.g. ?page=1)
    // 👉 Use `payload` if it's sent inside the request raw body (e.g. {"page": 1})
    paginationMode: PaginationPayloadMode.queryParams,

    // 🔁 How far from the bottom before fetching more (in pixels)
    scrollOffset: 200,
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
  // Replace `PropertyModel` with your own data model
  PagyController<PropertyModel> pagyController = PagyController(
    // 📍 API endpoint
    // 👉 If you already set baseUrl in PagyConfig, just provide the relative path (e.g. "api/properties")
    // 👉 If you did NOT set baseUrl in PagyConfig, provide the full URL (e.g. "https://example.com/api/properties")
    endPoint: "api/properties",

    // 🧱 Function to parse each item in the list into your data model
    fromMap: PropertyModel.fromJson,

    // 🔢 Number of items to load per page
    limit: 4,

    // 📦 This parses the full API response and extracts the list + total pages
    responseMapper: (response) {
      return PagyResponseParser(
        // 📄 The list of data items (from your API)
        list: response['data'],

        // 📊 Total number of pages (used for pagination logic)
        totalPages: response['pagination']['totalPages'],
      );
    },

    // 🔀 If not set globally in PagyConfig, define how pagination data is sent
    paginationMode: PaginationPayloadMode.queryParams,

    // 🧩 Send extra data along with your API request (optional)
    additionalQueryParams: {'type': 'all'},

    // 🔐 If your API requires authentication, you can pass the token here (optional)
    token: 'your_api_token',
  );

  @override
  void initState() {
    super.initState();

    // 🚀 This is the key line that starts the Pagy engine!
    // It triggers the first API call and loads the initial data.
    pagyController.loadData();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PagyListView<PropertyModel>(
      // 📏 Space between list items
      itemsGap: 3,

      // 🧱 Outer padding of the list
      padding: const EdgeInsets.symmetric(horizontal: 14),

      // 🎮 Your PagyController that manages pagination logic
      controller: pagyController,

      // 🪄 Number of shimmer placeholders to show while loading
      placeholderItemCount: 2,

      // ✨ Enable shimmer loading effect (optional, default: false)
      shimmerEffect: true,

      // 📦 Placeholder item to use with shimmer (required if shimmerEffect is true)
      placeholderItemModel: PropertyModel(),

      // 🧩 Your widget for each list item
      itemBuilder: (context, item) {
        // 🎯 'item' is your model from the API — use it to build your UI
        // Return your custom UI widget
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
