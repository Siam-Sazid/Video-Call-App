import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/app_logger.dart';
import '../controllers/call_controller.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  const VideoCallScreen({super.key, required this.channelName});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late final CallController _controller;

  @override
  void initState() {
    super.initState();
    appLogger.i('[VideoCallScreen] initState — finding controller');
    _controller = Get.find<CallController>();
    appLogger.i('[VideoCallScreen] controller found — calling initCall');
    _controller.initCall(widget.channelName);
  }

  Future<void> _endCall() async {
    await _controller.leaveCall();
    Get.delete<CallController>();
    Get.back();
  }

  Widget _buildRemoteVideo() {
    return Obx(() {
      final uid = _controller.remoteUid.value;
      appLogger.d('[VideoCallScreen] _buildRemoteVideo — remoteUid: $uid');
      if (uid != null) {
        appLogger.i('[VideoCallScreen] Rendering remote AgoraVideoView for uid: $uid');
        return AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: _controller.engine,
            canvas: VideoCanvas(uid: uid),
            connection: RtcConnection(channelId: widget.channelName),
          ),
        );
      }
      return Container(
        color: const Color(0xFF0F3460),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF6C63FF)),
              SizedBox(height: 16),
              Text(
                'Waiting for others to join...',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLocalVideo() {
    return Obx(() {
      final ready = _controller.isEngineReady.value;
      final camOff = _controller.isCameraOff.value;
      appLogger.d('[VideoCallScreen] _buildLocalVideo — isEngineReady: $ready, isCameraOff: $camOff');
      if (!ready) return const SizedBox.shrink();
      appLogger.i('[VideoCallScreen] Rendering local AgoraVideoView');
      return Stack(
        fit: StackFit.expand,
        children: [
          AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: _controller.engine,
              canvas: const VideoCanvas(uid: 0),
            ),
          ),
          if (camOff)
            Container(
              color: const Color(0xFF16213E),
              child: const Center(
                child: Icon(Icons.videocam_off, color: Colors.white38, size: 32),
              ),
            ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _buildRemoteVideo()),
          Positioned(
            top: 48,
            right: 16,
            width: 100,
            height: 140,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildLocalVideo(),
            ),
          ),
          Positioned(
            top: 48,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, color: Color(0xFF4CAF50), size: 8),
                  const SizedBox(width: 6),
                  Text(
                    widget.channelName,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          Obx(() {
            final uid = _controller.remoteUid.value;
            if (uid == null) return const SizedBox.shrink();
            return Positioned(
              top: 100,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'UID: $uid',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
            );
          }),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ControlButton(
                      icon: _controller.isMuted.value ? Icons.mic_off : Icons.mic,
                      label: _controller.isMuted.value ? 'Unmute' : 'Mute',
                      onTap: _controller.toggleMute,
                      active: !_controller.isMuted.value,
                    ),
                    _ControlButton(
                      icon: _controller.isCameraOff.value
                          ? Icons.videocam_off
                          : Icons.videocam,
                      label: _controller.isCameraOff.value ? 'Cam Off' : 'Cam On',
                      onTap: _controller.toggleCamera,
                      active: !_controller.isCameraOff.value,
                    ),
                    _ControlButton(
                      icon: Icons.flip_camera_ios,
                      label: 'Flip',
                      onTap: _controller.flipCamera,
                    ),
                    _ControlButton(
                      icon: _controller.isSpeakerOn.value
                          ? Icons.volume_up
                          : Icons.volume_off,
                      label: _controller.isSpeakerOn.value ? 'Speaker' : 'Earpiece',
                      onTap: _controller.toggleSpeaker,
                      active: _controller.isSpeakerOn.value,
                    ),
                    _ControlButton(
                      icon: Icons.call_end,
                      label: 'End',
                      onTap: _endCall,
                      isEndCall: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool isEndCall;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = true,
    this.isEndCall = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isEndCall
                  ? const Color(0xFFE53935)
                  : active
                      ? const Color(0xFF2A2A4A)
                      : const Color(0xFF424242),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
