import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../data/models/business_profile.dart';
import '../../../data/repositories/backend_business_repository.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/gmbapi_repository.dart';

class ActiveLocationState {
  final bool isLoading;
  final BusinessProfile? activeLocation;
  final List<BusinessProfile> availableLocations;
  final String? errorMessage;

  const ActiveLocationState({
    this.isLoading = false,
    this.activeLocation,
    this.availableLocations = const [],
    this.errorMessage,
  });

  ActiveLocationState copyWith({
    bool? isLoading,
    BusinessProfile? activeLocation,
    List<BusinessProfile>? availableLocations,
    String? errorMessage,
  }) {
    return ActiveLocationState(
      isLoading: isLoading ?? this.isLoading,
      activeLocation: activeLocation ?? this.activeLocation,
      availableLocations: availableLocations ?? this.availableLocations,
      errorMessage: errorMessage,
    );
  }
}

class ActiveLocationNotifier extends StateNotifier<ActiveLocationState> {
  ActiveLocationNotifier(this._businessRepository, [this._gmbapiRepository])
      : super(const ActiveLocationState()) {
    loadLocations();
  }

  final BusinessRepository _businessRepository;
  final GmbapiRepository? _gmbapiRepository;
  static const _activeLocationKey = 'active_gmb_location_id';
  static const _storage = FlutterSecureStorage();

  Future<void> loadLocations() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final locations =
          await _businessRepository.getAssociatedBusinesses('current_user');

      if (locations.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          availableLocations: [],
          activeLocation: null,
        );
        return;
      }

      // Check saved active location
      final savedId = await _storage.read(key: _activeLocationKey);
      BusinessProfile? active;
      if (savedId != null && savedId.isNotEmpty) {
        active = locations.firstWhere(
          (loc) => loc.id == savedId,
          orElse: () => locations.first,
        );
      } else {
        active = locations.first;
      }

      // Save initial selection if not set
      if (savedId != active.id) {
        await _storage.write(key: _activeLocationKey, value: active.id);
      }

      if (_gmbapiRepository != null && active.id.isNotEmpty) {
        try {
          await _gmbapiRepository.selectLocation(active.id);
        } catch (_) {}
      }

      state = state.copyWith(
        isLoading: false,
        availableLocations: locations,
        activeLocation: active,
      );
    } catch (e) {
      debugPrint('❌ Failed to load GMB locations: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load business locations.',
      );
    }
  }

  Future<void> selectLocation(BusinessProfile location) async {
    try {
      await _storage.write(key: _activeLocationKey, value: location.id);
      state = state.copyWith(activeLocation: location);
      debugPrint('✅ Active GMB Location set to: ${location.name} (${location.id})');

      if (_gmbapiRepository != null) {
        try {
          await _gmbapiRepository.selectLocation(location.id);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('❌ Failed to set active location: $e');
    }
  }

  Future<void> refresh() async {
    await loadLocations();
  }
}

final activeLocationProvider =
    StateNotifierProvider<ActiveLocationNotifier, ActiveLocationState>((ref) {
  final repo = BackendBusinessRepository();
  final gmbapiRepo = ref.watch(gmbapiRepositoryProvider);
  return ActiveLocationNotifier(repo, gmbapiRepo);
});
