// Seller inventory manager for boutiques.
//
// This screen creates and edits catalog products, uploads product
// images, and stores optional per-size inventory. When size inventory exists,
// the total stock field is still saved for legacy screens and quick summaries.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/utils/stock_status.dart';
import 'package:banigoba/modules/shop/controllers/admin_products_controller.dart';
import 'package:banigoba/modules/shop/widgets/admin_product_tile.dart';
import 'package:banigoba/modules/shop/widgets/product_form_sheet.dart';
import 'package:banigoba/modules/shop/widgets/stock_edit_sheet.dart';

/// Product and inventory manager for the current seller.
class AdminProductsPage extends StatelessWidget {
  const AdminProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Scoped to this screen: created and disposed with the widget.
    return GetBuilder<AdminProductsController>(
      init: AdminProductsController(),
      global: false,
      builder: (controller) => AdminProductsView(controller: controller),
    );
  }
}

/// The product list with its add buttons. The shop dashboard shows it as its
/// Stock tab, without the app bar.
class AdminProductsView extends StatelessWidget {
  const AdminProductsView({
    super.key,
    required this.controller,
    this.showAppBar = true,
  });

  static const Color primaryColor = Color(0xFF0D0140);

  final AdminProductsController controller;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('Products & Inventory'),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: Obx(() {
        if (!controller.loaded.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.products.isEmpty) {
          return const Center(
            child: Text('No products yet. Add your first listing.'),
          );
        }
        final products = controller.filtered;
        return Column(
          children: [
            _stockHeader(controller.summary),
            Expanded(
              child: products.isEmpty
                  ? const Center(child: Text('Nothing in this group.'))
                  : _productList(context, products),
            ),
          ],
        );
      }),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            key: const ValueKey('quick_add_button'),
            heroTag: 'quick_add',
            onPressed: controller.openQuickAdd,
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.bolt),
            label: const Text('Quick add'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'full_add',
            onPressed: () => showProductFormSheet(context),
            backgroundColor: primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Totals and filter chips: all pieces, the low ones, the sold out ones.
  Widget _stockHeader(StockSummary summary) {
    Widget chip(String label, StockLevel? level) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        key: ValueKey('stock_filter_${level?.name ?? 'all'}'),
        label: Text(label),
        selected: controller.stockFilter.value == level,
        onSelected: (_) => controller.filterBy(level),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip('All (${summary.total})', null),
            chip('Low (${summary.low})', StockLevel.low),
            chip('Sold out (${summary.soldOut})', StockLevel.soldOut),
          ],
        ),
      ),
    );
  }

  Widget _productList(
    BuildContext context,
    List<Map<String, dynamic>> products,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final data = products[index];
        final docId = data['id'].toString();
        final reach = controller.reach[docId];
        return AdminProductTile(
          product: data,
          reachText: reachLabel(
            reach: reach?.reach,
            followers: reach?.followers,
          ),
          onStock: () => _editStock(context, docId, data),
          onEdit: () =>
              showProductFormSheet(context, docId: docId, existingData: data),
          onDelete: () =>
              _confirmDelete(context, docId, data['name'] ?? 'No Name'),
        );
      },
    );
  }

  /// Changes how many are left, without opening the full form.
  Future<void> _editStock(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) async {
    final edit = await showStockEditSheet(context, data);
    if (edit == null) return;
    await controller.applyStock(id, edit);
  }

  /// Confirm deletion of a catalog product
  void _confirmDelete(BuildContext context, String id, Object name) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text(
          "Are you sure you want to remove '$name' from your boutique? "
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => controller.delete(id),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
