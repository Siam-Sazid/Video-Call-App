import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/datasources/agora_service.dart';
import '../../data/repositories/call_repository_impl.dart';
import '../../domain/usecases/join_channel_usecase.dart';
import '../../domain/usecases/leave_channel_usecase.dart';
import '../../domain/usecases/toggle_audio_usecase.dart';
import '../../domain/usecases/toggle_video_usecase.dart';
import '../../domain/usecases/switch_camera_usecase.dart';
import '../controllers/call_controller.dart';
import 'video_call_screen.dart'; // keep, unused temporarily
import 'video_call_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _channelController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _joinCall() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoCallTestScreen(channelName: _channelController.text.trim()),
      ),
    );
  }

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.video_call, size: 80, color: Color(0xFF6C63FF)),
                const SizedBox(height: 24),
                const Text(
                  'Video Call',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter a channel name to start or join a call',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _channelController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Channel name',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF16213E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.meeting_room_outlined, color: Colors.white38),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Please enter a channel name' : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _joinCall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Join Call',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
