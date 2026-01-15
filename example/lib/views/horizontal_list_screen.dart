import 'package:flutter/material.dart';
import 'package:pagy/pagy.dart';

import '../models/property_model.dart';

/// Example screen demonstrating PagyHorizontalListView usage.
///
/// This screen shows how to use horizontal pagination for carousels,
/// featured items, or horizontal galleries.
class HorizontalListScreen extends StatefulWidget {
  const HorizontalListScreen({super.key});

  @override
  State<HorizontalListScreen> createState() => _HorizontalListScreenState();
}

class _HorizontalListScreenState extends State<HorizontalListScreen> {
  late PagyController<PropertyModel> pagyController;

  @override
  void initState() {
    super.initState();
    pagyController = PagyController(
      endPoint: "properties",
      requestType: PagyApiRequestType.post,
      fromMap: PropertyModel.fromJson,
      limit: 6,
      responseParser: (response) {
        return PagyResponseParser(
          list: response['data'],
          totalPages: response['pagination']['totalPages'],
        );
      },
      payloadMode: PaginationPayloadMode.queryParams,
    );

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
      appBar: AppBar(title: const Text('Horizontal List Example')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Featured Properties',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => pagyController.refresh(),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Horizontal Paginated List
            PagyHorizontalListView<PropertyModel>(
              // useDynamicHeight: true,
              controller: pagyController,
              itemSpacing: 12,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shimmerEffect: true,
              placeholderItemCount: 3,
              placeholderItemModel: PropertyModel(),
              itemBuilderWithIndex: (context, item, index) {
                return _PropertyHorizontalCard(property: item, index: index);
              },
              emptyMessage: 'No properties found',
              emptyIcon: Icons.home_work_outlined,
            ),

            const SizedBox(height: 32),

            // Additional info section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Swipe horizontally to load more →',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Show pagination info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PagyObserver<PropertyModel>(
                controller: pagyController,
                builder: (context, state) {
                  if (state.isFetching) {
                    return const Text('Loading...');
                  }
                  return Text(
                    'Page ${pagyController.metadata.currentPage} of ${pagyController.metadata.totalPages} • '
                    '${state.data.length} items loaded',
                    style: const TextStyle(color: Colors.grey),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// A horizontal card widget for displaying property items.
class _PropertyHorizontalCard extends StatelessWidget {
  final PropertyModel property;
  final int index;

  const _PropertyHorizontalCard({required this.property, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            height: 120,
            width: double.infinity,
            color: Colors.grey[200],
            child: property.image != null && property.image!.isNotEmpty
                ? Image.network(
                    property.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Index badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#${index + 1}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Title
                Text(
                  property.title ?? 'No Title',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),

                // Price
                Text(
                  '\$${property.price ?? 0}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(Icons.home_work_outlined, size: 40, color: Colors.grey),
    );
  }
}
