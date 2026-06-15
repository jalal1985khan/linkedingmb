import '../models/business_profile.dart';
import '../repositories/business_repository.dart';

class MockBusinessRepository implements BusinessRepository {
  final List<BusinessProfile> _profiles = [
    BusinessProfile(
      id: 'b_001',
      name: 'Smart Dental Studio',
      category: 'Dental Clinic',
      location: 'Bangalore',
      address: 'Niz Banskandi Part 1, Assam 788101',
      phone: '096787 48791',
      hoursSummary: 'Open • Closes 5 am Tue',
      website: 'https://smartdental.example',
      targetAudience: 'Families and working professionals nearby',
      brandTone: 'Helpful and trustworthy',
      postingFrequency: 4,
    ),
    BusinessProfile(
      id: 'b_002',
      name: 'Urban Brew Cafe',
      category: 'Cafe',
      location: 'Indiranagar, Bangalore',
      address: '12 CMH Road, Indiranagar, Bangalore 560038',
      phone: '098450 33219',
      hoursSummary: 'Open • Closes 11 pm',
      website: 'https://urbanbrew.example',
      targetAudience: 'Students, freelancers, and local office teams',
      brandTone: 'Friendly and modern',
      postingFrequency: 5,
    ),
  ];

  @override
  Future<List<BusinessProfile>> getAssociatedBusinesses(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (userId == 'new_user') {
      return [];
    }
    return _profiles;
  }

  @override
  Future<BusinessProfile> createBusinessProfile(BusinessProfile profile) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final created = BusinessProfile(
      id: 'b_new_${DateTime.now().millisecondsSinceEpoch}',
      name: profile.name,
      category: profile.category,
      location: profile.location,
      address: profile.address,
      phone: profile.phone,
      hoursSummary: profile.hoursSummary,
      website: profile.website,
      targetAudience: profile.targetAudience,
      brandTone: profile.brandTone,
      postingFrequency: profile.postingFrequency,
    );
    _profiles.add(created);
    return created;
  }

  @override
  Future<BusinessProfile> updateBusinessProfile(BusinessProfile profile) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final index = _profiles.indexWhere((item) => item.id == profile.id);
    if (index >= 0) {
      _profiles[index] = profile;
      return profile;
    }
    _profiles.add(profile);
    return profile;
  }
}
