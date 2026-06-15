import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/business_profile.dart';
import 'business_repository.dart';

class BackendBusinessRepository implements BusinessRepository {
  BackendBusinessRepository({
    http.Client? httpClient,
    FlutterSecureStorage? secureStorage,
  })  : _httpClient = httpClient ?? http.Client(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _tokenStorageKey = 'auth_access_token';
  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;

  // Local fallback for onboarding-created businesses until manual location APIs are wired.
  final List<BusinessProfile> _localProfiles = <BusinessProfile>[];

  @override
  Future<List<BusinessProfile>> getAssociatedBusinesses(String userId) async {
    final token = await _secureStorage.read(key: _tokenStorageKey);
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token missing. Please login again.');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/locations');
    final response = await _httpClient.get(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch businesses (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final locationsRaw = (decoded['locations'] as List<dynamic>? ?? <dynamic>[]);
    final backendProfiles = locationsRaw
        .whereType<Map<String, dynamic>>()
        .map(_mapLocationToProfile)
        .toList();

    // Merge backend and local profiles (local first if same id).
    final byId = <String, BusinessProfile>{
      for (final profile in backendProfiles) profile.id: profile,
    };
    for (final local in _localProfiles) {
      byId[local.id] = local;
    }
    return byId.values.toList();
  }

  @override
  Future<BusinessProfile> createBusinessProfile(BusinessProfile profile) async {
    final created = profile.copyWith(
      id: profile.id == 'temp'
          ? 'local_${DateTime.now().millisecondsSinceEpoch}'
          : profile.id,
    );
    _localProfiles.removeWhere((item) => item.id == created.id);
    _localProfiles.add(created);
    return created;
  }

  @override
  Future<BusinessProfile> updateBusinessProfile(BusinessProfile profile) async {
    _localProfiles.removeWhere((item) => item.id == profile.id);
    _localProfiles.add(profile);
    return profile;
  }

  BusinessProfile _mapLocationToProfile(Map<String, dynamic> location) {
    final id = _string(location['name']).isNotEmpty
        ? _string(location['name'])
        : _string(location['_id']);

    final title = _string(location['title']);
    final category = _primaryCategory(location);
    final locationSummary = _locationSummary(location);
    final address = _addressSummary(location);
    final phone = _primaryPhone(location);
    final hours = _hoursSummary(location);
    final website = _string(location['websiteUri']).isNotEmpty
        ? _string(location['websiteUri'])
        : _string(location['website']);

    return BusinessProfile(
      id: id.isNotEmpty ? id : 'unknown_${DateTime.now().millisecondsSinceEpoch}',
      name: title.isNotEmpty ? title : 'Untitled Business',
      category: category.isNotEmpty ? category : 'Business',
      location: locationSummary.isNotEmpty ? locationSummary : 'Unknown area',
      address: address.isNotEmpty ? address : 'Address not available',
      phone: phone.isNotEmpty ? phone : 'N/A',
      hoursSummary: hours.isNotEmpty ? hours : 'Hours not available',
      website: website,
      targetAudience: 'Local customers',
      brandTone: 'Professional',
      postingFrequency: 4,
    );
  }

  String _primaryCategory(Map<String, dynamic> location) {
    final categories = location['categories'];
    if (categories is Map<String, dynamic>) {
      final primary = categories['primaryCategory'];
      if (primary is Map<String, dynamic>) {
        final display = _string(primary['displayName']);
        if (display.isNotEmpty) return display;
      }
    }
    return '';
  }

  String _locationSummary(Map<String, dynamic> location) {
    final storefront = location['storefrontAddress'];
    if (storefront is Map<String, dynamic>) {
      final locality = _string(storefront['locality']);
      final adminArea = _string(storefront['administrativeArea']);
      final region = [locality, adminArea].where((item) => item.isNotEmpty).join(', ');
      if (region.isNotEmpty) return region;
    }
    return _string(location['location_name']);
  }

  String _addressSummary(Map<String, dynamic> location) {
    final directAddress = _string(location['address']);
    if (directAddress.isNotEmpty) return directAddress;

    final storefront = location['storefrontAddress'];
    if (storefront is! Map<String, dynamic>) return '';

    final lines = (storefront['addressLines'] as List<dynamic>? ?? <dynamic>[])
        .map((line) => line.toString().trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final locality = _string(storefront['locality']);
    final postal = _string(storefront['postalCode']);
    final adminArea = _string(storefront['administrativeArea']);
    final country = _string(storefront['regionCode']);
    final parts = <String>[
      if (lines.isNotEmpty) lines.join(', '),
      if (locality.isNotEmpty) locality,
      if (adminArea.isNotEmpty) adminArea,
      if (postal.isNotEmpty) postal,
      if (country.isNotEmpty) country,
    ];
    return parts.join(', ');
  }

  String _primaryPhone(Map<String, dynamic> location) {
    final phoneNumbers = location['phoneNumbers'];
    if (phoneNumbers is Map<String, dynamic>) {
      final primary = _string(phoneNumbers['primaryPhone']);
      if (primary.isNotEmpty) return primary;
    }
    return '';
  }

  String _hoursSummary(Map<String, dynamic> location) {
    final direct = _string(location['hoursSummary']);
    if (direct.isNotEmpty) return direct;

    final regularHours = location['regularHours'];
    if (regularHours is Map<String, dynamic>) {
      final periods = regularHours['periods'];
      if (periods is List && periods.isNotEmpty) {
        return 'Open hours available';
      }
    }
    return '';
  }

  String _string(dynamic value) => (value ?? '').toString().trim();
}
