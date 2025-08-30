part of 'pagy_controller.dart';

extension PagyControllerHelpers<T> on PagyController<T> {
  /// Replace full data
  void updateData(List<T> newData) {
    itemsList
      ..clear()
      ..addAll(newData);
    _emit();
  }

  /// Add single item
  void addItem(T item, {bool atStart = false}) {
    atStart ? itemsList.insert(0, item) : itemsList.add(item);
    _emit();
  }

  /// Add multiple items
  void addItems(List<T> items, {bool atStart = false}) {
    atStart ? itemsList.insertAll(0, items) : itemsList.addAll(items);
    _emit();
  }

  /// Update item at given index
  void updateItemAt(int index, T newItem) {
    if (index >= 0 && index < itemsList.length) {
      itemsList[index] = newItem;
      _emit();
    }
  }

  /// Remove items matching condition
  void removeWhere(bool Function(T item) test) {
    itemsList.removeWhere(test);
    _emit();
  }

  /// Clear all items
  void _clearItems() {
    itemsList.clear();
    controller.value = controller.value.copyWith(
      data: [],
      currentPage: 0,
      totalPages: 1,
    );
  }

  /// 🚀 New: Insert at a specific index (safe insert)
  void insertAt(int index, T item) {
    if (index < 0 || index > itemsList.length) {
      itemsList.add(item);
    } else {
      itemsList.insert(index, item);
    }
    _emit();
  }

  /// 🚀 New: Replace item by condition
  void replaceWhere(bool Function(T item) test, T newItem) {
    final index = itemsList.indexWhere(test);
    if (index != -1) {
      itemsList[index] = newItem;
      _emit();
    }
  }

  /// 🚀 New: Update all items with mapper
  void mapItems(T Function(T old) mapper) {
    final updated = itemsList.map(mapper).toList();
    itemsList
      ..clear()
      ..addAll(updated);
    _emit();
  }

  /// 🚀 New: Reset to initial empty state
  void reset() {
    _clearItems();
  }

  /// Internal emit helper
  void _emit() {
    controller.value = controller.value.copyWith(data: [...itemsList]);
  }

  /// 🚀 Direct access for advanced use cases
  void modifyDirect(ValueUpdater<PagyState<T>> updater) {
    final updated = updater(controller.value);
    itemsList
      ..clear()
      ..addAll(updated.data);
    controller.value = updated;
  }

  void dispose() {
    controller.dispose();
  }
}

/// Signature for direct modification
typedef ValueUpdater<S> = S Function(S state);
