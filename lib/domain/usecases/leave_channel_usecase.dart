import '../repositories/call_repository.dart';

class LeaveChannelUseCase {
  final CallRepository _repository;
  const LeaveChannelUseCase(this._repository);
  Future<void> call() => _repository.leaveChannel();
}
