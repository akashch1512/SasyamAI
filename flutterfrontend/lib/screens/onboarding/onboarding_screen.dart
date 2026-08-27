import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../chat/chat_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;

  // Controllers & Form State
  final _phoneController = TextEditingController();
  final _stateController = TextEditingController(text: 'Maharashtra');
  final _districtController = TextEditingController(text: 'Pune');

  double _landSize = 5.0;
  double? _latitude;
  double? _longitude;
  bool _isDetectingLocation = false;

  String _selectedSoil = 'Black Soil';
  final List<String> _soilTypes = [
    'Black Soil',
    'Alluvial Soil',
    'Red & Yellow Soil',
    'Sandy Loam',
    'Clay Soil',
    'Laterite Soil',
  ];

  String _selectedIrrigation = 'Borewell & Drip';
  final List<String> _irrigationSources = [
    'Borewell & Drip',
    'Canal Irrigation',
    'Rainfed / Monsoon',
    'Sprinkler System',
    'Open Well / River',
  ];

  final List<String> _selectedCrops = ['Cotton', 'Soybean'];
  final List<String> _availableCrops = [
    'Cotton',
    'Wheat',
    'Paddy (Rice)',
    'Soybean',
    'Sugarcane',
    'Tomato',
    'Onion',
    'Gram (Chickpea)',
    'Mustard',
    'Groundnut',
    'Chilli',
    'Maize',
  ];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        _phoneController.text = user.phoneNumber!;
      }
      if (user.state != null && user.state!.isNotEmpty) {
        _stateController.text = user.state!;
      }
      if (user.district != null && user.district!.isNotEmpty) {
        _districtController.text = user.district!;
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  Future<void> _detectGpsLocation() async {
    setState(() {
      _isDetectingLocation = true;
    });

    final locationResult = await LocationService.getCurrentFarmerLocation();

    if (!mounted) return;

    if (locationResult != null) {
      setState(() {
        _latitude = locationResult.latitude;
        _longitude = locationResult.longitude;
        if (locationResult.state != null) {
          _stateController.text = locationResult.state!;
        }
        if (locationResult.district != null) {
          _districtController.text = locationResult.district!;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 Location detected: ${_stateController.text}'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not access GPS. Please type your state & district manually.'),
        ),
      );
    }

    setState(() {
      _isDetectingLocation = false;
    });
  }

  Future<void> _submitOnboarding() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.completeOnboarding(
      phoneNumber: _phoneController.text.trim(),
      state: _stateController.text.trim(),
      district: _districtController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      soilType: _selectedSoil,
      landSizeAcres: _landSize,
      irrigationSource: _selectedIrrigation,
      primaryCrops: _selectedCrops.join(', '),
      preferredLanguage: 'en',
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save profile. Continuing to chat...'),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
    }
  }

  void _skipOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const AppLogo(size: 32, fontSize: 18),
        actions: [
          TextButton(
            onPressed: _skipOnboarding,
            child: const Text('Skip for now', style: TextStyle(color: AppTheme.textMuted)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: index <= _currentStep ? AppTheme.primaryGreen : AppTheme.borderGrey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: _buildCurrentStepView(),
              ),
            ),

            // Bottom Navigation Controls
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundWhite,
                border: Border(top: BorderSide(color: AppTheme.borderGrey)),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      flex: 1,
                      child: CustomButton(
                        text: 'Back',
                        isOutlined: true,
                        onPressed: () => setState(() => _currentStep--),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: _currentStep == 2 ? 'Complete & Start Chat' : 'Next Step',
                      isLoading: auth.isLoading,
                      onPressed: () {
                        if (_currentStep < 2) {
                          setState(() => _currentStep++);
                        } else {
                          _submitOnboarding();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 0:
        return _buildStep1LocationAndPhone();
      case 1:
        return _buildStep2SoilAndLand();
      case 2:
        return _buildStep3CropsAndSummary();
      default:
        return Container();
    }
  }

  Widget _buildStep1LocationAndPhone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 1 of 3',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
        ),
        const SizedBox(height: 4),
        const Text(
          'Where is your farm located?',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 8),
        const Text(
          'Location helps SasyamAI provide weather-accurate crop advice and region-specific market rates.',
          style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 24),

        // Auto GPS Detect Button
        OutlinedButton.icon(
          onPressed: _isDetectingLocation ? null : _detectGpsLocation,
          icon: _isDetectingLocation
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen))
              : const Icon(Icons.my_location_rounded, color: AppTheme.primaryGreen),
          label: Text(
            _isDetectingLocation ? 'Detecting GPS Coordinates...' : 'Use Current Farm Location (GPS)',
            style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            side: const BorderSide(color: AppTheme.primaryGreen, width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),

        CustomTextField(
          controller: _stateController,
          labelText: 'State',
          hintText: 'e.g. Maharashtra / Punjab / Gujarat',
          prefixIcon: Icons.map_outlined,
        ),
        const SizedBox(height: 16),

        CustomTextField(
          controller: _districtController,
          labelText: 'District',
          hintText: 'e.g. Pune / Ludhiana / Nashik',
          prefixIcon: Icons.location_city_outlined,
        ),
        const SizedBox(height: 16),

        CustomTextField(
          controller: _phoneController,
          labelText: 'Phone Number (Optional)',
          hintText: '+91 98765 43210',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildStep2SoilAndLand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 2 of 3',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
        ),
        const SizedBox(height: 4),
        const Text(
          'Soil & Land Details',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 8),
        const Text(
          'Selecting your soil and water availability allows precise crop suitability ML predictions.',
          style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 24),

        const Text(
          'Primary Soil Type:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _soilTypes.map((soil) {
            final isSelected = _selectedSoil == soil;
            return ChoiceChip(
              label: Text(soil),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedSoil = soil);
              },
              selectedColor: AppTheme.paleGreen,
              backgroundColor: AppTheme.surfaceWhite,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryGreen : AppTheme.textDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppTheme.primaryGreen : AppTheme.borderGrey,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Land Size Slider & Display
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Farm Size (Acres):',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.paleGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_landSize.toStringAsFixed(1)} Acres',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
              ),
            ),
          ],
        ),
        Slider(
          value: _landSize,
          min: 0.5,
          max: 50.0,
          divisions: 99,
          activeColor: AppTheme.primaryGreen,
          inactiveColor: AppTheme.borderGrey,
          onChanged: (val) => setState(() => _landSize = val),
        ),
        const SizedBox(height: 20),

        const Text(
          'Irrigation / Water Source:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _irrigationSources.map((source) {
            final isSelected = _selectedIrrigation == source;
            return ChoiceChip(
              label: Text(source),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedIrrigation = source);
              },
              selectedColor: AppTheme.paleGreen,
              backgroundColor: AppTheme.surfaceWhite,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryGreen : AppTheme.textDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppTheme.primaryGreen : AppTheme.borderGrey,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep3CropsAndSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 3 of 3',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
        ),
        const SizedBox(height: 4),
        const Text(
          'What crops do you grow?',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select current or intended crops so the AI agent can give contextual advice and disease alerts.',
          style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 20),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableCrops.map((crop) {
            final isSelected = _selectedCrops.contains(crop);
            return FilterChip(
              label: Text(crop),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCrops.add(crop);
                  } else {
                    _selectedCrops.remove(crop);
                  }
                });
              },
              selectedColor: AppTheme.paleGreen,
              backgroundColor: AppTheme.surfaceWhite,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryGreen : AppTheme.textDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppTheme.primaryGreen : AppTheme.borderGrey,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),

        // Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderGrey),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppTheme.primaryGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Profile Summary',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark),
                  ),
                ],
              ),
              const Divider(color: AppTheme.borderGrey, height: 20),
              _buildSummaryRow('Location', '${_stateController.text}, ${_districtController.text}'),
              _buildSummaryRow('Soil', _selectedSoil),
              _buildSummaryRow('Land Size', '${_landSize.toStringAsFixed(1)} Acres'),
              _buildSummaryRow('Water Source', _selectedIrrigation),
              _buildSummaryRow('Crops', _selectedCrops.isEmpty ? 'General Farming' : _selectedCrops.join(', ')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
