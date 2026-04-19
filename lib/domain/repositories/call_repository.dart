abstract class CallRepository {
  Stream<void> get onLocalJoined;
  Stream<int> get onRemoteJoined;
  Stream<int> get onRemoteLeft;

  Future<void> initialize();
  Future<void> joinChannel(String channelName);
  Future<void> leaveChannel();
  Future<void> muteLocalAudio(bool mute);
  Future<void> muteLocalVideo(bool mute);
  Future<void> switchCamera();
  Future<void> setSpeakerphone(bool enabled);
  void dispose();
}
