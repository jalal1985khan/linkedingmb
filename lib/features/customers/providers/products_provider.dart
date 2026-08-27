import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/gmb_product.dart';
import '../../../data/repositories/backend_business_repository.dart';
import '../../business_flow/providers/active_location_provider.dart';

class ProductsState {
  final bool isLoading;
  final List<GmbProduct> products;
  final String? syncingProductId;
  final String? errorMessage;
  final bool isSubmitting;
  final bool isAnalyzing;
  final List<GmbProduct> suggestedProducts;

  const ProductsState({
    this.isLoading = false,
    this.products = const [],
    this.syncingProductId,
    this.errorMessage,
    this.isSubmitting = false,
    this.isAnalyzing = false,
    this.suggestedProducts = const [],
  });

  ProductsState copyWith({
    bool? isLoading,
    List<GmbProduct>? products,
    String? syncingProductId,
    bool clearSyncingProduct = false,
    String? errorMessage,
    bool? isSubmitting,
    bool? isAnalyzing,
    List<GmbProduct>? suggestedProducts,
  }) {
    return ProductsState(
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      syncingProductId: clearSyncingProduct ? null : (syncingProductId ?? this.syncingProductId),
      errorMessage: errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      suggestedProducts: suggestedProducts ?? this.suggestedProducts,
    );
  }
}

class ProductsNotifier extends StateNotifier<ProductsState> {
  final BackendBusinessRepository _repository;
  final String _locationId;

  ProductsNotifier(this._repository, this._locationId) : super(const ProductsState()) {
    if (_locationId.isNotEmpty) {
      loadProducts();
    }
  }

  Future<void> loadProducts() async {
    if (_locationId.isEmpty) return;
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final rawList = await _repository.getProducts(_locationId);
      final list = rawList.map((item) => GmbProduct.fromJson(item)).toList();
      state = state.copyWith(isLoading: false, products: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> addProduct(GmbProduct product) async {
    if (_locationId.isEmpty) return false;
    try {
      state = state.copyWith(isSubmitting: true, errorMessage: null);
      final payload = product.toJson();
      final success = await _repository.addProduct(_locationId, payload);
      if (success) {
        await loadProducts();
        state = state.copyWith(isSubmitting: false);
        return true;
      }
      state = state.copyWith(isSubmitting: false, errorMessage: 'Failed to add product');
      return false;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateProduct(GmbProduct product) async {
    if (_locationId.isEmpty || product.id.isEmpty) return false;
    try {
      state = state.copyWith(isSubmitting: true, errorMessage: null);
      final payload = product.toJson();
      final success = await _repository.updateProduct(_locationId, product.id, payload);
      if (success) {
        await loadProducts();
        state = state.copyWith(isSubmitting: false);
        return true;
      }
      state = state.copyWith(isSubmitting: false, errorMessage: 'Failed to update product');
      return false;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    if (_locationId.isEmpty || productId.isEmpty) return false;
    try {
      final success = await _repository.deleteProduct(_locationId, productId);
      if (success) {
        state = state.copyWith(
          products: state.products.where((p) => p.id != productId).toList(),
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> syncProductToLive(String productId) async {
    if (_locationId.isEmpty || productId.isEmpty) return false;
    try {
      state = state.copyWith(syncingProductId: productId, errorMessage: null);
      final success = await _repository.syncProduct(_locationId, productId);
      if (success) {
        state = state.copyWith(
          products: state.products
              .map((p) => p.id == productId ? p.copyWith(isSyncedToGmb: true, syncError: null) : p)
              .toList(),
          clearSyncingProduct: true,
        );
        return true;
      }
      state = state.copyWith(clearSyncingProduct: true, errorMessage: 'Failed to sync product to GMB');
      return false;
    } catch (e) {
      state = state.copyWith(clearSyncingProduct: true, errorMessage: e.toString());
      return false;
    }
  }

  Future<List<GmbProduct>> analyzeWebsite({String? websiteUrl}) async {
    if (_locationId.isEmpty) return [];
    try {
      state = state.copyWith(isAnalyzing: true, errorMessage: null);
      final rawList = await _repository.analyzeWebsiteProducts(_locationId, websiteUrl: websiteUrl);
      final list = rawList.map((item) => GmbProduct.fromJson(item)).toList();
      state = state.copyWith(isAnalyzing: false, suggestedProducts: list);
      return list;
    } catch (e) {
      state = state.copyWith(isAnalyzing: false, errorMessage: e.toString());
      return [];
    }
  }

  Future<int> importSelectedProducts(List<GmbProduct> selectedProducts) async {
    if (_locationId.isEmpty || selectedProducts.isEmpty) return 0;
    int imported = 0;
    state = state.copyWith(isSubmitting: true);
    for (final prod in selectedProducts) {
      try {
        final payload = prod.toJson();
        final success = await _repository.addProduct(_locationId, payload);
        if (success) imported++;
      } catch (_) {}
    }
    await loadProducts();
    state = state.copyWith(isSubmitting: false, suggestedProducts: []);
    return imported;
  }
}

final productsProvider = StateNotifierProvider.autoDispose<ProductsNotifier, ProductsState>((ref) {
  final activeLoc = ref.watch(activeLocationProvider).activeLocation;
  final locationId = activeLoc?.id ?? '';
  final repository = BackendBusinessRepository();
  return ProductsNotifier(repository, locationId);
});
