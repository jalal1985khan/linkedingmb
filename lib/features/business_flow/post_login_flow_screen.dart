import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/business_profile.dart';
import '../../data/repositories/gmbapi_repository.dart';
import '../auth/auth_controller.dart';
import '../settings/automation_settings_controller.dart';
import 'business_flow_controller.dart';

enum _FlowStage { selection, preview, onboarding, analyzing, recommendations }

class PostLoginFlowScreen extends ConsumerStatefulWidget {
  const PostLoginFlowScreen({super.key});

  @override
  ConsumerState<PostLoginFlowScreen> createState() => _PostLoginFlowScreenState();
}

class _PostLoginFlowScreenState extends ConsumerState<PostLoginFlowScreen> {
  _FlowStage _stage = _FlowStage.selection;
  BusinessProfile? _onboardingBusiness;
  Map<String, dynamic>? _selectedLocationPreview;
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
      case _FlowStage.preview:
        return _buildLocationPreview();
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
        data: (data) {
          final List<dynamic> locations = data['locations'] ?? [];
          final String? selectedLocationId = data['selected_location_id'];

          if (selectedLocationId != null) {
            // User already has a locked location. Select it and skip the screen!
            final location = locations.firstWhere(
                (loc) => loc['name']?.toString() == selectedLocationId,
                orElse: () => null);
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final business = BusinessProfile(
                  id: selectedLocationId,
                  name: location != null ? (location['title'] ?? 'Selected Business') : 'Selected Business',
                  category: location != null ? (location['categories']?['primaryCategory']?['displayName'] ?? '') : '',
                  location: location != null ? (location['storefrontAddress']?['locality'] ?? '') : '',
                  address: (location != null && location['storefrontAddress']?['addressLines'] != null && (location['storefrontAddress']!['addressLines'] as List).isNotEmpty) ? (location['storefrontAddress']!['addressLines'] as List)[0].toString() : '',
                  phone: location != null ? (location['phoneNumbers']?['primaryPhone'] ?? '') : '',
                  hoursSummary: '',
                  website: location != null ? (location['websiteUri'] ?? '') : '',
                  targetAudience: '',
                  brandTone: '',
                  postingFrequency: 4,
                );
                ref.read(selectedBusinessProvider.notifier).setBusiness(business);
              }
            });
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (locations.isEmpty) {
            _stage = _FlowStage.onboarding;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {});
              }
            });
            return const SizedBox.shrink();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(gmbapiLocationsProvider);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
            children: [
              Text(
                'We found ${locations.length} associated profiles via GMB',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...locations.map((location) {
                final raw = location['gmbapi_raw'] ?? {};
                final state = raw['state']?.toString() ?? 'Unknown';
                final isVerified = raw['is_verified'] == 1 || raw['is_verified'] == true;
                
                String statusText = state;
                Color statusColor = Colors.grey;
                
                if (state.toLowerCase() == 'active' && isVerified) {
                  statusText = 'Active & Verified';
                  statusColor = Colors.green;
                } else if (!isVerified) {
                  statusText = 'Pending Verification';
                  statusColor = Colors.orange;
                } else if (state.toLowerCase() == 'inactive') {
                  statusText = 'Inactive / Not Approved';
                  statusColor = Colors.red;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(location['title'] ?? 'Unknown Business'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${location['categories']?['primaryCategory']?['displayName'] ?? ''} • ${location['storefrontAddress']?['locality'] ?? ''}'),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: statusColor.withOpacity(0.5)),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () {
                      setState(() {
                        _selectedLocationPreview = location;
                        _stage = _FlowStage.preview;
                      });
                    },
                  ),
                );
              }).toList(),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => setState(() => _stage = _FlowStage.onboarding),
                icon: const Icon(Icons.add_business_rounded),
                label: const Text('My business is not listed'),
              ),
              const SizedBox(height: 12),
            ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationPreview() {
    final location = _selectedLocationPreview;
    if (location == null) {
      return const Center(child: Text("No location selected"));
    }
    
    final raw = location['gmbapi_raw'] ?? {};
    final state = raw['state']?.toString() ?? 'Unknown';
    final isVerified = raw['is_verified'] == 1 || raw['is_verified'] == true;
    
    String statusText = state;
    Color statusColor = Colors.grey;
    if (state.toLowerCase() == 'active' && isVerified) {
      statusText = 'Active & Verified';
      statusColor = Colors.green;
    } else if (!isVerified) {
      statusText = 'Pending Verification';
      statusColor = Colors.orange;
    } else if (state.toLowerCase() == 'inactive') {
      statusText = 'Inactive / Not Approved';
      statusColor = Colors.red;
    }

    final title = location['title'] ?? 'Unknown Business';
    final category = location['categories']?['primaryCategory']?['displayName'] ?? '';
    final addressLines = location['storefrontAddress']?['addressLines'] as List?;
    final address = addressLines != null && addressLines.isNotEmpty ? addressLines.join(", ") : '';
    final phone = location['phoneNumbers']?['primaryPhone'] ?? '';
    final website = location['websiteUri'] ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _stage = _FlowStage.selection),
        ),
        title: const Text('Confirm Business Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.storefront, size: 64, color: Colors.blueGrey.shade300),
            ),
            const SizedBox(height: 24),
            Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
            if (category.isNotEmpty) _buildDetailRow(Icons.category, category),
            if (address.isNotEmpty) _buildDetailRow(Icons.location_on, address),
            if (phone.isNotEmpty) _buildDetailRow(Icons.phone, phone),
            if (website.isNotEmpty) _buildDetailRow(Icons.language, website),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Disclaimer: Once you register with this business profile, you cannot select another one later. Your account will be tied to this business.',
                      style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isBusy ? null : () async {
                setState(() => _isBusy = true);
                try {
                  final locationId = location['name']?.toString() ?? '';
                  await ref.read(gmbapiRepositoryProvider).selectLocation(locationId);
                  
                  final business = BusinessProfile(
                    id: locationId,
                    name: title,
                    category: category,
                    location: location['storefrontAddress']?['locality'] ?? '',
                    address: addressLines != null && addressLines.isNotEmpty ? addressLines[0].toString() : '',
                    phone: phone,
                    hoursSummary: '',
                    website: website,
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
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _isBusy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Register with this Business'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
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
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(aiRecommendationsProvider(business.id));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
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
            ),
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
