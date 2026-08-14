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
  final String description;
  final String city;
  final String postal;
  final String state;
  final String countryCode;
  final String storeCode;
  final bool isManual;

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
      description: description ?? this.description,
      city: city ?? this.city,
      postal: postal ?? this.postal,
      state: state ?? this.state,
      countryCode: countryCode ?? this.countryCode,
      storeCode: storeCode ?? this.storeCode,
      isManual: isManual ?? this.isManual,
    );
  }

  bool get isManualLocation => isManual == true;
}
