import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/agora_config.dart';

class VideoCallTestScreen extends StatefulWidget {
  final String channelName;
  const VideoCallTestScreen({super.key, required this.channelName});

  @override
  State<VideoCallTestScreen> createState() => _VideoCallTestScreenState();
}

class _VideoCallTestScreenState extends State<VideoCallTestScreen> {
  late RtcEngine _engine;
  bool _localJoined = false;
  int? _remoteUid;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await [Permission.camera, Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: AgoraConfig.appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (_, __) => setState(() => _localJoined = true),
      onUserJoined: (_, uid, __) => setState(() => _remoteUid = uid),
      onUserOffline: (_, uid, __) => setState(() => _remoteUid = null),
    ));

    await _engine.enableVideo();
    await _engine.joinChannel(
      token: '',
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  Widget _localView() => AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );

  Widget _remoteView() {
    if (_remoteUid == null) {
      return const Center(child: Text('Waiting for remote...', style: TextStyle(color: Colors.white)));
    }
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine,
        canvas: VideoCanvas(uid: _remoteUid!),
        connection: RtcConnection(channelId: widget.channelName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _localJoined ? _localView() : const Center(child: CircularProgressIndicator())),
          if (_remoteUid != null)
            Positioned(
              top: 48, right: 16, width: 120, height: 160,
              child: _remoteView(),
            ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.call_end),
                label: const Text('End'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
