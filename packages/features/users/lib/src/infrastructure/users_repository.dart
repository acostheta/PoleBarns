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
