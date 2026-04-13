<p align="center">
	<img src="https://raw.githubusercontent.com/hayatkhan67/pagy/beta/assets/logo.png" alt="Pagy Logo" width="200"/>
</p>
<p align="center">
	<i>A powerful Flutter package for effortless API pagination with shimmer effects, error handling, and smooth scrolling</i>
</p>

<p align="center">
	<a href="https://pub.dev/packages/pagy"><img src="https://img.shields.io/pub/v/pagy.svg?label=pub&color=blue" alt="Pub Version"></a>
	<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="MIT License"></a>
	<a href="https://github.com/hayatkhan67/pagy"><img src="https://img.shields.io/badge/platform-flutter-ff69b4.svg" alt="Flutter Platform"></a>
	<a href="https://github.com/hayatkhan67/pagy/stargazers"><img src="https://img.shields.io/github/stars/hayatkhan67/pagy?style=social" alt="GitHub Stars"></a>
</p>

<p align="center">
	<a href="https://github.com/hayatkhan67/pagy">GitHub</a> •
	<a href="https://pub.dev/packages/pagy">pub.dev</a> •
	<a href="https://github.com/hayatkhan67/pagy/issues">Report Bug</a> •
	<a href="https://github.com/hayatkhan67/pagy/issues">Request Feature</a>
</p>

---

## ✨ Features

**Pagy** is a **plug-and-play pagination solution** for Flutter apps that makes implementing paginated lists incredibly easy:

- ✅ **Smart API Integration** - Query params, body payloads, and custom headers support
- 🚫 **Auto-cancellation** - Duplicate API calls automatically cancelled
- 🎨 **Beautiful UI** - Built-in shimmer effects, error states, and empty state handling  
- 🔧 **Built-in Parsers** - Laravel, Django, and 5+ common API formats supported
- 📊 **Advanced Metadata** - Progress tracking, page indicators, and load status
- 🔐 **Interceptors** - Custom auth tokens, retries, and request modification
- 🧩 **State Management** - Works with Bloc, Riverpod, Provider, or standalone
- 🌗 **Theme Support** - Automatic light/dark theme adaptation
- 🏗️ **Clean Architecture** - Dependency injection friendly
- ⚡ **Performance** - Optimized scrolling with lazy loading

---

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  pagy: ^1.2.1
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

> **💡 New in v1.2.1:** Persistence is now handled automatically. Filters are kept during retries and can optionally be kept during refreshes.

---

## 🔍 Advanced Features

### 1. Filter Persistence

Pagy now automatically persists your filters across `loadMore()` and `retry()` calls. You can also control whether filters are kept when the user pulls to refresh.

**Global Config:**
```dart
PagyConfig().initialize(
  baseUrl: "...",
  preserveFiltersOnRefresh: true, // Keep filters when pulling to refresh
);
```

**Manual Refresh with Control:**
```dart
// Keep filters for this refresh only
pagyController.refresh(preserveFilters: true);

// Clear filters manually
pagyController.clearFilters();
```

### 2. Custom Refresh Indicator

You can use any third-party refresh indicator (like `liquid_pull_to_refresh` or `custom_refresh_indicator`) by providing the `refreshIndicatorBuilder`.

```dart
PagyListView<Product>(
  controller: pagyController,
  refreshIndicatorBuilder: (context, child, onRefresh) {
    return MyCustomRefreshIndicator(
      onRefresh: onRefresh,
      child: child,
    );
  },
  itemBuilder: (context, product) => ProductCard(product: product),
)
```

### 3. Error Handling & Stacktraces

For better developer experience, `PagyError` now captures the stacktrace of the failure.

```dart
if (pagyController.controller.value.error != null) {
  final error = pagyController.controller.value.error!;
  print(error.message);
  print(error.stackTrace); // Access the full stacktrace
}
```

### 4. Clean Architecture Pathway

Pagy now supports a more structured approach for enterprise apps using repositories and use cases.

```dart
// 1. Create your repository
final repository = PagyPageRepository(
  endPoint: "products",
  fromMap: Product.fromJson,
);

// 2. Wrap in a Use Case (optional but recommended)
final useCase = GetPaginatedPageUseCase(repository);

// 3. Pass to Controller
pagyController = PagyController(
  useCase: useCase,
  // ...other config
);
```

---

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

### 5. Horizontal List View

Perfect for category carousels, featured products, or horizontal galleries:

#### Fixed Height (Default)
```dart
SizedBox(
  height: 200,
  child: PagyHorizontalListView<Category>(
    controller: categoryController,
    itemBuilderWithIndex: (context, category, index) {
      return CategoryCard(category: category);
    },
    itemSpacing: 12,
    shimmerEffect: true,
    placeholderItemModel: Category.empty(),
  ),
)
```

> **💡 Note:** By default, wrap `PagyHorizontalListView` in a `SizedBox` or `Container` with a fixed height since horizontal lists need constrained height.

#### Dynamic Height (New!)

Use `useDynamicHeight: true` when you want the height to be determined by content (intrinsic sizing). This is useful inside `Column`, `ListView`, or any layout where you don't want a fixed height:

```dart
Column(
  children: [
    Text('Featured Categories'),
    PagyHorizontalListView<Category>(
      controller: categoryController,
      useDynamicHeight: true, // Uses Row + SingleChildScrollView
      itemBuilderWithIndex: (context, category, index) {
        return CategoryCard(category: category);
      },
      itemSpacing: 12,
    ),
  ],
)
```

> **💡 Note:** When `useDynamicHeight` is `true`, all items are built upfront (not lazily), so use with caution for very large lists.


### 6. Show Pagination Info in UI

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

### 7. Error Handling

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

### ItemBuilder (v1.1.1+)

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

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

<p align="center">
  <img src="https://github.com/hayatkhan67.png" width="100" style="border-radius: 50%;" alt="Hayat Khan"/>
</p>

<h3 align="center">Hayat Khan</h3>

<p align="center">
  <i>Flutter Developer & Open Source Contributor</i>
</p>

<p align="center">
  <a href="https://github.com/hayatkhan67">
    <img src="https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white" alt="GitHub"/>
  </a>
  <a href="https://www.linkedin.com/in/hayat-khan-263217281/">
    <img src="https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn"/>
  </a>
  <a href="mailto:hayatkhan626225@gmail.com">
    <img src="https://img.shields.io/badge/Email-D14836?style=for-the-badge&logo=gmail&logoColor=white" alt="Email"/>
  </a>
</p>

---

<p align="center">
  <b>If you found this package helpful, please give it a ⭐ on <a href="https://github.com/hayatkhan67/pagy">GitHub</a>!</b>
</p>

<p align="center">
  Made with ❤️ by <a href="https://github.com/hayatkhan67">Hayat Khan</a>
</p>
