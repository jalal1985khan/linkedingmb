import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/gmb_product.dart';
import '../business_flow/providers/active_location_provider.dart';
import '../dashboard/widgets/dashboard_header_bar.dart';
import '../notifications/notification_end_drawer.dart';
import '../shell/providers/shell_nav_provider.dart';
import 'providers/products_provider.dart';
import 'widgets/ai_product_analyzer_dialog.dart';
import 'widgets/product_form_dialog.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({
    super.key,
    this.showScaffold = true,
  });

  final bool showScaffold;

  void _openAddProductDialog(BuildContext context, WidgetRef ref) {
    ProductFormDialog.show(
      context,
      onSave: (product) async {
        final success = await ref.read(productsProvider.notifier).addProduct(product);
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added successfully!')),
          );
        }
        return success;
      },
    );
  }

  void _openEditProductDialog(BuildContext context, WidgetRef ref, GmbProduct product) {
    ProductFormDialog.show(
      context,
      product: product,
      onSave: (updated) async {
        final success = await ref.read(productsProvider.notifier).updateProduct(updated);
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully!')),
          );
        }
        return success;
      },
    );
  }

  void _openAIAnalyzerDialog(BuildContext context, WidgetRef ref, String defaultUrl) {
    AIProductAnalyzerDialog.show(
      context,
      initialWebsiteUrl: defaultUrl,
      onAnalyze: (url) => ref.read(productsProvider.notifier).analyzeWebsite(websiteUrl: url),
      onImport: (selected) async {
        final count = await ref.read(productsProvider.notifier).importSelectedProducts(selected);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully imported $count products!')),
          );
        }
        return count;
      },
    );
  }

  void _confirmDeleteProduct(BuildContext context, WidgetRef ref, GmbProduct product) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Delete product?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          content: Text(
            'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final success = await ref.read(productsProvider.notifier).deleteProduct(product.id);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product removed successfully')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Delete Product',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLocation = ref.watch(activeLocationProvider).activeLocation;
    final productsState = ref.watch(productsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E1B4B);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF0B0F19)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F4FF), Color(0xFFFAF8FF), Color(0xFFFFFFFF)],
            stops: [0.0, 0.35, 1.0],
          );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFFAF8FF),
      endDrawer: const NotificationEndDrawer(),
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
                child: DashboardHeaderBar(
                  title: 'Products',
                  subtitle: activeLocation?.name ?? 'SocialHive',
                  showSparkle: true,
                  showBackButton: true,
                  onBack: () => ref.handleSmartBack(context),
                  onOpenNotifications: () {
                    Scaffold.maybeOf(context)?.openEndDrawer();
                  },
                ),
              ),
              const SizedBox(height: 6),

              // Scrollable Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.read(productsProvider.notifier).loadProducts(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Web-Style Showcase Banner & Top Action Buttons
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isCompact = constraints.maxWidth < 640;

                              Widget buildAiSuggestBtn({bool expanded = false}) {
                                final btn = SizedBox(
                                  height: 40,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _openAIAnalyzerDialog(
                                      context,
                                      ref,
                                      activeLocation?.website ?? '',
                                    ),
                                    icon: const Icon(Icons.auto_awesome_rounded, size: 15, color: Color(0xFF9333EA)),
                                    label: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'AI Smart Suggest',
                                        maxLines: 1,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                          color: isDark ? const Color(0xFFC084FC) : const Color(0xFF7E22CE),
                                        ),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: isDark
                                          ? const Color(0xFF581C87).withValues(alpha: 0.25)
                                          : const Color(0xFFFAF5FF),
                                      side: BorderSide(
                                        color: isDark
                                            ? const Color(0xFF7E22CE).withValues(alpha: 0.4)
                                            : const Color(0xFFE9D5FF),
                                      ),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                    ),
                                  ),
                                );
                                return expanded ? Expanded(child: btn) : btn;
                              }

                              Widget buildAddProductBtn({bool expanded = false}) {
                                final btn = SizedBox(
                                  height: 40,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _openAddProductDialog(context, ref),
                                    icon: const Icon(Icons.add_rounded, size: 17),
                                    label: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Add Product',
                                        maxLines: 1,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF0F172A),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                    ),
                                  ),
                                );
                                return expanded ? Expanded(child: btn) : btn;
                              }

                              if (isCompact) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Products Catalog & Showcase',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Manage your products & SaaS offerings for AI marketing campaigns and publish product showcase updates to Google.',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        color: textSecondary,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        buildAiSuggestBtn(expanded: true),
                                        const SizedBox(width: 8),
                                        buildAddProductBtn(expanded: true),
                                      ],
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Products Catalog & Showcase',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 17,
                                            color: textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Manage your products & SaaS offerings for AI marketing campaigns and publish product showcase updates to Google.',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            color: textSecondary,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      buildAiSuggestBtn(),
                                      const SizedBox(width: 8),
                                      buildAddProductBtn(),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Section Title: Products List
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF312E81).withValues(alpha: 0.5) : const Color(0xFFEEF2FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.shopping_bag_rounded, color: Color(0xFF4F46E5), size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ALL PRODUCTS (${productsState.products.length})',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: textSecondary,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                              if (productsState.isLoading)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                            ],
                          ),
                        ),

                        // Products Content (Loading / Empty / Cards Grid)
                        if (productsState.isLoading && productsState.products.isEmpty)
                          _buildLoadingSkeleton(isDark, cardBgColor, borderColor)
                        else if (productsState.products.isEmpty)
                          _buildEmptyState(context, ref, isDark, cardBgColor, borderColor, textPrimary, textSecondary)
                        else
                          _buildProductsGrid(
                            context,
                            ref,
                            productsState.products,
                            productsState.syncingProductId,
                            isDark,
                            cardBgColor,
                            borderColor,
                            textPrimary,
                            textSecondary,
                          ),

                        const SizedBox(height: 24),

                        // Scale Your Catalog Promo Banner
                        _buildScaleCatalogCard(
                          context,
                          ref,
                          activeLocation?.website ?? '',
                          isDark,
                          cardBgColor,
                          borderColor,
                          textPrimary,
                          textSecondary,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsGrid(
    BuildContext context,
    WidgetRef ref,
    List<GmbProduct> products,
    String? syncingProductId,
    bool isDark,
    Color cardBgColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);

        if (crossAxisCount == 1) {
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, idx) {
              return _buildProductCard(
                context,
                ref,
                products[idx],
                syncingProductId == products[idx].id,
                isDark,
                cardBgColor,
                borderColor,
                textPrimary,
                textSecondary,
              );
            },
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 380,
          ),
          itemCount: products.length,
          itemBuilder: (context, idx) {
            return _buildProductCard(
              context,
              ref,
              products[idx],
              syncingProductId == products[idx].id,
              isDark,
              cardBgColor,
              borderColor,
              textPrimary,
              textSecondary,
            );
          },
        );
      },
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    WidgetRef ref,
    GmbProduct product,
    bool isSyncing,
    bool isDark,
    Color cardBgColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final hasImage = product.imageUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Aspect Ratio Image Header with Badge
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: hasImage
                      ? Image.network(
                          product.imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildImageFallback(isDark, borderColor),
                        )
                      : _buildImageFallback(isDark, borderColor),
                ),
                // Sync status badge (Top Right)
                Positioned(
                  top: 10,
                  right: 10,
                  child: product.isSyncedToGmb
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 13, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'Live on GMB',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Dashboard Only',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                ),
                if (product.isSpecial)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 12, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(
                            'Special',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  product.category,
                  style: GoogleFonts.plusJakartaSans(
                    color: textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (product.price.isNotEmpty)
                      Text(
                        '\$${product.price}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    if (product.discountedPrice.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '\$${product.discountedPrice}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Card Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              children: [
                if (!product.isSyncedToGmb) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: OutlinedButton.icon(
                      onPressed: isSyncing
                          ? null
                          : () async {
                              final success = await ref
                                  .read(productsProvider.notifier)
                                  .syncProductToLive(product.id);
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Product published live to Google!')),
                                );
                              }
                            },
                      icon: isSyncing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.public_rounded, size: 15, color: Color(0xFF7C3AED)),
                      label: Text(
                        isSyncing ? 'Publishing...' : 'Post Showcase Update',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: const Color(0xFF7C3AED),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF581C87).withValues(alpha: 0.2)
                            : const Color(0xFFF5F3FF),
                        side: const BorderSide(color: Color(0xFFDDD6FE)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton.icon(
                          onPressed: () => _openEditProductDialog(context, ref, product),
                          icon: Icon(Icons.edit_outlined, size: 14, color: textPrimary),
                          label: Text(
                            'Edit',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              color: textPrimary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmDeleteProduct(context, ref, product),
                          icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                          label: Text(
                            'Delete',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isDark
                                ? const Color(0xFF7F1D1D).withValues(alpha: 0.15)
                                : const Color(0xFFFEF2F2),
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF991B1B).withValues(alpha: 0.3)
                                  : const Color(0xFFFECACA),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageFallback(bool isDark, Color borderColor) {
    return Container(
      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 36, color: Colors.grey.withValues(alpha: 0.7)),
            const SizedBox(height: 4),
            Text(
              'SocialHive Product',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    Color cardBgColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF312E81).withValues(alpha: 0.3) : const Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_shopping_cart_rounded, color: Color(0xFF4F46E5), size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'No products yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your SaaS offerings & products to help customers discover and purchase from your Google My Business listing.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => _openAddProductDialog(context, ref),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(
              'Add your first product',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark, Color cardBgColor, Color borderColor) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }

  Widget _buildScaleCatalogCard(
    BuildContext context,
    WidgetRef ref,
    String defaultUrl,
    bool isDark,
    Color cardBgColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF312E81).withValues(alpha: 0.4), const Color(0xFF1E1B4B).withValues(alpha: 0.6)]
              : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.rocket_launch_rounded, color: Color(0xFF4F46E5), size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            'Scale Your Product Catalog',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bundle popular SaaS packages & products and publish to Google Search & Maps to increase customer conversions.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: textSecondary,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () => _openAIAnalyzerDialog(context, ref, defaultUrl),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              icon: const Icon(Icons.auto_awesome_rounded, size: 15),
              label: Text(
                'AI Product Bundler & Scanner',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
