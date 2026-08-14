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
    this.additionalCategories = const [],
    this.bookingUrl = '',
    this.logoUrl = '',
    this.coverPhotoUrl = '',
    this.additionalPhotos = const [],
    this.services = const [],
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
  final List<String>? additionalCategories;
  final String? bookingUrl;
  final String? logoUrl;
  final String? coverPhotoUrl;
  final List<String>? additionalPhotos;
  final List<String>? services;

  bool get isManualLocation => isManual == true;
  String get descriptionText => description ?? '';
  String get cityText => city ?? '';
  String get postalText => postal ?? '';
  String get stateText => state ?? '';
  String get countryCodeText => countryCode ?? 'US';
  String get storeCodeText => storeCode ?? '';
  List<String> get additionalCategoriesList => additionalCategories ?? const <String>[];
  String get bookingUrlText => bookingUrl ?? '';
  String get logoUrlText => logoUrl ?? '';
  String get coverPhotoUrlText => coverPhotoUrl ?? '';
  List<String> get additionalPhotosList => additionalPhotos ?? const <String>[];
  List<String> get servicesList => services ?? const <String>[];

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
    List<String>? additionalCategories,
    String? bookingUrl,
    String? logoUrl,
    String? coverPhotoUrl,
    List<String>? additionalPhotos,
    List<String>? services,
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
      additionalCategories: additionalCategories ?? additionalCategoriesList,
      bookingUrl: bookingUrl ?? bookingUrlText,
      logoUrl: logoUrl ?? logoUrlText,
      coverPhotoUrl: coverPhotoUrl ?? coverPhotoUrlText,
      additionalPhotos: additionalPhotos ?? additionalPhotosList,
      services: services ?? servicesList,
    );
  }
}
