part of 'pagy_controller.dart';

/// Extension providing helper methods for manipulating paginated data
/// inside a [PagyController].
///
/// These utilities allow adding, updating, removing, or resetting items
/// in the local cache while keeping [PagyState] in sync.
extension PagyControllerHelpers<T> on PagyController<T> {
  /// Replaces the entire dataset with [newData].
  void updateData(List<T> newData) {
    itemsList
      ..clear()
      ..addAll(newData);
    _emit();
  }

  /// Adds a single [item] to the list.
  ///
  /// By default, items are appended at the end.
  /// Use [atStart] to insert the item at the beginning.
  void addItem(T item, {bool atStart = false}) {
    atStart ? itemsList.insert(0, item) : itemsList.add(item);
    _emit();
  }

  /// Adds multiple [items] to the list.
  ///
  /// Items can be inserted at the beginning if [atStart] is true.
  void addItems(List<T> items, {bool atStart = false}) {
    atStart ? itemsList.insertAll(0, items) : itemsList.addAll(items);
    _emit();
  }

  /// Updates the item at [index] with [newItem].
  ///
  /// If [index] is out of range, no action is taken.
  void updateItemAt(int index, T newItem) {
    if (index >= 0 && index < itemsList.length) {
      itemsList[index] = newItem;
      _emit();
    }
  }

  /// Removes items that match the given [test] condition.
  void removeWhere(bool Function(T item) test) {
    itemsList.removeWhere(test);
    _emit();
  }

  /// Clears all items and resets pagination state to initial.
  void _clearItems() {
    itemsList.clear();
    controller.value = controller.value.copyWith(
      data: [],
      currentPage: 0,
      totalPages: 1,
    );
  }

  /// Inserts an [item] at a specific [index].
  ///
  /// If [index] is invalid, the item is appended to the end.
  void insertAt(int index, T item) {
    if (index < 0 || index > itemsList.length) {
      itemsList.add(item);
    } else {
      itemsList.insert(index, item);
    }
    _emit();
  }

  /// Replaces the first item matching [test] with [newItem].
  ///
  /// If no item matches, no action is taken.
  void replaceWhere(bool Function(T item) test, T newItem) {
    final index = itemsList.indexWhere(test);
    if (index != -1) {
      itemsList[index] = newItem;
      _emit();
    }
  }

  /// Maps all items in the list using the provided [mapper] function.
  ///
  /// Useful for bulk updates, e.g., toggling a property across items.
  void mapItems(T Function(T old) mapper) {
    final updated = itemsList.map(mapper).toList();
    itemsList
      ..clear()
      ..addAll(updated);
    _emit();
  }

  /// Resets the controller to its initial empty state.
  void reset() {
    _clearItems();
  }

  /// Internal helper to emit the current list and update [PagyState].
  void _emit() {
    controller.value = controller.value.copyWith(data: [...itemsList]);
  }

  /// Directly modifies the [PagyState] using an [updater] callback.
  ///
  /// This allows advanced customizations of the state while keeping the
  /// item list and state synchronized.
  void modifyDirect(ValueUpdater<PagyState<T>> updater) {
    final updated = updater(controller.value);
    itemsList
      ..clear()
      ..addAll(updated.data);
    controller.value = updated;
  }

  /// Disposes the underlying [ValueNotifier] to free resources.
  void dispose() {
    controller.dispose();
  }
}

/// Signature for functions that update a given [PagyState].
typedef ValueUpdater<S> = S Function(S state);
