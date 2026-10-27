import 'dart:async';

import 'package:bagi_fair/data/datasources/cloud_gateway.dart';
import 'package:bagi_fair/data/datasources/local_store.dart';
import 'package:bagi_fair/data/repositories/repository_helpers.dart';
import 'package:bagi_fair/domain/entities/activity_entry.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:bagi_fair/domain/entities/group_invite.dart';
import 'package:bagi_fair/domain/entities/outbox_item.dart';
import 'package:bagi_fair/domain/repositories/auth_repository.dart';
import 'package:bagi_fair/domain/repositories/group_repository.dart';
import 'package:bagi_fair/domain/repositories/mutation_queue.dart';
import 'package:uuid/uuid.dart';

class GroupRepositoryImpl implements GroupRepository {
  GroupRepositoryImpl({
    required this._store,
    required this._queue,
    required this._auth,
    required this._gateway,
    this._uuid = const Uuid(),
  });

  final LocalStore _store;
  final MutationQueue _queue;
  final AuthRepository _auth;
  final CloudGateway _gateway;
  final Uuid _uuid;

  @override
  Stream<List<Group>> watchGroups() {
    return _store.watch('groups').map((rows) {
      final groups = <Group>[];
      for (final row in rows) {
        if (row['deleted_at'] != null) continue;
        final group = Group.fromJson(row);
        if (group.archived) continue;
        groups.add(_withRole(group));
      }
      groups.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return groups;
    });
  }

  @override
  Stream<Group?> watchGroup(String groupId) {
    return _store.watch('groups').map((rows) {
      for (final row in rows) {
        if (row['id'] == groupId && row['deleted_at'] == null) {
          return _withRole(Group.fromJson(row));
        }
      }
      return null;
    });
  }

  @override
  Stream<List<GroupMember>> watchMembers(String groupId) {
    return _store.watch('group_members').map((rows) {
      final members = <GroupMember>[];
      for (final row in rows) {
        if (row['group_id'] != groupId || row['deleted_at'] != null) continue;
        members.add(GroupMember.fromJson(row));
      }
      members.sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
      return members;
    });
  }

  @override
  Stream<List<GroupMember>> watchAllMembers() {
    return _store.watch('group_members').map((rows) {
      final members = <GroupMember>[];
      for (final row in rows) {
        if (row['deleted_at'] != null) continue;
        members.add(GroupMember.fromJson(row));
      }
      return members;
    });
  }

  @override
  Future<Group?> getGroup(String groupId) async {
    final row = _store.get('groups', groupId);
    if (row == null || row['deleted_at'] != null) return null;
    return _withRole(Group.fromJson(row));
  }

  @override
  Future<void> createGroup(Group group) async {
    final user = _auth.currentUser;
    final now = DateTime.now();
    final groupRow = group.copyWith(updatedAt: now).toJson();
    await _store.put('groups', groupRow, pending: !_queue.isDemo);
    await _queue.enqueue(
      table: 'groups',
      rowId: group.id,
      operation: OutboxOperation.upsert,
      payload: groupRow,
    );

    if (user != null) {
      final member = GroupMember(
        id: _uuid.v4(),
        groupId: group.id,
        userId: user.id,
        displayName: user.displayName,
        email: user.email,
        avatarUrl: user.avatarUrl,
        role: GroupRole.owner,
        joinedAt: now,
      );
      final memberRow = member.toJson();
      await _store.put('group_members', memberRow, pending: !_queue.isDemo);
      await _queue.enqueue(
        table: 'group_members',
        rowId: member.id,
        operation: OutboxOperation.upsert,
        payload: memberRow,
      );

      await logActivity(
        _store,
        _queue,
        id: _uuid.v4(),
        groupId: group.id,
        actorId: user.id,
        actorName: user.displayName,
        kind: ActivityKind.groupCreated,
        summary: 'membuat grup ${group.name}',
      );
    }
  }

