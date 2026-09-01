import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import '../config/api_constants.dart';
import 'api_service.dart';

class TtsService {
  TtsService._() {
    _player.onPlayerComplete.listen((_) {
      _speakingMessageId = null;
    });
  }
  static final TtsService instance = TtsService._();

  final AudioPlayer _player = AudioPlayer();
  String? _speakingMessageId;

  String? get speakingMessageId => _speakingMessageId;
  bool get isPlaying => _speakingMessageId != null;

  Future<void> speak({
    required String text,
    required String languageCode,
    String? messageId,
  }) async {
    if (text.trim().isEmpty) return;

    await stop();
    _speakingMessageId = messageId ?? 'live';

    try {
      final response = await ApiService().post(
        ApiConstants.voiceTtsEndpoint,
        body: {
          'text': text,
          'language_code': languageCode,
          'speaker': 'anushka',
        },
      );

      if (response.statusCode != 200) {
        _speakingMessageId = null;
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['is_fallback'] == true) {
        _speakingMessageId = null;
        return;
      }

      final audioB64 = data['audio_base64'] as String? ?? '';
      if (audioB64.isEmpty) {
        _speakingMessageId = null;
        return;
      }

      final bytes = base64Decode(audioB64);
      final tempDir = await getTemporaryDirectory();
      final contentType = (data['content_type'] as String?) ?? 'audio/wav';
      final ext = contentType.contains('mpeg') || contentType.contains('mp3')
          ? 'mp3'
          : 'wav';
      final file = File(
        '${tempDir.path}/sasyam_tts_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      await file.writeAsBytes(bytes, flush: true);

      await _player.play(DeviceFileSource(file.path));
    } catch (_) {
      _speakingMessageId = null;
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    _speakingMessageId = null;
  }

  Future<void> toggle({
    required String text,
    required String languageCode,
    String? messageId,
  }) async {
    if (_speakingMessageId != null && _speakingMessageId == messageId) {
      await stop();
      return;
    }
    await speak(
      text: text,
      languageCode: languageCode,
      messageId: messageId,
    );
  }
}
