import '../repositories/call_repository.dart';

class ToggleVideoUseCase {
  final CallRepository _repository;
  const ToggleVideoUseCase(this._repository);
  Future<void> call(bool mute) => _repository.muteLocalVideo(mute);
}
