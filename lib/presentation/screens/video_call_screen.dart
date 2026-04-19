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

  // Watches only remoteUid + isLocalJoined — never rebuilds due to isCameraOff.
  // Returns AgoraVideoView directly with no extra Stack wrapper.
  Widget _buildBackground() {
    return Obx(() {
      final uid = _controller.remoteUid.value;
      final joined = _controller.isLocalJoined.value;

      if (uid != null) {
        appLogger.i('[VideoCallScreen] Background: remote uid $uid');
        return AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: _controller.engine,
            canvas: VideoCanvas(uid: uid),
            connection: RtcConnection(channelId: widget.channelName),
          ),
        );
      }

      if (!joined) {
        return Container(
          color: const Color(0xFF16213E),
          child: const Center(
            child: Icon(Icons.videocam, color: Colors.white38, size: 48),
          ),
        );
      }

      appLogger.i('[VideoCallScreen] Background: local video');
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _controller.engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Layer 1: video background
          Positioned.fill(child: _buildBackground()),

          // Layer 2: camera-off overlay for fullscreen local video
          Positioned.fill(
            child: Obx(() {
              final solo = _controller.remoteUid.value == null;
              final joined = _controller.isLocalJoined.value;
              final camOff = _controller.isCameraOff.value;
              if (!camOff || !solo || !joined) return const SizedBox.shrink();
              return Container(
                color: const Color(0xFF16213E),
                child: const Center(
                  child: Icon(Icons.videocam_off, color: Colors.white38, size: 48),
                ),
              );
            }),
          ),

          // Layer 3: local pip — Positioned is outside Obx, not inside it
          Positioned(
            top: 48,
            right: 16,
            width: 100,
            height: 140,
            child: Obx(() {
              final uid = _controller.remoteUid.value;
              final joined = _controller.isLocalJoined.value;
              if (uid == null || !joined) return const SizedBox.shrink();
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _controller.engine,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                ),
              );
            }),
          ),

          // Layer 4: camera-off overlay for pip
          Positioned(
            top: 48,
            right: 16,
            width: 100,
            height: 140,
            child: Obx(() {
              final uid = _controller.remoteUid.value;
              final joined = _controller.isLocalJoined.value;
              final camOff = _controller.isCameraOff.value;
              if (uid == null || !joined || !camOff) return const SizedBox.shrink();
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: const Color(0xFF16213E),
                  child: const Center(
                    child: Icon(Icons.videocam_off, color: Colors.white38, size: 24),
                  ),
                ),
              );
            }),
          ),

          // Layer 5: channel name badge
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

          // Layer 6: remote UID badge — Positioned outside Obx
          Positioned(
            top: 100,
            left: 16,
            child: Obx(() {
              final uid = _controller.remoteUid.value;
              if (uid == null) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'UID: $uid',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              );
            }),
          ),

          // Layer 7: control bar
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
