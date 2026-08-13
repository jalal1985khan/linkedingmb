class GMBLocation {
  final String locationId;
  final String title;
  final String category;
  final List<String> additionalCategories;
  final String address;
  final String? websiteUri;
  final String? primaryPhone;

  GMBLocation({
    required this.locationId,
    required this.title,
    required this.category,
    required this.additionalCategories,
    required this.address,
    this.websiteUri,
    this.primaryPhone,
  });

  factory GMBLocation.fromJson(Map<String, dynamic> json) {
    return GMBLocation(
      locationId: json['location_id'] ?? '',
      title: json['title'] ?? json['displayName'] ?? '',
      category: json['category'] ?? 'Business Services',
      additionalCategories: List<String>.from(json['additional_categories'] ?? []),
      address: json['address'] ?? '',
      websiteUri: json['websiteUri'],
      primaryPhone: json['primaryPhone'],
    );
  }
}
