import '../models/business_profile.dart';

abstract class BusinessRepository {
  Future<List<BusinessProfile>> getAssociatedBusinesses(String userId);
  Future<BusinessProfile> createBusinessProfile(BusinessProfile profile);
  Future<BusinessProfile> updateBusinessProfile(BusinessProfile profile);
}
