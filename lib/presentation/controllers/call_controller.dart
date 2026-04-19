import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:get/get.dart';
import '../../core/utils/app_logger.dart';
import '../../data/datasources/agora_service.dart';
import '../../domain/repositories/call_repository.dart';
import '../../domain/usecases/join_channel_usecase.dart';
import '../../domain/usecases/leave_channel_usecase.dart';
import '../../domain/usecases/toggle_audio_usecase.dart';
import '../../domain/usecases/toggle_video_usecase.dart';
import '../../domain/usecases/switch_camera_usecase.dart';

class CallController extends GetxController {
  final CallRepository _repository;
  final AgoraService _agoraService;
  final JoinChannelUseCase _joinChannel;
  final LeaveChannelUseCase _leaveChannel;
  final ToggleAudioUseCase _toggleAudio;
  final ToggleVideoUseCase _toggleVideo;
  final SwitchCameraUseCase _switchCamera;

  CallController({
    required CallRepository repository,
    required AgoraService agoraService,
    required JoinChannelUseCase joinChannel,
    required LeaveChannelUseCase leaveChannel,
    required ToggleAudioUseCase toggleAudio,
    required ToggleVideoUseCase toggleVideo,
    required SwitchCameraUseCase switchCamera,
  })  : _repository = repository,
        _agoraService = agoraService,
        _joinChannel = joinChannel,
        _leaveChannel = leaveChannel,
        _toggleAudio = toggleAudio,
        _toggleVideo = toggleVideo,
        _switchCamera = switchCamera;

  final isEngineReady = false.obs;
  final isLocalJoined = false.obs;
  final remoteUid = Rxn<int>();
  final isMuted = false.obs;
  final isCameraOff = false.obs;
  final isSpeakerOn = true.obs;

  late final StreamSubscription _localSub;
  late final StreamSubscription _remoteSub;
  late final StreamSubscription _remoteLeftSub;

  RtcEngine get engine => _agoraService.engine;

  Future<void> initCall(String channelName) async {
    appLogger.i('[CallController] initCall started for channel: "$channelName"');

    try {
      await _repository.initialize();
      appLogger.i('[CallController] repository initialized');

      isEngineReady.value = true;
      appLogger.i('[CallController] isEngineReady = true');

      _localSub = _repository.onLocalJoined.listen((_) {
        appLogger.i('[CallController] local user joined ✓ → isLocalJoined = true');
        isLocalJoined.value = true;
        _repository.setSpeakerphone(true).catchError((e) {
          appLogger.w('[CallController] setSpeakerphone failed: $e');
        });
      });

      _remoteSub = _repository.onRemoteJoined.listen((uid) {
        appLogger.i('[CallController] remote user joined → uid: $uid');
        remoteUid.value = uid;
      });

      _remoteLeftSub = _repository.onRemoteLeft.listen((uid) {
        appLogger.i('[CallController] remote user left → uid: $uid');
        remoteUid.value = null;
      });

      appLogger.i('[CallController] joining channel...');
      await _joinChannel.call(channelName);
      appLogger.i('[CallController] joinChannel dispatched');
    } catch (e, st) {
      appLogger.e('[CallController] initCall failed', error: e, stackTrace: st);
    }
  }

  Future<void> leaveCall() async {
    appLogger.i('[CallController] leaveCall');
    await _leaveChannel.call();
  }

  Future<void> toggleMute() async {
    isMuted.value = !isMuted.value;
    appLogger.i('[CallController] mute → ${isMuted.value}');
    await _toggleAudio.call(isMuted.value);
  }

  Future<void> toggleCamera() async {
    isCameraOff.value = !isCameraOff.value;
    appLogger.i('[CallController] camera off → ${isCameraOff.value}');
    await _toggleVideo.call(isCameraOff.value);
  }

  Future<void> flipCamera() => _switchCamera.call();

  Future<void> toggleSpeaker() async {
    isSpeakerOn.value = !isSpeakerOn.value;
    appLogger.i('[CallController] speaker → ${isSpeakerOn.value}');
    await _repository.setSpeakerphone(isSpeakerOn.value);
  }

  @override
  void onClose() {
    appLogger.i('[CallController] onClose — cleaning up');
    _localSub.cancel();
    _remoteSub.cancel();
    _remoteLeftSub.cancel();
    _repository.dispose();
    super.onClose();
  }
}
