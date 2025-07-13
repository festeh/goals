import 'dart:async';
import 'dart:io';
import 'package:dimaist/models/note.dart';
import 'package:dimaist/services/api_service.dart';
import 'package:dimaist/services/app_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class WearRecordingScreen extends StatefulWidget {
  const WearRecordingScreen({super.key});

  @override
  State<WearRecordingScreen> createState() => _WearRecordingScreenState();
}

class _WearRecordingScreenState extends State<WearRecordingScreen>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  final AppDatabase _db = AppDatabase();
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _audioPath;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
      if (mounted) {
        setState(() {
          _isRecording = true;
        });
      }
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<bool> _requestPermissions() async {
    var status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    if (mounted) {
      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _audioPath = path;
      });
    }

    if (_audioPath != null) {
      try {
        final file = File(_audioPath!);
        final bytes = await file.readAsBytes();
        final Note note = await ApiService.sendAudio(bytes);
        await _db.upsertNote(note);
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/note', arguments: note);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error sending audio: $e');
        }
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRecording)
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: const Icon(Icons.mic, size: 50, color: Colors.red),
                )
              else if (_isProcessing)
                const CircularProgressIndicator()
              else
                const SizedBox.shrink(),
              const SizedBox(height: 20),
              Text(
                _isRecording
                    ? 'Recording...'
                    : _isProcessing
                        ? 'Processing...'
                        : 'Done',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 100,
                height: 100,
                child: ElevatedButton(
                  onPressed: _isRecording ? _stopRecording : null,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: Colors.red,
                  ),
                  child: const Icon(Icons.stop, size: 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}