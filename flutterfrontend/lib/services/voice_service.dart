import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'api_service.dart';
import '../config/api_constants.dart';

class VoiceService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  Future<bool> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/farmer_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: filePath,
        );
        _isRecording = true;
        return true;
      }
      return false;
    } catch (e) {
      _isRecording = false;
      return false;
    }
  }

  Future<String?> stopRecordingAndTranscribe({String languageCode = 'hi-IN'}) async {
    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;

      if (path == null) return null;

      // Read audio bytes
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();

      // Send to Sarvam Saaras v3 endpoint
      final response = await ApiService().uploadMultipart(
        ApiConstants.voiceTranscribeEndpoint,
        fileBytes: bytes,
        filename: 'recording.m4a',
        fields: {'language_code': languageCode},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['transcript'] as String?;
      }
      return null;
    } catch (e) {
      _isRecording = false;
      return null;
    }
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}
