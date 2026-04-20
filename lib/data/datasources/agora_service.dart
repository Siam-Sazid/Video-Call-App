import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/agora_config.dart';
import '../../core/utils/app_logger.dart';

class AgoraService {
  RtcEngine? _engine;
  RtcEngine get engine => _engine!;

  final _localJoinedController = StreamController<void>.broadcast();
  final _remoteJoinedController = StreamController<int>.broadcast();
  final _remoteLeftController = StreamController<int>.broadcast();

  Stream<void> get onLocalJoined => _localJoinedController.stream;
  Stream<int> get onRemoteJoined => _remoteJoinedController.stream;
  Stream<int> get onRemoteLeft => _remoteLeftController.stream;

  Future<void> initialize() async {
    appLogger.i('[AgoraService] Requesting permissions...');
    final statuses = await [Permission.camera, Permission.microphone].request();
    appLogger.i('[AgoraService] Camera: ${statuses[Permission.camera]}');
    appLogger.i('[AgoraService] Microphone: ${statuses[Permission.microphone]}');

    appLogger.i('[AgoraService] Creating RTC engine...');
    _engine = createAgoraRtcEngine();

    await _engine!.initialize(const RtcEngineContext(
      appId: AgoraConfig.appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));
    appLogger.i('[AgoraService] Engine initialized');

    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        appLogger.i('[AgoraService] onJoinChannelSuccess — channel: ${connection.channelId}, uid: ${connection.localUid}');
        _localJoinedController.add(null);
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        appLogger.i('[AgoraService] onUserJoined — uid: $remoteUid');
        _remoteJoinedController.add(remoteUid);
      },
      onUserOffline: (connection, remoteUid, reason) {
        appLogger.i('[AgoraService] onUserOffline — uid: $remoteUid, reason: $reason');
        _remoteLeftController.add(remoteUid);
      },
      onError: (err, msg) {
        appLogger.e('[AgoraService] onError — code: $err, msg: $msg');
      },
      onConnectionStateChanged: (connection, state, reason) {
        appLogger.i('[AgoraService] connectionState: $state, reason: $reason');
      },
      onLocalVideoStateChanged: (source, state, reason) {
        appLogger.i('[AgoraService] localVideoState: $state, reason: $reason');
      },
      onCameraReady: () {
        appLogger.i('[AgoraService] onCameraReady ✓');
      },
    ));
    appLogger.i('[AgoraService] Event handlers registered');

    await _engine!.enableVideo();
    appLogger.i('[AgoraService] Video enabled');
  }

  Future<void> joinChannel(String channelName) async {
    final token = AgoraConfig.tempToken;
    final mode = (token.isEmpty) ? 'TEST MODE (no token)' : 'TOKEN MODE (temp token)';
    appLogger.i('[AgoraService] Auth mode: $mode');
    appLogger.i('[AgoraService] Joining channel: "$channelName"');
    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
    appLogger.i('[AgoraService] joinChannel call dispatched');
  }

  Future<void> leaveChannel() async {
    appLogger.i('[AgoraService] Leaving channel...');
    await _engine!.leaveChannel();
    appLogger.i('[AgoraService] Channel left');
  }

  Future<void> muteLocalAudio(bool mute) => _engine!.muteLocalAudioStream(mute);

  Future<void> muteLocalVideo(bool mute) => _engine!.muteLocalVideoStream(mute);

  Future<void> switchCamera() => _engine!.switchCamera();

  Future<void> setSpeakerphone(bool enabled) => _engine!.setEnableSpeakerphone(enabled);

  void dispose() {
    appLogger.i('[AgoraService] Disposing...');
    _localJoinedController.close();
    _remoteJoinedController.close();
    _remoteLeftController.close();
    _engine?.release();
    _engine = null;
  }
}
