<p align="center">
	<img src="https://raw.githubusercontent.com/hayatkhan67/pagy/main/assets/logo.png" alt="Package Logo" />
</p>
<p align="center">
	<i>Pagy - A simple Flutter package for smooth pagination</i>
</p>
<p align="center">
	<a href="https://pub.dev/packages/pagy" rel="noopener" target="_blank"><img src="https://img.shields.io/pub/v/pagy.svg" alt="Pub.dev Badge"></a>
	<a href="https://opensource.org/licenses/MIT" rel="noopener" target="_blank"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="MIT License Badge"></a>
	<a href="https://github.com/hayatkhan67/pagy" rel="noopener" target="_blank"><img src="https://img.shields.io/badge/platform-flutter-ff69b4.svg" alt="Flutter Platform Badge"></a>
</p>

---

# 🚀 Pagy - A Flutter Package for Pagination

**Pagy** is a **plug-and-play pagination solution** for Flutter apps. It handles:

- API pagination (query params, body payloads, headers).
- Auto-cancel of duplicate API calls.
- Global styles (placeholders, shimmer, spacing).
- API interceptors (for auth tokens, retries, etc.).
- Logging and monitoring.
- Easy integration with **Bloc**, **Riverpod**, or direct controllers.
- Works with both **light and dark themes** automatically.
- Clean Architecture friendly – can be injected into repositories/services.

---

## Usage

### Example: Paginating Property Data

Here’s an example of how you can use **Pagy** in your project to paginate through property data from an API:

```dart
import 'package:flutter/material.dart';
import 'package:pagy/pagy.dart';

import 'views/nav_screen.dart';

void main() {
  PagyConfig().initialize(
    baseUrl: "Your API Base URL",
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
  late PagyController<PropertyModel> pagyController;

  @override
  void initState() {
    super.initState();
    pagyController = PagyController(
      endPoint: "properties",
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
    return PagyListView<PropertyModel>(
      itemSpacing: 10,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      // separatorBuilder: (context, index) => const Divider(),
      controller: pagyController,
      placeholderItemCount: 10,
      shimmerEffect: true,
      placeholderItemModel: PropertyModel(),
      itemBuilder: (context, item) {
        return PropertyCardWidget(data: item);
      },
    );
  }
}

```