  @override
  Future<void> updateGroup(Group group) async {
    final row = group.copyWith(updatedAt: DateTime.now()).toJson();
    await _store.put('groups', row, pending: !_queue.isDemo);
    await _queue.enqueue(
      table: 'groups',
      rowId: group.id,
      operation: OutboxOperation.upsert,
      payload: row,
    );
  }

  @override
  Future<void> archiveGroup(String groupId) async {
    final group = await getGroup(groupId);
    if (group == null) return;
    await updateGroup(group.copyWith(archived: true));
  }

  @override
  Future<GroupInvite> createInvite(String groupId) async {
    final now = DateTime.now();
    final code = _gateway.isDemo
        ? _generateCode()
        : await _gateway.createInvite(groupId);
    final invite = GroupInvite(
      code: code,
      groupId: groupId,
      createdBy: _auth.currentUser?.id ?? '',
      createdAt: now,
      expiresAt: now.add(const Duration(days: 7)),
    );
    if (_gateway.isDemo) {
      final row = invite.toJson()..['id'] = code;
      await _store.put('group_invites', row);
    }
    return invite;
  }

  @override
  Future<void> joinGroup(String code) async {
    final normalized = code.trim().toUpperCase();
    if (!_gateway.isDemo) {
      await _gateway.joinGroup(normalized);
      _queue.requestSync();
      return;
    }

    Map<String, dynamic>? invite;
    for (final row in _store.all('group_invites')) {
      if ((row['code'] as String?)?.toUpperCase() == normalized) {
        invite = row;
        break;
      }
    }
    if (invite == null) {
      throw const GroupJoinException('invite_not_found');
    }
    final expiresAt = DateTime.tryParse(invite['expires_at']?.toString() ?? '');
    if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
      throw const GroupJoinException('invite_expired');
    }
    final groupId = invite['group_id'] as String;
    final user = _auth.currentUser;
    if (user == null) {
      throw const GroupJoinException('not_signed_in');
    }
    final group = await getGroup(groupId);
    if (group == null) {
      throw const GroupJoinException('invite_not_found');
    }
    final alreadyMember = _store
        .all('group_members')
        .any((row) => row['group_id'] == groupId && row['user_id'] == user.id);
    if (alreadyMember) {
      throw const GroupJoinException('already_member');
    }

    final member = GroupMember(
      id: _uuid.v4(),
      groupId: groupId,
      userId: user.id,
      displayName: user.displayName,
      email: user.email,
      avatarUrl: user.avatarUrl,
      role: GroupRole.member,
      joinedAt: DateTime.now(),
    );
    await _store.put('group_members', member.toJson());
    final updated = group.copyWith(
      memberCount: group.memberCount + 1,
      updatedAt: DateTime.now(),
    );
    await _store.put('groups', updated.toJson());
    await logActivity(
      _store,
      _queue,
      id: _uuid.v4(),
      groupId: groupId,
      actorId: user.id,
      actorName: user.displayName,
      kind: ActivityKind.memberJoined,
      summary: 'bergabung ke grup',
    );
  }

  Group _withRole(Group group) {
    final userId = _auth.currentUser?.id;
    if (userId == null) return group;
    if (group.ownerId == userId) {
      return group.copyWith(myRole: GroupRole.owner);
    }
    for (final row in _store.all('group_members')) {
      if (row['group_id'] == group.id && row['user_id'] == userId) {
        final role = GroupRole.values.firstWhere(
          (value) => value.name == row['role'],
          orElse: () => GroupRole.member,
        );
        return group.copyWith(myRole: role);
      }
    }
    return group;
  }

  String _generateCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final seed = DateTime.now().microsecondsSinceEpoch;
    var value = seed;
    final buffer = StringBuffer();
    for (var i = 0; i < 7; i++) {
      buffer.write(alphabet[value % alphabet.length]);
      value ~/= alphabet.length;
    }
    return buffer.toString();
  }
}
