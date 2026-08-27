import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../services/imgbb_service.dart';
import '../services/voice_service.dart';

class ChatInputBar extends StatefulWidget {
  final Function(String text, String? imageUrl) onSendMessage;
  final bool isSending;
  final String preferredLanguage;

  const ChatInputBar({
    super.key,
    required this.onSendMessage,
    this.isSending = false,
    this.preferredLanguage = 'hi-IN',
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final VoiceService _voiceService = VoiceService();

  XFile? _selectedImage;
  bool _isUploadingImage = false;
  String? _uploadedImageUrl;

  bool _isRecordingVoice = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.85,
      upperBound: 1.15,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _pulseController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _pulseController.forward();
        }
      });
  }

  @override
  void dispose() {
    _textController.dispose();
    _voiceService.dispose();
    _recordingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty && _uploadedImageUrl == null) return;

    widget.onSendMessage(text, _uploadedImageUrl);
    _textController.clear();
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await ImgBBService.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _isUploadingImage = true;
      });

      final url = await ImgBBService.uploadImage(image);
      setState(() {
        _uploadedImageUrl = url;
        _isUploadingImage = false;
      });
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Upload Crop / Leaf Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.paleGreen,
                  child: Icon(Icons.camera_alt, color: AppTheme.primaryGreen),
                ),
                title: const Text('Take Picture with Camera'),
                subtitle: const Text('Capture plant leaf or disease symptom'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.paleGreen,
                  child: Icon(Icons.photo_library, color: AppTheme.primaryGreen),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select photo from phone storage'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleVoiceRecording() async {
    if (_isRecordingVoice) {
      // Stop recording
      _recordingTimer?.cancel();
      _pulseController.stop();

      setState(() {
        _isRecordingVoice = false;
      });

      // Show transcribing indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transcribing voice via Sarvam Saaras v3... 🎙️'),
          duration: Duration(seconds: 2),
        ),
      );

      final transcript = await _voiceService.stopRecordingAndTranscribe(
        languageCode: widget.preferredLanguage,
      );

      if (transcript != null && transcript.isNotEmpty) {
        setState(() {
          _textController.text = transcript;
        });
      }
    } else {
      // Start recording
      final started = await _voiceService.startRecording();
      if (started) {
        setState(() {
          _isRecordingVoice = true;
          _recordingSeconds = 0;
        });
        _pulseController.forward();
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordingSeconds++;
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: const Border(top: BorderSide(color: AppTheme.borderGrey, width: 1)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selected Image Preview Bar
            if (_selectedImage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderGrey),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 44,
                        height: 44,
                        color: AppTheme.paleGreen,
                        child: const Icon(Icons.image, color: AppTheme.primaryGreen),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isUploadingImage
                            ? 'Uploading to ImgBB...'
                            : 'Crop image ready for diagnosis',
                        style: TextStyle(
                          fontSize: 13,
                          color: _isUploadingImage ? AppTheme.primaryGreen : AppTheme.textDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_isUploadingImage)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _selectedImage = null;
                            _uploadedImageUrl = null;
                          });
                        },
                      ),
                  ],
                ),
              ),

            // Main Input Controls
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Image Picker Button
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primaryGreen),
                  onPressed: widget.isSending ? null : _showImageSourcePicker,
                  tooltip: 'Upload Leaf Photo for Disease Diagnosis',
                ),

                // Voice Recording Button
                if (_isRecordingVoice)
                  ScaleTransition(
                    scale: _pulseController,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.stop, color: Colors.white),
                        onPressed: _toggleVoiceRecording,
                        tooltip: 'Stop Recording',
                      ),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.mic_none_rounded, color: AppTheme.primaryGreen),
                    onPressed: widget.isSending ? null : _toggleVoiceRecording,
                    tooltip: 'Speak in Hindi / Regional Language (Sarvam STT)',
                  ),

                // Text Input Field
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.borderGrey),
                    ),
                    child: _isRecordingVoice
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                const Text('🎙️ Listening...', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Text('00:${_recordingSeconds.toString().padLeft(2, '0')}s', style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : TextField(
                            controller: _textController,
                            maxLines: 4,
                            minLines: 1,
                            style: const TextStyle(color: AppTheme.textDark, fontSize: 15),
                            decoration: const InputDecoration(
                              hintText: 'Message SasyamAI (e.g. crop advice, disease)...',
                              hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                            onSubmitted: (_) => _handleSend(),
                          ),
                  ),
                ),
                const SizedBox(width: 8),

                // Send Button
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryGreen,
                  child: widget.isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : IconButton(
                          icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                          onPressed: widget.isSending ? null : _handleSend,
                          tooltip: 'Send message',
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
