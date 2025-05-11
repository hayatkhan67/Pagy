<p align="center">
	<img src="https://raw.githubusercontent.com/hayatkhan67/pagy/main/assets/logo.png" alt="Package Logo" />
</p>
<p align="center">
	<i>Pagy - A simple Flutter package for smooth pagination</i>
</p>
<p align="center">
	<a href="https://pub.dev/packages/pagy" rel="noopener" target="_blank"><img src="https://img.shields.io/pub/v/pagy.svg" alt="Pub.dev Badge"></a>
	<a href="https://github.com/hayatkhan67/pagy/actions" rel="noopener" target="_blank"><img src="https://github.com/hayatkhan67/pagy/workflows/build/badge.svg" alt="GitHub Build Badge"></a>
	<a href="https://opensource.org/licenses/MIT" rel="noopener" target="_blank"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="MIT License Badge"></a>
	<a href="https://github.com/hayatkhan67/pagy" rel="noopener" target="_blank"><img src="https://img.shields.io/badge/platform-flutter-ff69b4.svg" alt="Flutter Platform Badge"></a>
</p>

---

# Pagy - A Flutter Package for Pagination

**Pagy** is a Flutter package designed for smooth, efficient, and customizable pagination in your apps. It allows you to load data in chunks and display it seamlessly while handling API responses, pagination strategies, and UI components like shimmer effects.

<img src="https://raw.githubusercontent.com/hayatkhan67/pagy/main/assets/logo.png" alt="Example Project" />

## Usage

### Example: Paginating Property Data

Here’s an example of how you can use **Pagy** in your project to paginate through property data from an API:

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
  PagyController<PropertyModel> pagyController = PagyController(
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
    super.dispose();
    pagyController.dispose();
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
