import 'package:bagi_fair/domain/entities/group.dart';
import 'package:bagi_fair/domain/entities/group_invite.dart';
import 'package:bagi_fair/domain/repositories/group_repository.dart';

class WatchGroups {
  const WatchGroups(this._repository);

  final GroupRepository _repository;

  Stream<List<Group>> call() => _repository.watchGroups();
}

class WatchGroup {
  const WatchGroup(this._repository);

  final GroupRepository _repository;

  Stream<Group?> call(String groupId) => _repository.watchGroup(groupId);
}

class WatchGroupMembers {
  const WatchGroupMembers(this._repository);

  final GroupRepository _repository;

  Stream<List<GroupMember>> call(String groupId) =>
      _repository.watchMembers(groupId);
}

class GetGroup {
  const GetGroup(this._repository);

  final GroupRepository _repository;

  Future<Group?> call(String groupId) => _repository.getGroup(groupId);
}

class CreateGroup {
  const CreateGroup(this._repository);

  final GroupRepository _repository;

  Future<void> call(Group group) => _repository.createGroup(group);
}

class UpdateGroup {
  const UpdateGroup(this._repository);

  final GroupRepository _repository;

  Future<void> call(Group group) => _repository.updateGroup(group);
}

class ArchiveGroup {
  const ArchiveGroup(this._repository);

  final GroupRepository _repository;

  Future<void> call(String groupId) => _repository.archiveGroup(groupId);
}

class CreateGroupInvite {
  const CreateGroupInvite(this._repository);

  final GroupRepository _repository;

  Future<GroupInvite> call(String groupId) => _repository.createInvite(groupId);
}

class JoinGroupByCode {
  const JoinGroupByCode(this._repository);

  final GroupRepository _repository;

  Future<void> call(String code) => _repository.joinGroup(code);
}
