import 'dart:async';
import 'dart:io';
import 'package:dimaist/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class RecordingDialog extends StatefulWidget {
  const RecordingDialog({super.key});

  @override
  State<RecordingDialog> createState() => _RecordingDialogState();
}

class _RecordingDialogState extends State<RecordingDialog>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _audioPath;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _startRecording();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _requestPermissions();
    if (hasPermission) {
      const encoder = AudioEncoder.wav;
      const config = RecordConfig(
        encoder: encoder,
        numChannels: 1,
        sampleRate: 16000,
        bitRate: 256000,
        noiseSuppress: true,
      );
      final path = '${Directory.systemTemp.path}/temp.wav';
      await _recorder.start(config, path: path);
      setState(() {
        _isRecording = true;
      });
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isLinux) {
      return true;
    }
    var status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _audioPath = path;
    });
    if (_audioPath != null) {
      try {
        final file = File(_audioPath!);
        final bytes = await file.readAsBytes();
        await ApiService.sendAudio(bytes);
      } catch (e) {
        if (kDebugMode) {
          print('Error sending audio: $e');
        }
      } finally {
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recording...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isRecording)
            ScaleTransition(
              scale: _scaleAnimation,
              child: const Icon(Icons.mic, size: 50),
            )
          else
            const Text('Processing...'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isRecording ? _stopRecording : null,
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }
}
