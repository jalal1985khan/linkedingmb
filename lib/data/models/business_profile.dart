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
    );
  }
}
