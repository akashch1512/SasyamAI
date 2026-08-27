import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/imgbb_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _cropsController = TextEditingController();

  String _selectedSoil = 'Black Soil';
  String _selectedIrrigation = 'Borewell & Drip';
  double _landSize = 5.0;
  bool _isUploadingPhoto = false;

  final List<String> _soilTypes = [
    'Black Soil',
    'Alluvial Soil',
    'Red & Yellow Soil',
    'Sandy Loam',
    'Clay Soil',
    'Laterite Soil',
  ];

  final List<String> _irrigationSources = [
    'Borewell & Drip',
    'Canal Irrigation',
    'Rainfed / Monsoon',
    'Sprinkler System',
    'Open Well / River',
  ];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      _nameController.text = user.fullName;
      _phoneController.text = user.phoneNumber ?? '';
      _stateController.text = user.state ?? '';
      _districtController.text = user.district ?? '';
      _cropsController.text = user.primaryCrops ?? '';
      _selectedSoil = user.soilType ?? 'Black Soil';
      _selectedIrrigation = user.irrigationSource ?? 'Borewell & Drip';
      _landSize = user.landSizeAcres ?? 5.0;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _cropsController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadProfileImage() async {
    final image = await ImgBBService.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _isUploadingPhoto = true);
      final uploadedUrl = await ImgBBService.uploadImage(image);
      setState(() => _isUploadingPhoto = false);

      if (uploadedUrl != null && mounted) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        await auth.updateProfile({'profile_image_url': uploadedUrl});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image updated successfully! 📸'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.updateProfile({
      'full_name': _nameController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'state': _stateController.text.trim(),
      'district': _districtController.text.trim(),
      'soil_type': _selectedSoil,
      'land_size_acres': _landSize,
      'irrigation_source': _selectedIrrigation,
      'primary_crops': _cropsController.text.trim(),
    });

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Farm profile saved successfully! 🌱'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Farmer Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Photo with ImgBB upload badge
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: AppTheme.paleGreen,
                    backgroundImage: user?.profileImageUrl != null
                        ? NetworkImage(user!.profileImageUrl!)
                        : null,
                    child: user?.profileImageUrl == null
                        ? const Icon(Icons.person, size: 48, color: AppTheme.primaryGreen)
                        : null,
                  ),
                  GestureDetector(
                    onTap: _isUploadingPhoto ? null : _pickAndUploadProfileImage,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.primaryGreen,
                      child: _isUploadingPhoto
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? '',
                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 24),

              // Farmer Information Header
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Personal Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
              ),
              const SizedBox(height: 12),

              CustomTextField(
                controller: _nameController,
                labelText: 'Full Name',
                prefixIcon: Icons.person_outline,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter name' : null,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _phoneController,
                labelText: 'Phone Number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _stateController,
                      labelText: 'State',
                      prefixIcon: Icons.map_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _districtController,
                      labelText: 'District',
                      prefixIcon: Icons.location_city_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Farm Details
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Farm & Agriculture Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
              ),
              const SizedBox(height: 12),

              // Soil Type Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Soil Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderGrey),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _soilTypes.contains(_selectedSoil) ? _selectedSoil : _soilTypes.first,
                        isExpanded: true,
                        items: _soilTypes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedSoil = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Irrigation Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Irrigation Source', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderGrey),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _irrigationSources.contains(_selectedIrrigation) ? _selectedIrrigation : _irrigationSources.first,
                        isExpanded: true,
                        items: _irrigationSources.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedIrrigation = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Land Size
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Land Size:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                  Text('${_landSize.toStringAsFixed(1)} Acres', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                ],
              ),
              Slider(
                value: _landSize,
                min: 0.5,
                max: 50.0,
                divisions: 99,
                activeColor: AppTheme.primaryGreen,
                inactiveColor: AppTheme.borderGrey,
                onChanged: (v) => setState(() => _landSize = v),
              ),
              const SizedBox(height: 10),

              CustomTextField(
                controller: _cropsController,
                labelText: 'Primary Crops Grown',
                hintText: 'e.g. Cotton, Wheat, Soybean',
                prefixIcon: Icons.grass_rounded,
              ),
              const SizedBox(height: 28),

              CustomButton(
                text: 'Save Changes',
                isLoading: auth.isLoading,
                onPressed: _saveProfile,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
