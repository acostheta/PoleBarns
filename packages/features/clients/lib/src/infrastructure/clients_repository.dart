import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientsRepository {
  final SupabaseClient _supabase;

  ClientsRepository(this._supabase);

  // --- Clients ---

  Stream<List<Map<String, dynamic>>> getAllClients() {
    return _supabase
        .from('clients')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  Future<void> createClient(Map<String, dynamic> clientData) async {
    final userId = _supabase.auth.currentUser?.id;
    final data = {
      ...clientData,
      'created_by': userId,
      'updated_by': userId,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await _supabase.from('clients').insert(data);
  }

  Future<void> updateClient(String clientId, Map<String, dynamic> updates) async {
    final userId = _supabase.auth.currentUser?.id;
    final data = {
      ...updates,
      'updated_by': userId,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await _supabase.from('clients').update(data).eq('id', clientId);
  }

  Future<void> deleteClient(String cliendId) async {
    await _supabase.from('clients').delete().eq('id', cliendId);
  }
}

final clientsRepositoryProvider = Provider<ClientsRepository>((ref) {
  return ClientsRepository(Supabase.instance.client);
});

final allClientsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(clientsRepositoryProvider).getAllClients();
});
