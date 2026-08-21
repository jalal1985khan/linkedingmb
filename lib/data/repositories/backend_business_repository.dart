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

    try {
      final token = await _secureStorage.read(key: _tokenStorageKey);
      if (token != null && token.isNotEmpty) {
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };

        if (profile.isManualLocation) {
          final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/manual-locations/update');
          await _httpClient.post(
            uri,
            headers: headers,
            body: jsonEncode({
              'location_name': profile.id,
              'title': profile.name,
              'address': profile.address,
              'description': profile.descriptionText,
              'website': profile.website,
              'phone': profile.phone,
            }),
          );
        } else {
          final locIdParam = Uri.encodeComponent(profile.id);
          final uri = Uri.parse(
              '${ApiConfig.baseUrl}/api/gmb/profile?location_id=$locIdParam&update_mask=title,description,websiteUri,phoneNumbers');
          final updatePayload = {
            'title': profile.name,
            'description': profile.descriptionText,
            'websiteUri': profile.website,
            'phoneNumbers': {
              'primaryPhone': profile.phone,
            },
          };
          await _httpClient.patch(
            uri,
            headers: headers,
            body: jsonEncode(updatePayload),
          );
        }
      }
    } catch (_) {}

    return profile;
  }

  @override
  Future<BusinessProfile?> fetchLocationProfile(String locationId) async {
    try {
      final token = await _secureStorage.read(key: _tokenStorageKey);
      if (token == null || token.isEmpty) return null;

      final locIdParam = Uri.encodeComponent(locationId);
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/profile?location_id=$locIdParam');

      final response = await _httpClient.get(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final profileData = decoded['profile'] ?? decoded['location'] ?? decoded['data'] ?? decoded;
        if (profileData is Map<String, dynamic>) {
          return _mapLocationToProfile(profileData);
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<String> enhanceDescription({
    required String businessName,
    required String category,
    required String currentDescription,
  }) async {
    try {
      final token = await _secureStorage.read(key: _tokenStorageKey);
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token missing.');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/profile/enhance');
      final response = await _httpClient.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'business_name': businessName,
          'category': category,
          'current_description': currentDescription,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return _string(decoded['enhanced_description'] ?? decoded['description'] ?? decoded['data']);
      } else {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(decoded?['detail'] ?? 'Failed to enhance description');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> searchCategories(String query) async {
    try {
      final token = await _secureStorage.read(key: _tokenStorageKey);
      if (token == null || token.isEmpty) return [];

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/categories?search=${Uri.encodeComponent(query)}');
      final response = await _httpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['categories'] is List) {
          return List<Map<String, dynamic>>.from(decoded['categories']);
        }
      }
    } catch (_) {}
    return [];
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

    double ratingVal = 0.0;
    final rawRating = location['averageRating'] ?? location['rating'] ?? location['average_rating'] ?? location['overall_rating'];
    if (rawRating != null) {
      if (rawRating is num) {
        ratingVal = rawRating.toDouble();
      } else if (rawRating is String) {
        ratingVal = double.tryParse(rawRating) ?? 0.0;
      }
    }

    final description = _extractDescription(location);
    final storeCode = _string(location['storeCode']);
    final isManual = location['is_manual'] == true || location['isManual'] == true;

    String cityStr = '';
    String postalStr = '';
    String stateStr = '';
    String countryStr = 'US';

    final storefront = location['storefrontAddress'];
    if (storefront is Map<String, dynamic>) {
      cityStr = _string(storefront['locality']);
      postalStr = _string(storefront['postalCode']);
      stateStr = _string(storefront['administrativeArea']);
      countryStr = _string(storefront['regionCode']).isNotEmpty ? _string(storefront['regionCode']) : 'US';
    }

    final bookingUrl = _string(location['bookingUri']).isNotEmpty
        ? _string(location['bookingUri'])
        : _string(location['booking_url']);

    List<String> addCats = [];
    final catsObj = location['categories'];
    if (catsObj is Map<String, dynamic> && catsObj['additionalCategories'] is List) {
      for (final item in catsObj['additionalCategories']) {
        if (item is Map<String, dynamic>) {
          final display = _string(item['displayName']).isNotEmpty ? _string(item['displayName']) : _string(item['name']);
          if (display.isNotEmpty) addCats.add(display);
        } else if (item is String && item.isNotEmpty) {
          addCats.add(item);
        }
      }
    }

    String logoStr = '';
    String coverStr = '';
    List<String> photosList = [];
    final mediaList = location['media'];
    if (mediaList is List) {
      for (final item in mediaList) {
        if (item is Map<String, dynamic>) {
          final url = _string(item['googleUrl']).isNotEmpty ? _string(item['googleUrl']) : _string(item['sourceUrl']);
          final cat = _string(item['mediaFormat']).isNotEmpty ? _string(item['mediaFormat']) : _string(item['category']);
          if (cat.toUpperCase() == 'LOGO') {
            logoStr = url;
          } else if (cat.toUpperCase() == 'COVER') {
            coverStr = url;
          } else if (url.isNotEmpty) {
            photosList.add(url);
          }
        }
      }
    }

    List<String> servicesList = [];
    final serviceItemsRaw = location['serviceItems'] ?? location['service_items'] ?? location['services'];
    if (serviceItemsRaw is List) {
      for (final item in serviceItemsRaw) {
        if (item is Map<String, dynamic>) {
          final freeForm = item['freeFormServiceItem'];
          if (freeForm is Map<String, dynamic>) {
            final label = freeForm['label'];
            if (label is Map<String, dynamic>) {
              final name = _string(label['displayName']);
              if (name.isNotEmpty) servicesList.add(name);
            }
          }
          final struct = item['structuredServiceItem'];
          if (struct is Map<String, dynamic>) {
            final name = _string(struct['displayName']);
            if (name.isNotEmpty) servicesList.add(name);
          }
          final directName = _string(item['displayName']).isNotEmpty ? _string(item['displayName']) : _string(item['name']);
          if (directName.isNotEmpty && !servicesList.contains(directName)) servicesList.add(directName);
        } else if (item is String && item.isNotEmpty) {
          servicesList.add(item);
        }
      }
    }

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
      rating: ratingVal,
      description: description,
      city: cityStr,
      postal: postalStr,
      state: stateStr,
      countryCode: countryStr,
      storeCode: storeCode,
      isManual: isManual,
      additionalCategories: addCats,
      bookingUrl: bookingUrl,
      logoUrl: logoStr,
      coverPhotoUrl: coverStr,
      additionalPhotos: photosList,
      services: servicesList,
    );
  }

  String _primaryCategory(Map<String, dynamic> location) {
    final categories = location['categories'];
    if (categories is Map<String, dynamic>) {
      final primary = categories['primaryCategory'];
      if (primary is Map<String, dynamic>) {
        final display = _string(primary['displayName']);
        if (display.isNotEmpty) return display;
        final name = _string(primary['name']);
        if (name.isNotEmpty) return name;
      }
    }
    final rawCat = _string(location['category']);
    if (rawCat.isNotEmpty) return rawCat;
    return '';
  }

  String _locationSummary(Map<String, dynamic> location) {
    final storefront = location['storefrontAddress'];
    if (storefront is Map<String, dynamic>) {
      final locality = _string(storefront['locality']);
      final adminArea = _string(storefront['administrativeArea']);
      if (locality.isNotEmpty && adminArea.isNotEmpty) {
        return '$locality, $adminArea';
      }
      if (locality.isNotEmpty) return locality;
    }
    return '';
  }

  String _addressSummary(Map<String, dynamic> location) {
    final direct = _string(location['address']);
    if (direct.isNotEmpty) return direct;

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

  String _extractDescription(Map<String, dynamic> location) {
    if (location['description'] != null && _string(location['description']).isNotEmpty) {
      return _string(location['description']);
    }
    final profile = location['profile'];
    if (profile is Map<String, dynamic> && profile['description'] != null) {
      return _string(profile['description']);
    }
    if (location['profile_description'] != null) {
      return _string(location['profile_description']);
    }
    return '';
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

  String _string(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  // ── Product Management Methods ───────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getProducts(String locationId) async {
    final token = await _secureStorage.read(key: _tokenStorageKey);
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/gmb/products?location_id=${Uri.encodeComponent(locationId)}',
    );
    final response = await _httpClient.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load products (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (decoded['products'] ?? []) as List<dynamic>;
    return list.whereType<Map<String, dynamic>>().toList();
  }

  Future<bool> addProduct(String locationId, Map<String, dynamic> productData) async {
    final token = await _secureStorage.read(key: _tokenStorageKey);
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/gmb/products?location_id=${Uri.encodeComponent(locationId)}',
    );
    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(productData),
    );

    return response.statusCode == 200;
  }

  Future<bool> deleteProduct(String locationId, String productId) async {
    final token = await _secureStorage.read(key: _tokenStorageKey);
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/gmb/products/$productId?location_id=${Uri.encodeComponent(locationId)}',
    );
    final response = await _httpClient.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }

  Future<List<Map<String, dynamic>>> analyzeWebsiteProducts(String locationId, {String? websiteUrl}) async {
    final token = await _secureStorage.read(key: _tokenStorageKey);
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/gmb/products/analyze-website?location_id=${Uri.encodeComponent(locationId)}',
    );
    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (websiteUrl != null && websiteUrl.isNotEmpty) 'website_url': websiteUrl,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to analyze website for products');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (decoded['suggested_products'] ?? []) as List<dynamic>;
    return list.whereType<Map<String, dynamic>>().toList();
  }
}
