import 'package:flutter/material.dart';

class CatergorieNameRow extends StatefulWidget {
  const CatergorieNameRow({
    super.key,
    this.onChanged,
    this.itemList,
    this.isLoading = false,
    this.isSubProductLoading = false,
  });
  final Function(String v)? onChanged;
  final List<String>? itemList;
  final bool isLoading;
  final bool isSubProductLoading;

  @override
  State<CatergorieNameRow> createState() => _CatergorieNameRowState();
}

class _CatergorieNameRowState extends State<CatergorieNameRow> {
  get onChanged => widget.onChanged;
  List<String>? get items => widget.itemList;
  String selectedItem = 'all';

  void selectItem(value, {bool isInit = false}) {
    selectedItem = value;
    if (onChanged != null && !isInit) {
      onChanged(value);
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (items?.contains('all') ?? false) {
        selectItem('all', isInit: true);
      } else if (items?.isNotEmpty ?? false) {
        selectItem(items?[0], isInit: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 10),
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(items?.length ?? 0, (index) {
          String? categorieItem = items?[index];
          bool isSelected = selectedItem == categorieItem;

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap:
                  widget.isSubProductLoading
                      ? null
                      : () => selectItem(categorieItem),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 21,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.purpleAccent : Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  // border: Border.all(
                  // color: isSelected
                  //     ? AppColors.extraligthblue
                  //     : context.appColors.cardBackground,
                  // ),
                ),
                child: Text(
                  (categorieItem ?? ''),
                  style: TextStyle(
                    fontSize: 12,
                    color: !isSelected ? Colors.purpleAccent : Colors.white,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
