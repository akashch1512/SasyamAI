class ApiConstants {
  // Default base URL (configurable by user in settings)
  // For Android Emulator use: http://10.0.2.2:8000
  // For Linux/macOS/Desktop/Web use: 
  static const String defaultBaseUrl = 'https://sasyamai.onrender.com';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String baseUrlKey = 'custom_base_url';
  static const String languageKey = 'preferred_language';

  // API Endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String googleAuthEndpoint = '/api/auth/google';
  static const String meEndpoint = '/api/auth/me';

  static const String profileEndpoint = '/api/user/profile';
  static const String onboardingEndpoint = '/api/user/onboarding';
  static const String uploadImageEndpoint = '/api/user/upload-image';

  static const String chatSessionsEndpoint = '/api/chat/sessions';
  static const String chatMessageEndpoint = '/api/chat/message';

  static const String voiceTranscribeEndpoint = '/api/voice/transcribe';

  static const String adminStatsEndpoint = '/api/admin/stats';
  static const String adminUsersEndpoint = '/api/admin/users';
  static const String adminQueriesEndpoint = '/api/admin/queries-summary';
  static const String adminInsightsEndpoint = '/api/admin/insights';
}
