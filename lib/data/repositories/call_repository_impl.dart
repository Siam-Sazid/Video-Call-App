import '../../domain/repositories/call_repository.dart';
import '../datasources/agora_service.dart';

class CallRepositoryImpl implements CallRepository {
  final AgoraService _agoraService;
  CallRepositoryImpl(this._agoraService);

  @override
  Stream<void> get onLocalJoined => _agoraService.onLocalJoined;
  @override
  Stream<int> get onRemoteJoined => _agoraService.onRemoteJoined;
  @override
  Stream<int> get onRemoteLeft => _agoraService.onRemoteLeft;

  @override
  Future<void> initialize() => _agoraService.initialize();
  @override
  Future<void> joinChannel(String channelName) => _agoraService.joinChannel(channelName);
  @override
  Future<void> leaveChannel() => _agoraService.leaveChannel();
  @override
  Future<void> muteLocalAudio(bool mute) => _agoraService.muteLocalAudio(mute);
  @override
  Future<void> muteLocalVideo(bool mute) => _agoraService.muteLocalVideo(mute);
  @override
  Future<void> switchCamera() => _agoraService.switchCamera();
  @override
  Future<void> setSpeakerphone(bool enabled) => _agoraService.setSpeakerphone(enabled);
  @override
  void dispose() => _agoraService.dispose();
}
