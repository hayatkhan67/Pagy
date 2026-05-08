# Migration Guide

This guide helps you upgrade to Pagy 1.0.0 with minimal code changes.

## Overview

Version 1.0.0 introduces better naming conventions and new features while maintaining full backward compatibility. All old parameter names still work but show deprecation warnings and will be removed in v2.0.0.

---

## Breaking Changes

**None** - This is a backward-compatible release. Your existing code will continue to work.

---

## Deprecated Parameters

The following parameters have been renamed for better clarity. Both old and new names work in v1.0.0.

### PagyController

| Old Name | New Name | Reason |
|----------|----------|--------|
| `responseMapper` | `responseParser` | More accurate - it parses, not maps |
| `additionalQueryParams` | `query` | Shorter, clearer |
| `paginationMode` | `payloadMode` | More descriptive |

#### Example Migration

**Before (v0.x):**
```dart
PagyController<Product>(
  endPoint: "products",
  fromMap: Product.fromJson,
  responseMapper: (response) {
    return PagyResponseParser(
      list: response['data'],
      totalPages: response['pagination']['totalPages'],
    );
  },
  additionalQueryParams: {'sort': 'latest'},
  paginationMode: PaginationPayloadMode.queryParams,
);
```

**After (v1.0.0):**
```dart
PagyController<Product>(
  endPoint: "products",
  fromMap: Product.fromJson,
  // Use built-in parser (new feature!)
  responseParser: PagyParsers.dataWithPagination,
  query: {'sort': 'latest'},
  payloadMode: PaginationPayloadMode.queryParams,
);
```

### PagyConfig

| Old Name | New Name | Reason |
|----------|----------|--------|
| `apiLogs` | `enableLogs` | More explicit |
| `paginationMode` | `payloadMode` | Consistent with controller |

#### Example Migration

**Before:**
```dart
PagyConfig().initialize(
  baseUrl: "https://api.example.com/",
  apiLogs: true,
  paginationMode: PaginationPayloadMode.queryParams,
);
```

**After:**
```dart
PagyConfig().initialize(
  baseUrl: "https://api.example.com/",
  enableLogs: true,
  payloadMode: PaginationPayloadMode.queryParams,
);
```

---

### ItemBuilder (v1.1.1+)

| Old Name | New Name | Reason |
|----------|----------|--------|
| `itemBuilder` | `itemBuilderWithIndex` | Provides access to item's index |

#### Example Migration

**Before (v1.1.0 and earlier):**
```dart
PagyListView<Product>(
  controller: pagyController,
  itemBuilder: (context, product) {
    return ProductTile(product: product);
  },
)
```

**After (v1.1.1+):**
```dart
PagyListView<Product>(
  controller: pagyController,
  itemBuilderWithIndex: (context, product, index) {
    return ProductTile(
      product: product,
      position: index + 1,  // Now you have access to the index!
    );
  },
)
```

**Use Cases for Index:**
- **Numbering**: Show "#1", "#2", etc. next to items
- **Alternating colors**: `color: index.isEven ? Colors.white : Colors.grey`
- **Position logic**: Different styling for first/last items
- **Analytics**: Track which position users interact with most

---

### Controller Helpers (v1.4.0+)

The helper methods on `PagyController` have been renamed for clarity and consistency. All old methods still work and delegate to the new implementations.

| Old Name | New Name | Why |
|----------|----------|-----|
| `addItem()` | `add()` | Shorter, uses `InsertPosition` enum |
| `addItems()` | `addAll()` | Consistent with Dart `List` naming |
| `updateItemAt()` | `update()` | Shorter |
| `removeWhere()` | `remove(where:)` | Named param is self-documenting |
| `insertAt()` | `insert()` | Consistent with `List.insert` |
| `replaceWhere()` | `replace(where:, replacement:)` | Named params |
| `mapItems()` | `map()` | Matches `Iterable.map` |
| `updateData()` | `setData()` | Clearer intent |
| `listen()` | `onChange()` | Returns cancel callback |
| `listenWithCancel()` | `onChange()` | Same, better name |
| `modifyDirect()` | `modifyState()` | Describes what it modifies |

#### Example Migration

**Before (v1.3.x — still works):**
```dart
// Adding items
controller.addItem(user, atStart: true);
controller.addItems(users, atStart: false);

// Updating items
controller.updateItemAt(0, updatedUser);
controller.mapItems((u) => u.copyWith(isOnline: false));

// Removing items
controller.removeWhere((u) => u.id == userId);

// Replacing items
controller.replaceWhere((u) => u.id == userId, updatedUser);

// Listening
controller.listen((items) => print(items.length));
```

**After (v1.4.0 — recommended):**
```dart
// Adding items
controller.add(user, position: InsertPosition.start);
controller.addAll(users);

// Updating items
controller.update(0, updatedUser);
controller.map((u) => u.copyWith(isOnline: false));

// Removing items — now returns count!
final removedCount = controller.remove(where: (u) => u.id == userId);

// Replacing items
controller.replace(where: (u) => u.id == userId, replacement: updatedUser);

// Listening — now returns cancel callback!
final cancel = controller.onChange((items) => print(items.length));
cancel(); // cleanup
```

