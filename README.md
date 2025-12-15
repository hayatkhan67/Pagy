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

- ✅ API pagination (query params, body payloads, headers)
- 🚫 Auto-cancel of duplicate API calls
- 🎨 Global styles (placeholders, shimmer, spacing)
- 🔐 API interceptors (for auth tokens, retries, etc.)
- 📊 Logging and monitoring
- 🧩 Easy integration with **Bloc**, **Riverpod**, or direct controllers
- 🌗 Works with both **light and dark themes** automatically
- 🏗️ Clean Architecture friendly – can be injected into repositories/services

---

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  pagy: ^1.0.0
```

Then run:

```bash
flutter pub get
```

---

## 🎯 Quick Start

### Step 1: Initialize Pagy

In your `main.dart`, configure Pagy before running your app:

```dart
import 'package:flutter/material.dart';
import 'package:pagy/pagy.dart';

void main() {
  // Initialize Pagy with your API configuration
  PagyConfig().initialize(
    baseUrl: "https://api.example.com/",
    pageKey: 'page',          // Your API's page param name
    limitKey: 'limit',        // Your API's limit param name
    enableLogs: true,         // Enable debug logs
    payloadMode: PaginationPayloadMode.queryParams, // or .payload for body
  );

  runApp(const MyApp());
}
```

### Step 2: Create Your Model

```dart
class Product {
  final int id;
  final String name;
  final String image;
  final double price;

  Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
  });

  // Factory for JSON parsing
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      price: json['price'].toDouble(),
    );
  }

  // Empty constructor for shimmer placeholder
  Product.empty()
      : id = 0,
        name = 'Loading...',
        image = '',
        price = 0.0;
}
```

### Step 3: Set Up Controller

```dart
import 'package:flutter/material.dart';
import 'package:pagy/pagy.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late PagyController<Product> pagyController;

  @override
  void initState() {
    super.initState();
    
    pagyController = PagyController(
      endPoint: "products",
      requestType: PagyApiRequestType.get,
      fromMap: Product.fromJson,
      limit: 20,
      // Use built-in parser for common response structures
      responseParser: PagyParsers.dataWithPagination,
      // Or custom parser:
      // responseParser: (response) => PagyResponseParser(
      //   list: response['data'],
      //   totalPages: response['pagination']['totalPages'],
      // ),
    );

    // Load initial data
    pagyController.loadData();
  }

  @override
  void dispose() {
    pagyController.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: PagyListView<Product>(
        controller: pagyController,
        itemSpacing: 10,
        padding: const EdgeInsets.all(16),
        shimmerEffect: true,
        placeholderItemCount: 10,
        placeholderItemModel: Product.empty(),
        // Use itemBuilderWithIndex to access item's position
        itemBuilderWithIndex: (context, product, index) {
          return ProductCard(
            product: product,
            position: index + 1, // Show item number
          );
        },
      ),
    );
  }
}
```

> **💡 New in v1.0.2:** Use `itemBuilderWithIndex` to access the item's index for features like numbering, alternating colors, or position-based logic.

---

## 🎨 ItemBuilder Options

### With Index (Recommended)

Access the item's position in the list:

```dart
PagyListView<Product>(
  controller: pagyController,
  itemBuilderWithIndex: (context, product, index) {
    return Card(
      color: index.isEven ? Colors.white : Colors.grey[100],
      child: ListTile(
        leading: CircleAvatar(child: Text('#${index + 1}')),
        title: Text(product.name),
      ),
    );
  },
)
```

### Without Index (Deprecated)

If you don't need the index, the old signature still works but is deprecated:

```dart
PagyListView<Product>(
  controller: pagyController,
  itemBuilder: (context, product) { // ⚠️ Deprecated
    return ProductCard(product: product);
  },
)
```

---

## 🔧 Built-in Response Parsers

Reduce boilerplate with pre-built parsers for common API response structures:

```dart
// For: { "data": [...], "pagination": { "totalPages": 10 } }
responseParser: PagyParsers.dataWithPagination

// For: { "items": [...], "total_pages": 10 }
responseParser: PagyParsers.itemsWithTotal

// For: { "results": [...], "page_count": 10 }
responseParser: PagyParsers.resultsWithCount

// For Laravel: { "data": [...], "last_page": 10 }
responseParser: PagyParsers.laravel

// For Django: { "results": [...], "count": 100 }
responseParser: (response) => PagyParsers.django(response, itemsPerPage: 20)

// Custom key names
responseParser: (response) => PagyParsers.customKey(
  response,
  itemKey: 'users',
  totalKey: 'totalPages',
)
```

---

## 💡 Common Use Cases

### 1. Search & Filter

```dart
// Simple search
await pagyController.search('laptop computers');

// Apply filters
await pagyController.applyFilters({
  'category': 'electronics',
  'price_max': 1000,
  'in_stock': true,
});

