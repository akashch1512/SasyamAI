Implementation Plan: SasyamAI End-to-End Agriculture AI Platform
Implement the complete SasyamAI application: a FastAPI + LangGraph + PostgreSQL backend and a clean, farmer-first, white, professional Flutter chat frontend with voice input (Sarvam Saaras v3 STT), image-based crop disease detection (ChatGPT Vision), crop recommendation (modular ML placeholder), crop price & government scheme fetchers, user profile & onboarding, ImgBB integration, and an admin analytics dashboard.

User Review Required
IMPORTANT

API Keys & Fallback Modes:

The application will read OPENAI_API_KEY, SARVAM_API_KEY, and IMGBB_API_KEY from the backend .env file or request headers.
Intelligent, structured fallback modes are built-in for all services (ChatGPT LLM & Vision, Sarvam STT, ImgBB) so the entire platform, UI, voice flow, and image detection work reliably during development and local testing even before API keys are configured.
When valid API keys are supplied in .env, the system automatically activates live OpenAI GPT-4o / GPT-4o-mini, Sarvam Saaras v3 STT, and ImgBB remote hosting.
NOTE

Default Admin Account: A default admin user (admin@sasyamai.com / admin123) will be auto-seeded on initial startup so you can immediately access and test the Admin Analytics Dashboard. Any regular user can also be promoted or given the admin role.

Proposed Architecture & Component Flow
Mermaid diagram
Proposed Changes
Backend (FastapiBackend/)
[MODIFY] 
pyproject.toml
Add dependencies: asyncpg, pydantic-settings, openai, langchain-openai, pyjwt, pwdlib / passlib[bcrypt], python-multipart, alembic.
[NEW] 
config.py
Pydantic Settings class to manage database URL, JWT secret/algorithm, OpenAI API key & model, Sarvam API key & endpoint, ImgBB API key, and environment flags.
[NEW] 
database.py
Async SQLAlchemy engine configuration, sessionmaker (AsyncSession), Base declarative model, and database dependency get_db().
[NEW] 
models/user.py
User SQLAlchemy model: email, hashed_password, full_name, phone_number, profile_image_url, role (user/admin), state, district, latitude, longitude, soil_type, land_size_acres, irrigation_source, primary_crops (JSON), preferred_language, is_onboarded, timestamps.
[NEW] 
models/chat.py
ChatSession model: id (UUID), user_id, title, timestamps.
ChatMessage model: id (UUID), session_id, role (user/assistant), content, image_url, metadata_json, created_at.
[NEW] 
models/analytics.py
QueryAnalytics model: user_id, session_id, query_text, category, detected_crop, detected_disease, state, created_at.
[NEW] 
schemas/auth.py
, 
schemas/user.py
, 
schemas/chat.py
, 
schemas/admin.py
, 
schemas/voice.py
Pydantic v2 validation models for request/response bodies.
[NEW] 
core/security.py
 & 
core/dependencies.py
Password hashing & verification, JWT token generation & validation, get_current_user and get_admin_user dependency injections.
[NEW] 
agent/state.py
LangGraph AgentState schema holding chat messages, farmer profile context, image URL, intent, missing profile fields, ML recommendations, disease analysis, and response text.
[NEW] 
agent/knowledge/farm_advisory_guide.md
Domain knowledge guide covering Indian crops, soil types, NPK fertilizer formulas, Integrated Pest Management (IPM), irrigation techniques, seasonal Kharif/Rabi/Zaid schedules, and organic farming advice.
[NEW] 
agent/tools/crop_recommendation.py
Modular ML prediction interface predict_crops_ml(...) (clean placeholder function ready for ML model drop-in) + LLM reasoning node that checks required farmer details (soil, state, irrigation) and asks clarifying questions if required.
[NEW] 
agent/tools/crop_price.py
Mandi price fetcher placeholder function fetch_crop_market_price(...) returning "This feature is not implemented yet, but it will be available soon. :)".
[NEW] 
agent/tools/government_schemes.py
Scheme fetcher placeholder function fetch_government_schemes(...) returning "This feature is not implemented yet, but it will be available soon. :)".
[NEW] 
agent/subagents/disease_detector.py
Specialized Crop Disease Detection Agent using OpenAI GPT-4o vision with structured diagnostic output (Issue/Pathogen, Confidence, Symptoms, Immediate Treatment, Organic Solutions, Preventive Measures).
[NEW] 
agent/orchestrator.py
LangGraph StateGraph compiling the routing logic, sub-agent invocation, agronomy guidance retrieval, ML crop recommendation, and query analytics logging.
[NEW] 
services/sarvam_service.py
 & 
