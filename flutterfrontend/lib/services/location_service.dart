import 'package:geolocator/geolocator.dart';

class FarmerLocationResult {
  final double latitude;
  final double longitude;
  final String? state;
  final String? district;

  FarmerLocationResult({
    required this.latitude,
    required this.longitude,
    this.state,
    this.district,
  });
}

class LocationService {
  static Future<FarmerLocationResult?> getCurrentFarmerLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      // Estimate regional agro-climatic state based on coordinates (fallback mapping)
      String estimatedState = _estimateStateFromCoords(position.latitude, position.longitude);
      String estimatedDistrict = "Regional Zone";

      return FarmerLocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        state: estimatedState,
        district: estimatedDistrict,
      );
    } catch (e) {
      return null;
    }
  }

  static String _estimateStateFromCoords(double lat, double lng) {
    if (lat >= 18.0 && lat <= 22.0 && lng >= 72.0 && lng <= 80.0) {
      return "Maharashtra";
    } else if (lat >= 29.5 && lat <= 32.5 && lng >= 74.0 && lng <= 77.0) {
      return "Punjab";
    } else if (lat >= 27.0 && lat <= 30.5 && lng >= 74.5 && lng <= 77.5) {
      return "Haryana";
    } else if (lat >= 21.0 && lat <= 26.5 && lng >= 74.0 && lng <= 82.5) {
      return "Madhya Pradesh";
    } else if (lat >= 20.0 && lat <= 24.5 && lng >= 68.0 && lng <= 74.5) {
      return "Gujarat";
    } else if (lat >= 23.5 && lat <= 30.5 && lng >= 77.0 && lng <= 84.5) {
      return "Uttar Pradesh";
    } else if (lat >= 11.5 && lat <= 18.5 && lng >= 74.0 && lng <= 78.5) {
      return "Karnataka";
    } else if (lat >= 12.5 && lat <= 19.5 && lng >= 77.0 && lng <= 84.5) {
      return "Andhra Pradesh / Telangana";
    } else if (lat >= 8.0 && lat <= 13.5 && lng >= 76.0 && lng <= 80.5) {
      return "Tamil Nadu";
    }
    return "India (Agricultural Region)";
  }
}
