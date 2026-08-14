import '../models/business_profile.dart';

abstract class BusinessRepository {
  Future<List<BusinessProfile>> getAssociatedBusinesses(String userId);
  Future<BusinessProfile> createBusinessProfile(BusinessProfile profile);
  Future<BusinessProfile> updateBusinessProfile(BusinessProfile profile);
  Future<BusinessProfile?> fetchLocationProfile(String locationId);
  Future<String> enhanceDescription({
    required String businessName,
    required String category,
    required String currentDescription,
  });
}
