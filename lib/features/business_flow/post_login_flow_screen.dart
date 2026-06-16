import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/business_profile.dart';
import '../../data/repositories/gmbapi_repository.dart';
import '../auth/auth_controller.dart';
import '../settings/automation_settings_controller.dart';
import 'business_flow_controller.dart';

enum _FlowStage { selection, onboarding, analyzing, recommendations }

class PostLoginFlowScreen extends ConsumerStatefulWidget {
  const PostLoginFlowScreen({super.key});

  @override
  ConsumerState<PostLoginFlowScreen> createState() => _PostLoginFlowScreenState();
}

class _PostLoginFlowScreenState extends ConsumerState<PostLoginFlowScreen> {
  _FlowStage _stage = _FlowStage.selection;
  BusinessProfile? _onboardingBusiness;
  bool _isBusy = false;
  bool _autoApply = false;
  final Set<String> _selectedRecommendationIds = <String>{};

  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hoursController = TextEditingController();
  final _websiteController = TextEditingController();
  final _audienceController = TextEditingController();
  final _toneController = TextEditingController();
  double _postingFrequency = 4;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _hoursController.dispose();
    _websiteController.dispose();
    _audienceController.dispose();
    _toneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    switch (_stage) {
      case _FlowStage.selection:
        return _buildBusinessSelection(user.id);
      case _FlowStage.onboarding:
        return _buildOnboarding();
      case _FlowStage.analyzing:
        return _buildAnalyzing();
      case _FlowStage.recommendations:
        return _buildRecommendations();
    }
  }

  Widget _buildBusinessSelection(String userId) {
    final locationsState = ref.watch(gmbapiLocationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Business Profile')),
      body: locationsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Could not fetch business profiles: $error'),
          ),
        ),
        data: (locations) {
          if (locations.isEmpty) {
            _stage = _FlowStage.onboarding;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {});
              }
            });
            return const SizedBox.shrink();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'We found ${locations.length} associated profiles via GMB',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              for (final location in locations)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(location['title'] ?? 'Unknown Business'),
                    subtitle: Text('${location['categories']?['primaryCategory']?['displayName'] ?? ''} • ${location['storefrontAddress']?['locality'] ?? ''}'),
                    trailing: _isBusy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () async {
                      if (_isBusy) return;
                      setState(() => _isBusy = true);
                      try {
                        final locationId = location['name']?.toString() ?? '';
                        await ref.read(gmbapiRepositoryProvider).selectLocation(locationId);
                        
                        // Fake a BusinessProfile object for compatibility with downstream
                        final business = BusinessProfile(
                          id: locationId,
                          name: location['title'] ?? 'Selected Business',
                          category: location['categories']?['primaryCategory']?['displayName'] ?? '',
                          location: location['storefrontAddress']?['locality'] ?? '',
                          address: location['storefrontAddress']?['addressLines']?.firstOrNull ?? '',
                          phone: location['phoneNumbers']?['primaryPhone'] ?? '',
                          hoursSummary: '',
                          website: location['websiteUri'] ?? '',
                          targetAudience: '',
                          brandTone: '',
                          postingFrequency: 4,
                        );
                        
                        if (mounted) {
                          ref.read(selectedBusinessProvider.notifier).setBusiness(business);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to select location: $e')));
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isBusy = false);
                        }
                      }
                    },
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => setState(() => _stage = _FlowStage.onboarding),
                icon: const Icon(Icons.add_business_rounded),
                label: const Text('My business is not listed'),
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOnboarding() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Onboarding'),
        leading: IconButton(
          onPressed: () => setState(() => _stage = _FlowStage.selection),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Tell us about your business so AI can personalize your profile and posting strategy.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _inputField(_nameController, 'Business name'),
          _inputField(_categoryController, 'Category (e.g. Dental Clinic, Cafe)'),
          _inputField(_locationController, 'Location / service area'),
          _inputField(_addressController, 'Address'),
          _inputField(_phoneController, 'Phone number'),
          _inputField(_hoursController, 'Hours summary (e.g. Open • Closes 10 pm)'),
          _inputField(_websiteController, 'Website (optional)'),
          _inputField(_audienceController, 'Target audience'),
          _inputField(_toneController, 'Brand tone (friendly/professional/etc)'),
          const SizedBox(height: 10),
          Text(
            'Posting frequency: ${_postingFrequency.round()} posts/week',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _postingFrequency,
            min: 1,
            max: 14,
            divisions: 13,
            label: _postingFrequency.round().toString(),
            onChanged: (value) => setState(() => _postingFrequency = value),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _isBusy ? null : _submitOnboarding,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _isBusy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Analyze with AI'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzing() {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Analysis')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 18),
            Text(
              'AI is analyzing your business profile, category trends, and local posting strategy...',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    final business = _onboardingBusiness;
    if (business == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final recommendationState = ref.watch(aiRecommendationsProvider(business.id));
    return Scaffold(
      appBar: AppBar(title: const Text('AI Recommendations')),
      body: recommendationState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Failed to load recommendations: $error')),
        data: (recommendations) {
          if (_selectedRecommendationIds.isEmpty) {
            _selectedRecommendationIds.addAll(recommendations.map((item) => item.id));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Choose what you want AI to apply now. You can switch on full auto-apply as well.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable auto-apply'),
                subtitle: const Text('AI will apply selected recommendation categories automatically'),
                value: _autoApply,
                onChanged: (value) => setState(() => _autoApply = value),
              ),
              const SizedBox(height: 8),
              for (final recommendation in recommendations)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: CheckboxListTile(
                    value: _selectedRecommendationIds.contains(recommendation.id),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedRecommendationIds.add(recommendation.id);
                        } else {
                          _selectedRecommendationIds.remove(recommendation.id);
                        }
                      });
                    },
                    title: Text(recommendation.title),
                    subtitle: Text('${recommendation.description}\nImpact: ${recommendation.impact}'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: _isBusy ? null : _applyRecommendations,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: _isBusy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Apply & Continue to Dashboard'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }

  Future<void> _submitOnboarding() async {
    if (_nameController.text.trim().isEmpty ||
        _categoryController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _hoursController.text.trim().isEmpty ||
        _audienceController.text.trim().isEmpty ||
        _toneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required business details.')),
      );
      return;
    }

    setState(() => _isBusy = true);
    final repository = ref.read(businessRepositoryProvider);
    final aiRepository = ref.read(aiRepositoryProvider);

    try {
      final createdBusiness = await repository.createBusinessProfile(
        BusinessProfile(
          id: 'temp',
          name: _nameController.text.trim(),
          category: _categoryController.text.trim(),
          location: _locationController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
          hoursSummary: _hoursController.text.trim(),
          website: _websiteController.text.trim(),
          targetAudience: _audienceController.text.trim(),
          brandTone: _toneController.text.trim(),
          postingFrequency: _postingFrequency.round(),
        ),
      );
      _onboardingBusiness = createdBusiness;
      setState(() {
        _stage = _FlowStage.analyzing;
      });

      await aiRepository.analyzeBusiness(createdBusiness);

      if (!mounted) {
        return;
      }
      setState(() {
        _stage = _FlowStage.recommendations;
      });
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _applyRecommendations() async {
    final business = _onboardingBusiness;
    if (business == null) {
      return;
    }
    setState(() => _isBusy = true);
    try {
      await ref.read(aiRepositoryProvider).applyRecommendations(
            businessId: business.id,
            autoApply: _autoApply,
            recommendationIds: _selectedRecommendationIds.toList(),
          );
      ref
          .read(automationSettingsProvider.notifier)
          .setAutoApplyRecommendations(_autoApply);
      if (!mounted) {
        return;
      }
      ref.read(selectedBusinessProvider.notifier).setBusiness(business);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }
}
