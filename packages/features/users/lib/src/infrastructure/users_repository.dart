import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsersRepository {
  final SupabaseClient _supabase;

  UsersRepository(this._supabase);

  // --- Users ---

  Stream<List<Map<String, dynamic>>> getAllUsers() {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    await _supabase.from('profiles').update(updates).eq('id', userId);
  }

  Future<String> registerWorker({
    required String email,
    required String password,
    required String name,
    required String role,
    String? jobPositionId,
  }) async {
    // 1. Sign up the user
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );

    final userId = response.user?.id;
    if (userId == null) {
      throw Exception(
          'Error al crear el usuario en el sistema de autenticación');
    }

    // 2. Update the profile (trigger might have created it, but we want to set role/jobPosition)
    // We wait a bit to ensure trigger completed if any, or we use upsert
    await _supabase.from('profiles').update({
      'role': role,
      'job_position_id': jobPositionId,
      'is_active': true,
    }).eq('id', userId);

    return userId;
  }

  // --- Job Positions ---

  // Real-time stream for job positions
  Stream<List<Map<String, dynamic>>> getJobPositions() {
    return _supabase
        .from('job_positions')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  Future<void> createJobPosition(String name) async {
    await _supabase.from('job_positions').insert({'name': name});
  }

  Future<void> updateJobPosition(String id, String name) async {
    await _supabase.from('job_positions').update({'name': name}).eq('id', id);
  }

  Future<void> deleteJobPosition(String id) async {
    await _supabase.from('job_positions').delete().eq('id', id);
  }

  // --- Worker Groups ---
  Stream<List<Map<String, dynamic>>> getWorkerGroups() {
    return _supabase
        .from('worker_groups')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  Future<void> createWorkerGroup(String name, String? supervisorId) async {
    await _supabase.from('worker_groups').insert({
      'name': name,
      'supervisor_id': supervisorId,
    });
  }

  Future<void> updateWorkerGroup(
      String id, String name, String? supervisorId) async {
    await _supabase.from('worker_groups').update({
      'name': name,
      'supervisor_id': supervisorId,
    }).eq('id', id);
  }

  Future<void> deleteWorkerGroup(String id) async {
    await _supabase.from('worker_groups').delete().eq('id', id);
  }

  // --- Group Members ---
  Stream<List<Map<String, dynamic>>> getGroupMembers(String groupId) {
    return _supabase
        .from('worker_group_members')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  Future<void> addGroupMember(String groupId, String profileId) async {
    await _supabase.from('worker_group_members').insert({
      'group_id': groupId,
      'profile_id': profileId,
    });
  }

  Future<void> removeGroupMember(String groupId, String profileId) async {
    await _supabase
        .from('worker_group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('profile_id', profileId);
  }
}

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository(Supabase.instance.client);
});

final allUsersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(usersRepositoryProvider).getAllUsers();
});

// Changed to StreamProvider for real-time updates
final jobPositionsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(usersRepositoryProvider).getJobPositions();
});

final workerGroupsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(usersRepositoryProvider).getWorkerGroups();
});

final groupMembersProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, groupId) {
  return ref.watch(usersRepositoryProvider).getGroupMembers(groupId);
});