#### New Methods (no old equivalent)

These are entirely new — no migration needed:

```dart
// Update matching items with a transform function
controller.updateWhere(
  where: (u) => u.id == userId,
  update: (u) => u.copyWith(status: 'active'),
);

// Upsert — update if exists, insert if not
controller.upsertWhere(
  where: (u) => u.id == user.id,
  update: (old) => old.copyWith(name: user.name),
  item: user,
);

// Batch — multiple changes, single rebuild
controller.batch((items) {
  items.removeWhere((u) => u.isBlocked);
  items.sort((a, b) => a.name.compareTo(b.name));
});

// Query
final admin = controller.firstWhereOrNull((u) => u.isAdmin);
final exists = controller.contains((u) => u.id == userId);

// Reordering
controller.sort((a, b) => a.createdAt.compareTo(b.createdAt));
controller.swap(0, 1);
controller.move(from: 3, to: 0);

// State inspection
print(controller.isEmpty);
print(controller.length);
print(controller.first);
```

## New Features in 1.0.0

### 1. Built-in Response Parsers

Instead of writing custom `responseMapper` functions, use pre-built parsers:

```dart
// Instead of this:
responseMapper: (response) => PagyResponseParser(
  list: response['data'],
  totalPages: response['pagination']['totalPages'],
),

// Use this:
responseParser: PagyParsers.dataWithPagination
```

Available parsers:
- `PagyParsers.dataWithPagination`
- `PagyParsers.itemsWithTotal`
- `PagyParsers.resultsWithCount`
- `PagyParsers.simpleList`
- `PagyParsers.laravel`
- `PagyParsers.django`
- `PagyParsers.customKey`

### 2. Pagination Metadata

Easy access to pagination info for UI:

```dart
// Show page numbers
Text('Page ${controller.metadata.currentPage} of ${controller.metadata.totalPages}')

// Progress bar
LinearProgressIndicator(value: controller.metadata.progress)

// Check if more pages exist
if (controller.metadata.hasMore) {
  // Show load more button
}
```

### 3. Convenience Methods

```dart
// Refresh from page 1
await controller.refresh();

// Search
await controller.search('laptop');

// Apply filters
await controller.applyFilters({'category': 'electronics'});

// Load next page explicitly
await controller.loadMore();
```

### 4. Enhanced Error Handling

```dart
// Access detailed error information
if (state.error != null) {
  print('Error: ${state.error!.message}');
  print('Type: ${state.error!.type}');
  print('Suggestion: ${state.error!.suggestion}');
  print('Status Code: ${state.error!.statusCode}');
}
```

### 5. Better Configuration Validation

PagyConfig now validates your settings and provides helpful warnings:

```dart
// ❌ Will show error
PagyConfig().initialize(
  baseUrl: "invalid-url",  // Error: must start with http:// or https://
);

// ⚠️ Will show warning
PagyConfig().initialize(
  baseUrl: "https://api.example.com",  // Warning: consider adding trailing /
);

// ✅ Best practice
PagyConfig().initialize(
  baseUrl: "https://api.example.com/",  // Perfect!
);
```

---

## Migration Steps

### Step 1: Update pubspec.yaml

```yaml
dependencies:
  pagy: ^1.0.0
```

Run: `flutter pub get`

### Step 2: Review Deprecation Warnings

Run your app and look for deprecation warnings in the console. They'll guide you to the new parameter names.

### Step 3: Update Parameter Names (Optional)

Using your IDE's find-and-replace:

1. Find: `responseMapper:` → Replace: `responseParser:`
2. Find: `additionalQueryParams:` → Replace: `query:`
3. Find: `apiLogs:` → Replace: `enableLogs:`

### Step 4: Consider Using Built-in Parsers

Review your `responseMapper/responseParser` functions. If they match common patterns, replace them with built-in parsers:

**Common pattern:**
```dart
// Your custom parser
responseParser: (response) {
  return PagyResponseParser(
    list: response['data'],
    totalPages: response['pagination']['totalPages'],
  );
}

// Can be replaced with:
responseParser: PagyParsers.dataWithPagination
```

### Step 5: Test Thoroughly

Run your tests to ensure everything works as expected.

---

## No Action Required

If you prefer, you can continue using the old parameter names. They'll work perfectly in v1.0.0, though you'll see deprecation warnings. You have until v2.0.0 to migrate.

---

## Getting Help

If you encounter issues during migration:

1. Check the deprecation warning message - it tells you the replacement
2. Review the [README](./README.md) for updated examples
3. [Open an issue](https://github.com/hayatkhan67/pagy/issues) on GitHub

---

## Future (v2.0.0)

In the next major version, deprecated parameters will be removed. Plan to migrate before then if you haven't already.
