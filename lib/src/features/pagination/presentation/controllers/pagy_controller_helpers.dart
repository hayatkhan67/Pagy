part of 'pagy_controller.dart';

extension PagyControllerHelpers<T> on PagyController<T> {
  void updateData(List<T> newData) {
    itemsList
      ..clear()
      ..addAll(newData);
    controller.value = controller.value.copyWith(data: [...itemsList]);
  }

  void addItem(T item, {bool atStart = false}) {
    atStart ? itemsList.insert(0, item) : itemsList.add(item);
    controller.value = controller.value.copyWith(data: [...itemsList]);
  }

  void addItems(List<T> items, {bool atStart = false}) {
    atStart ? itemsList.insertAll(0, items) : itemsList.addAll(items);
    controller.value = controller.value.copyWith(data: [...itemsList]);
  }

  void updateItemAt(int index, T newItem) {
    if (index >= 0 && index < itemsList.length) {
      itemsList[index] = newItem;
      controller.value = controller.value.copyWith(data: [...itemsList]);
    }
  }

  void removeWhere(bool Function(T item) test) {
    itemsList.removeWhere(test);
    controller.value = controller.value.copyWith(data: [...itemsList]);
  }

  void clearItems() {
    itemsList.clear();
    controller.value = controller.value.copyWith(
      data: [],
      currentPage: 0,
      totalPages: 1,
    );
  }

  void dispose() {
    controller.dispose();
  }
}