services/imgbb_service.py
Sarvam AI Saaras v3 STT integration with multi-language Indian audio processing + ImgBB cloud storage uploader.
[NEW] 
api/routes/auth.py
, 
user.py
, 
chat.py
, 
voice.py
, 
admin.py
Modular API route handlers following FastAPI best practices.
[MODIFY] 
main.py
Initialize FastAPI app with lifespan (database table creation, default admin seeding), CORS middleware, and router inclusion.
Frontend (flutterfrontend/)
[MODIFY] 
pubspec.yaml
Add dependencies: http, provider, shared_preferences, image_picker, flutter_markdown, geolocator, record, audioplayers / path_provider, fl_chart, intl, google_fonts.
Configure assets/images/logo.png.
[NEW] 
config/theme.dart
Clean, white, farmer-first theme: soft green accents (#1B5E20, #2E7D32), clean white cards (#FFFFFF, #F8FAF9), high-contrast text, clear typography.
[NEW] 
config/api_constants.dart
Base URL (http://10.0.2.2:8000 / http://localhost:8000 / configurable) and endpoint paths.
[NEW] 
models/user_model.dart
, 
chat_model.dart
, 
admin_model.dart
Dart model classes with fromJson and toJson.
[NEW] 
services/api_service.dart
, 
voice_service.dart
, 
imgbb_service.dart
, 
location_service.dart
Central network, audio recording, image upload, and GPS location services.
[NEW] 
providers/auth_provider.dart
, 
chat_provider.dart
, 
admin_provider.dart
Reactive state management with ChangeNotifier.
[NEW] 
widgets/app_logo.dart
, 
chat_bubble.dart
, 
chat_input_bar.dart
, 
custom_button.dart
Reusable UI components styled for clean white aesthetic.
[NEW] 
screens/splash_screen.dart
Splash screen displaying SasyamAI logo and checking authentication status.
[NEW] 
screens/auth/login_screen.dart
 & 
register_screen.dart
Minimalist white authentication screens with "Continue with Google" option.
[NEW] 
screens/onboarding/onboarding_screen.dart
Farmer onboarding flow: GPS auto-detect location, phone number, soil type chips, land size slider/input, irrigation method, primary crops.
[NEW] 
screens/chat/chat_screen.dart
 & 
screens/chat/components/chat_drawer.dart
Full ChatGPT-style chat interface with drawer for chat history sessions, new chat button, image preview chips, voice recording modal, and quick switch to Admin panel (for admin users).
[NEW] 
screens/profile/profile_screen.dart
View and edit farmer details, farm acreage, soil type, location, and ImgBB profile photo uploader.
[NEW] 
screens/settings/settings_screen.dart
Preferred language selector, backend URL configuration, offline cache toggles, and About SasyamAI.
[NEW] 
screens/admin/admin_dashboard_screen.dart
Admin analytics dashboard:
Metric KPI cards (Total Users, Total Queries, Crop Recommendations, Disease Scans).
Search query category breakdown charts with fl_chart.
Top searched crops & farmer issues.
Registered farmers list table.
AI-generated search trend insights.
[MODIFY] 
main.dart
Provider bindings, routing, clean white theme initialization, and entry point.
Verification Plan
Automated Verification:
Backend Tests & Static Analysis:
uv run ruff check . (ensure zero lint issues).
uv run ruff format . (ensure proper formatting).
Test script verifying:
User registration, login, JWT token issue, and onboarding.
Chat session creation and messaging flow.
LangGraph execution with Crop Recommendation, Crop Price placeholder, Govt Scheme placeholder, Farm Advisory, and Vision Disease Detection.
Voice transcription endpoint with Sarvam STT.
Admin statistics and query analytics endpoints.
Flutter Static Analysis & Tests:
flutter analyze (ensure zero compilation or lint errors).
flutter test (verify widget tests and model serialization tests pass).
Manual / Live Verification:
Start the FastAPI backend with uv run uvicorn app.main:app --port 8000.
Verify Swagger UI at http://127.0.0.1:8000/docs with all endpoints functioning.
Test user flow: Login -> Onboarding -> Chat with text/image/voice -> Profile update -> Admin Dashboard.