// Custom query parameters
await pagyController.loadData(
  queryParameter: {
    'sort': 'price_desc',
    'brand': 'Apple',
  },
);
```

### 2. Pull-to-Refresh

```dart
RefreshIndicator(
  onRefresh: () async {
    await pagyController.refresh();
  },
  child: PagyListView<Product>(
    controller: pagyController,
    itemBuilder: (context, product) => ProductCard(product: product),
  ),
)
```

### 3. POST Requests with Authentication

```dart
pagyController = PagyController(
  endPoint: "private/orders",
  requestType: PagyApiRequestType.post,
  fromMap: Order.fromJson,
  token: "Bearer YOUR_AUTH_TOKEN",
  headers: {
    'X-Custom-Header': 'value',
  },
  payloadData: {
    'user_id': 123,
    'status': 'active',
  },
  responseParser: PagyParsers.dataWithPagination,
);
```

### 4. Grid View

```dart
PagyGridView<Product>(
  controller: pagyController,
  crossAxisCount: 2,
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
  shimmerEffect: true,
  placeholderItemModel: Product.empty(),
  itemBuilder: (context, product) {
    return ProductGridCard(product: product);
  },
)
```

### 5. Show Pagination Info in UI

```dart
// Display current page info
Text('Page ${pagyController.metadata.currentPage} of ${pagyController.metadata.totalPages}')

// Progress indicator
LinearProgressIndicator(value: pagyController.metadata.progress)

// Show loading state
if (pagyController.metadata.hasMore)
  TextButton(
    onPressed: pagyController.loadMore,
    child: const Text('Load More'),
  )
```

### 6. Error Handling

```dart
PagyObserver<Product>(
  controller: pagyController,
  builder: (context, state) {
    if (state.error != null) {
      return Column(
        children: [
          Text('Error: ${state.error!.message}'),
          if (state.error!.suggestion != null)
            Text('Suggestion: ${state.error!.suggestion}'),
          ElevatedButton(
            onPressed: pagyController.retry,
            child: const Text('Retry'),
          ),
        ],
      );
    }
    return PagyListView<Product>(...);
  },
)
```

---

## 🎨 Customization

### Custom Error Widget

```dart
PagyListView<Product>(
  controller: pagyController,
  errorBuilder: (message, retry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: retry,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  },
  itemBuilder: (context, product) => ProductCard(product: product),
)
```

### Custom Empty State

```dart
PagyListView<Product>(
  controller: pagyController,
  emptyStateRetryBuilder: (retry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 64),
          const Text('No products found'),
          TextButton(
            onPressed: retry,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  },
  itemBuilder: (context, product) => ProductCard(product: product),
)
```

---

## 🔄 Migration Guide (if upgrading from <1.0.0)

Version 1.0.0+ introduces better naming while maintaining backward compatibility. Old parameter names still work but are deprecated and will be removed in v2.0.0.

### PagyController

| Old (Deprecated) | New (Recommended) | 
|------------------|-------------------|
| `responseMapper` | `responseParser` |
| `additionalQueryParams` | `query` |
| `paginationMode` | `payloadMode` |

### PagyConfig

| Old (Deprecated) | New (Recommended) |
|------------------|-------------------|
| `apiLogs` | `enableLogs` |
| `paginationMode` | `payloadMode` |

### ItemBuilder (v1.0.2+)

| Old (Deprecated) | New (Recommended) |
|------------------|-------------------|
| `itemBuilder: (context, item) => ...` | `itemBuilderWithIndex: (context, item, index) => ...` |

**Why?** Access to the item's index enables features like:
- Item numbering ("#1", "#2", etc.)
- Alternating row colors
- Position-based styling
- Analytics tracking by position

### Example Migration

**Old (still works, shows deprecation warnings):**
```dart
PagyController(
  responseMapper: (response) => PagyResponseParser(...),
  additionalQueryParams: {'sort': 'latest'},
  paginationMode: PaginationPayloadMode.queryParams,
);

PagyListView(
  itemBuilder: (context, item) => ItemWidget(item), // No index access
)
```

**New (recommended):**
```dart
PagyController(
  responseParser: PagyParsers.dataWithPagination,
  query: {'sort': 'latest'},
  payloadMode: PaginationPayloadMode.queryParams,
);

PagyListView(
  itemBuilderWithIndex: (context, item, index) => ItemWidget(
    item: item,
    position: index + 1,
  ),
)
```

---

## 📝 Full Example

Check out the complete working example in the [`example`](./example) directory, which includes:

- ListView and GridView implementations
- Search and filtering
- Custom error/empty states
- Shimmer loading effects
- Pull-to-refresh
- State management with Riverpod

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 💬 Support

For questions or issues, please:
- Open an issue on [GitHub](https://github.com/hayatkhan67/pagy/issues)
- Check existing [discussions](https://github.com/hayatkhan67/pagy/discussions)
