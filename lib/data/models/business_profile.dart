class BusinessProfile {
  const BusinessProfile({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.address,
    required this.phone,
    required this.hoursSummary,
    required this.website,
    required this.targetAudience,
    required this.brandTone,
    required this.postingFrequency,
    this.rating = 0.0,
    this.description = '',
    this.city = '',
    this.postal = '',
    this.state = '',
    this.countryCode = 'US',
    this.storeCode = '',
    this.isManual = false,
  });

  final String id;
  final String name;
  final String category;
  final String location;
  final String address;
  final String phone;
  final String hoursSummary;
  final String website;
  final String targetAudience;
  final String brandTone;
  final int postingFrequency;
  final double rating;
  final String? description;
  final String? city;
  final String? postal;
  final String? state;
  final String? countryCode;
  final String? storeCode;
  final bool? isManual;

  bool get isManualLocation => isManual == true;
  String get descriptionText => description ?? '';
  String get cityText => city ?? '';
  String get postalText => postal ?? '';
  String get stateText => state ?? '';
  String get countryCodeText => countryCode ?? 'US';
  String get storeCodeText => storeCode ?? '';

  BusinessProfile copyWith({
    String? id,
    String? name,
    String? category,
    String? location,
    String? address,
    String? phone,
    String? hoursSummary,
    String? website,
    String? targetAudience,
    String? brandTone,
    int? postingFrequency,
    double? rating,
    String? description,
    String? city,
    String? postal,
    String? state,
    String? countryCode,
    String? storeCode,
    bool? isManual,
  }) {
    return BusinessProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      location: location ?? this.location,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      hoursSummary: hoursSummary ?? this.hoursSummary,
      website: website ?? this.website,
      targetAudience: targetAudience ?? this.targetAudience,
      brandTone: brandTone ?? this.brandTone,
      postingFrequency: postingFrequency ?? this.postingFrequency,
      rating: rating ?? this.rating,
      description: description ?? descriptionText,
      city: city ?? cityText,
      postal: postal ?? postalText,
      state: state ?? stateText,
      countryCode: countryCode ?? countryCodeText,
      storeCode: storeCode ?? storeCodeText,
      isManual: isManual ?? isManualLocation,
    );
  }
}
