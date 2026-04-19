import '../repositories/call_repository.dart';

class SwitchCameraUseCase {
  final CallRepository _repository;
  const SwitchCameraUseCase(this._repository);
  Future<void> call() => _repository.switchCamera();
}
