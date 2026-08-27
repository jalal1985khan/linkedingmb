class GmbProduct {
  final String id;
  final String name;
  final String category;
  final String price;
  final String discountedPrice;
  final String description;
  final String imageUrl;
  final String landingPageUrl;
  final bool isSpecial;
  final String locationId;
  final bool isSyncedToGmb;
  final String? gmbName;
  final String? syncError;

  const GmbProduct({
    required this.id,
    required this.name,
    this.category = 'General',
    this.price = '',
    this.discountedPrice = '',
    this.description = '',
    this.imageUrl = '',
    this.landingPageUrl = '',
    this.isSpecial = false,
    this.locationId = '',
    this.isSyncedToGmb = false,
    this.gmbName,
    this.syncError,
  });

  factory GmbProduct.fromJson(Map<String, dynamic> json) {
    return GmbProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Product',
      category: json['category']?.toString() ?? 'General',
      price: json['price'] != null ? json['price'].toString() : '',
      discountedPrice: json['discountedPrice'] != null ? json['discountedPrice'].toString() : '',
      description: json['description']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString() ?? '',
      landingPageUrl: json['landingPageUrl']?.toString() ?? json['landing_page_url']?.toString() ?? '',
      isSpecial: json['isSpecial'] == true || json['is_special'] == true,
      locationId: json['location_id']?.toString() ?? '',
      isSyncedToGmb: json['is_synced_to_gmb'] == true || json['isSyncedToGmb'] == true,
      gmbName: json['gmb_name']?.toString(),
      syncError: json['sync_error']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'category': category,
      if (price.isNotEmpty) 'price': price,
      if (discountedPrice.isNotEmpty) 'discountedPrice': discountedPrice,
      if (description.isNotEmpty) 'description': description,
      if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      if (landingPageUrl.isNotEmpty) 'landingPageUrl': landingPageUrl,
      'isSpecial': isSpecial,
      if (locationId.isNotEmpty) 'location_id': locationId,
      'is_synced_to_gmb': isSyncedToGmb,
      if (gmbName != null) 'gmb_name': gmbName,
      if (syncError != null) 'sync_error': syncError,
    };
  }

  GmbProduct copyWith({
    String? id,
    String? name,
    String? category,
    String? price,
    String? discountedPrice,
    String? description,
    String? imageUrl,
    String? landingPageUrl,
    bool? isSpecial,
    String? locationId,
    bool? isSyncedToGmb,
    String? gmbName,
    String? syncError,
  }) {
    return GmbProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      landingPageUrl: landingPageUrl ?? this.landingPageUrl,
      isSpecial: isSpecial ?? this.isSpecial,
      locationId: locationId ?? this.locationId,
      isSyncedToGmb: isSyncedToGmb ?? this.isSyncedToGmb,
      gmbName: gmbName ?? this.gmbName,
      syncError: syncError ?? this.syncError,
    );
  }
}
