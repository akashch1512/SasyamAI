import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';
import '../config/api_constants.dart';

class ImgBBService {
  static final ImagePicker _picker = ImagePicker();

  static Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      return file;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> uploadImage(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final response = await ApiService().uploadMultipart(
        ApiConstants.uploadImageEndpoint,
        fileBytes: bytes,
        filename: file.name,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['image_url'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
