import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auth/auth.dart';
import '../models/rbac_model.dart';

final rbacRepositoryProvider = Provider((ref) => RbacRepository());

class RbacRepository {
  final _client = Supabase.instance.client;

  // --- Roles Management ---

  Future<List<Map<String, dynamic>>> getRoles() async {
    final data = await _client.from('app_roles').select().order('name');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> createRole(String name, {String? description}) async {
    await _client.from('app_roles').insert({
      'name': name,
      'description': description,
    });
  }

  Future<void> updateRole(String id, String oldName, String newName,
      {String? description}) async {
    // 1. Update the role itself
    await _client.from('app_roles').update({
      'name': newName,
      'description': description,
    }).eq('id', id);

    // 2. Cascade update permissions (since they use role_name as UNIQUE key/FK logic)
    if (oldName != newName) {
      await _client
          .from('app_role_permissions')
          .update({'role_name': newName}).eq('role_name', oldName);

      // 3. Cascade update profiles
      await _client
          .from('profiles')
          .update({'role': newName}).eq('role', oldName);
    }
  }

  Future<void> deleteRole(String id, String roleName) async {
    // 1. Delete permissions first (CASCADE in DB would be better, but let's be safe)
    await _client
        .from('app_role_permissions')
        .delete()
        .eq('role_name', roleName);

    // 2. Delete the role
    await _client.from('app_roles').delete().eq('id', id);

    // Note: Profiles will keep the role string unless we null it out,
    // but typically we'd reassign users before deleting a role.
  }

  // --- Modules & Permissions ---

  Future<List<AppModule>> getModules() async {
    final data = await _client.from('app_modules').select().order('name');
    return (data as List).map((e) => AppModule.fromJson(e)).toList();
  }

  Future<List<RolePermission>> getPermissionsForRole(String roleName) async {
    final data = await _client
        .from('app_role_permissions')
        .select()
        .eq('role_name', roleName);
    return (data as List).map((e) => RolePermission.fromJson(e)).toList();
  }

  Future<void> updatePermission(
      String roleName, String moduleId, bool canAccess) async {
    final params = {
      'role_name': roleName,
      'module_id': moduleId,
      'can_access': canAccess,
    };

    await _client.from('app_role_permissions').upsert(
          params,
          onConflict: 'role_name, module_id',
        );
  }
}

// Providers
final rolesListProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(rbacRepositoryProvider);
  return repo.getRoles();
});

final modulesListProvider = FutureProvider<List<AppModule>>((ref) async {
  final repo = ref.watch(rbacRepositoryProvider);
  return repo.getModules();
});

final rolePermissionsProvider =
    FutureProvider.family<List<RolePermission>, String>((ref, roleName) async {
  final repo = ref.watch(rbacRepositoryProvider);
  return repo.getPermissionsForRole(roleName);
});

final currentUserAccessProvider =
    StreamProvider<Map<String, bool>>((ref) async* {
  // ── React to auth changes so this provider re-runs on login / logout ──
  final authState = ref.watch(authStateProvider);
  final session = authState.valueOrNull?.session;
  final user = session?.user ?? Supabase.instance.client.auth.currentUser;

  if (user == null) {
    yield {};
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final cacheKey = 'access_map_${user.id}';
  final cachedData = prefs.getString(cacheKey);
  
  // 1. Yield cached data immediately so the sidebar isn't blank while loading.
  if (cachedData != null) {
    try {
      final decoded = jsonDecode(cachedData) as Map<String, dynamic>;
      final casted = decoded.map((key, value) => MapEntry(key, value as bool));
      yield casted;
    } catch (_) {}
  }

  // 2. Fetch from network
  try {
    final client = Supabase.instance.client;
    
    // Watch the profile state
    final profileProvider = ref.watch(userProfileProvider(user.id));
    final role = profileProvider.valueOrNull?['role'] as String?;
    final isLoadingProfile = profileProvider.isLoading;
    final hasError = profileProvider.hasError;

    // Si aún está cargando o hubo un error (por ejemplo, token fallido), 
    // mantenemos el caché actual si existe y terminamos.
    if ((role == null && isLoadingProfile) || hasError) {
      if (cachedData == null) yield {};
      return;
    }

    if (role == 'Administrador') {
      final adminAccess = {'*': true};
      prefs.setString(cacheKey, jsonEncode(adminAccess));
      yield adminAccess;
      return;
    }

    // Si el rol es null genuinamente (sin error de red y ya cargó), no tienen permisos.
    if (role == null) {
      if (cachedData != '{}') {
        prefs.setString(cacheKey, jsonEncode({}));
      }
      yield {};
      return;
    }

    final data = await client
        .from('app_role_permissions')
        .select('can_access, app_modules(key)')
        .eq('role_name', role);

    final Map<String, bool> access = {};
    for (var item in data as List) {
      final moduleData = item['app_modules'];
      if (moduleData != null) {
        final key = moduleData['key'] as String;
        final can = item['can_access'] as bool;
        access[key] = can;
      }
    }
    
    // Save to cache
    prefs.setString(cacheKey, jsonEncode(access));
    yield access;
  } catch (e) {
    // If error and we have cached data, just let the stream end with it.
    // We don't yield empty to not overwrite the cached data.
    if (cachedData == null) {
      yield {};
    }
  }
});
