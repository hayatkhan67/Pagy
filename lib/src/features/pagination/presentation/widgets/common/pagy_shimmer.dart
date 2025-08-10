import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PagyShimmer<T> extends StatelessWidget {
  final int count;
  final Widget Function(BuildContext, int) itemBuilder;
  final Widget Function(IndexedWidgetBuilder) layoutBuilder;

  const PagyShimmer({
    super.key,
    required this.count,
    required this.itemBuilder,
    required this.layoutBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: layoutBuilder(
        (ctx, index) => itemBuilder(ctx, index),
      ),
    );
  }
}
