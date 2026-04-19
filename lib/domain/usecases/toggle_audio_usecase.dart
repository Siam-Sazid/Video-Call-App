import '../repositories/call_repository.dart';

class ToggleAudioUseCase {
  final CallRepository _repository;
  const ToggleAudioUseCase(this._repository);
  Future<void> call(bool mute) => _repository.muteLocalAudio(mute);
}
