import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Session? get currentSession => _supabase.auth.currentSession;
  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signInWithEmailAndPassword(String email, String password) async {
    // Clear any stale cached data before signing in so the navbar
    // always shows fresh data from the server on the first load.
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) =>
        k.startsWith('profile_map_') || k.startsWith('access_map_')).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
    return await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmailAndPassword(String email, String password, {String? name}) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: name != null ? {'name': name} : null,
    );
  }

  Future<void> signOut() async {
    // Clear cached profile & access so the next user starts with a blank slate.
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) =>
        k.startsWith('profile_map_') || k.startsWith('access_map_')).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
    await _supabase.auth.signOut();
  }

  // Profile Management
  
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? picture,
    String? role,
    bool? isActive,
    String? jobPositionId,
  }) async {
    final updates = {
      'updated_at': DateTime.now().toIso8601String(),
      if (name != null) 'name': name,
      if (picture != null) 'picture': picture,
      'role': role,
      if (isActive != null) 'is_active': isActive,
      if (jobPositionId != null) 'job_position_id': jobPositionId,
    };
    await _supabase.from('profiles').update(updates).eq('id', userId);
  }
  
  Stream<List<Map<String, dynamic>>> getJobPositions() {
     return _supabase
        .from('job_positions')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }
  
  Future<String> uploadAvatar({
    required String userId,
    required List<int> fileBytes,
    required String fileName,
    required String contentType,
  }) async {
    final path = 'public/$userId/$fileName';
    await _supabase.storage.from('avatars').uploadBinary(
          path,
          (fileBytes is Uint8List) ? fileBytes : Uint8List.fromList(fileBytes),
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return _supabase.storage.from('avatars').getPublicUrl(path);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// Reactive to auth state so it re-fetches on login / logout
final userProfileProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, userId) async* {
  // ── Watch auth state so this provider re-runs on login/logout ──
  ref.watch(authStateProvider);

  final prefs = await SharedPreferences.getInstance();
  final cacheKey = 'profile_map_$userId';
  final cached = prefs.getString(cacheKey);
  
  if (cached != null) {
    try {
      yield jsonDecode(cached) as Map<String, dynamic>;
    } catch (_) {}
  }

  try {
    final data = await ref.watch(authRepositoryProvider).getUserProfile(userId);
    if (data != null) {
      prefs.setString(cacheKey, jsonEncode(data));
    }
    yield data;
  } catch (e) {
    // On network/token error, just keep the cached value (or null).
    if (cached == null) yield null;
  }
});

// Note: jobPositionsProvider in this file is likely deprecated/duplicates the one in users_repository.
// However, the dashboard or other legacy code might use it. Ideally we should remove it if unused,
// but for safety we'll leave it or user request didn't mention it.
// Actually, let's keep it as is or if User wants real-time everywhere.
// The user explicitly asked for "Job Positions" module so that's handled in users_repository.
final jobPositionsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(authRepositoryProvider).getJobPositions();
});
