import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auth/auth.dart';
import '../models/rbac_model.dart';
import '../../../config/rbac_config.dart';

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

final currentUserAccessProvider = StreamProvider<Map<String, bool>>((ref) async* {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    yield {};
    return;
  }

  // 1. Escuchar cambios en el perfil para obtener el role_id
  final profileStream = Supabase.instance.client
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', user.id);

  await for (final profiles in profileStream) {
    if (profiles.isEmpty) {
      yield {};
      continue;
    }

    final roleId = profiles.first['role_id'] as String?;
    final userLevel = profiles.first['user_level']?.toString().toLowerCase() ?? '';
    
    final Map<String, bool> accessMap = {};

    // 1. Si el nivel de usuario es 'administrador', dar acceso total de inmediato
    if (userLevel == 'administrador' || userLevel == 'admin') {
      accessMap['*'] = true;
      yield accessMap;
      continue;
    }

    if (roleId == null) {
      yield {};
      continue;
    }

    // 2. Obtener los permisos del rol
    final roleData = await Supabase.instance.client
        .from('roles')
        .select('permissions, name')
        .eq('id', roleId)
        .single();

    final permissionsJson = roleData['permissions'] as Map<String, dynamic>? ?? {};
    final roleName = roleData['name']?.toString().toLowerCase() ?? '';

    // 3. Si el nombre del rol es administrador, dar acceso total
    if (roleName == 'admin' || roleName == 'administrador') {
      accessMap['*'] = true;
    } else {
      // Mapear permisos del JSONB a un mapa plano de capacidades
      permissionsJson.forEach((module, actions) {
        if (actions is Map) {
          final canView = actions['view'] == true;
          // Normalizar el nombre del módulo para que coincida con el Sidebar
          String moduleKey = module.toLowerCase();
          if (moduleKey == 'jobs') moduleKey = 'projects';
          if (moduleKey == 'products') moduleKey = 'pole_barns';
          if (moduleKey == 'properties') moduleKey = 'accounts_payable'; // Ejemplo de mapeo si aplica

          if (canView) {
            accessMap['view_$moduleKey'] = true;
          }
          if (actions['create'] == true) {
            accessMap['create_$moduleKey'] = true;
          }
          if (actions['edit'] == true) {
            accessMap['edit_$moduleKey'] = true;
          }
          if (actions['delete'] == true) {
            accessMap['delete_$moduleKey'] = true;
          }
        }
      });
    }

    yield accessMap;
  }
});
