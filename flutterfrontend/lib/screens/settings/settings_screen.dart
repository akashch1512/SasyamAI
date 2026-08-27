import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_constants.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/custom_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _serverUrlController = TextEditingController();
  String _selectedLanguage = 'hi-IN';

  final Map<String, String> _languages = {
    'hi-IN': 'Hindi (हिन्दी)',
    'en-IN': 'English (India)',
    'mr-IN': 'Marathi (मराठी)',
    'pa-IN': 'Punjabi (ਪੰਜਾਬੀ)',
    'gu-IN': 'Gujarati (ગુજરાતી)',
    'te-IN': 'Telugu (తెలుగు)',
    'ta-IN': 'Tamil (தமிழ்)',
    'kn-IN': 'Kannada (ಕನ್ನಡ)',
    'bn-IN': 'Bengali (বাংলা)',
    'ml-IN': 'Malayalam (മലയാളം)',
  };

  @override
  void initState() {
    super.initState();
    _serverUrlController.text = ApiService().baseUrl;
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(ApiConstants.languageKey) ?? 'hi-IN';
    setState(() {
      _selectedLanguage = lang;
    });
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final newUrl = _serverUrlController.text.trim();
    if (newUrl.isNotEmpty) {
      await ApiService().setBaseUrl(newUrl);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.languageKey, _selectedLanguage);

    if (mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.updateProfile({'preferred_language': _selectedLanguage});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully! ⚙️'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preferred Voice Language (Sarvam AI STT)
            const Text(
              'Voice Input & AI Language',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select your preferred Indian regional language for microphone voice recognition powered by Sarvam Saaras v3.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderGrey),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  isExpanded: true,
                  items: _languages.entries.map((e) {
                    return DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value, style: const TextStyle(color: AppTheme.textDark, fontSize: 14.5)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedLanguage = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Backend Server URL
            const Text(
              'Backend API Server URL',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 6),
            const Text(
              'Configure the FastAPI backend address (use http://10.0.2.2:8000 for Android Emulator, or http://127.0.0.1:8000 for local desktop/web).',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _serverUrlController,
              style: const TextStyle(fontSize: 14.5, color: AppTheme.textDark),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.dns_outlined, size: 20, color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.surfaceWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderGrey),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Save Button
            CustomButton(
              text: 'Save Settings',
              onPressed: _saveSettings,
            ),
            const SizedBox(height: 40),

            // About SasyamAI Section
            Center(
              child: Column(
                children: [
                  const AppLogo(size: 40, fontSize: 20),
                  const SizedBox(height: 8),
                  const Text(
                    'Version 1.0.0 (FastAPI + LangGraph + Flutter)',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Empowering Indian Agriculture with Artificial Intelligence',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
