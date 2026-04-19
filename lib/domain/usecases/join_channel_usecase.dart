import '../repositories/call_repository.dart';

class JoinChannelUseCase {
  final CallRepository _repository;
  const JoinChannelUseCase(this._repository);
  Future<void> call(String channelName) => _repository.joinChannel(channelName);
}
