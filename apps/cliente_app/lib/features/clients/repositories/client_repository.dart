import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/client_model.dart';

final clientRepositoryProvider = Provider((ref) => ClientRepository());

class ClientRepository {
  final _client = Supabase.instance.client;

  Stream<List<ClientModel>> getClientsStream() {
    return _client
        .from('clients')
        .stream(primaryKey: ['id'])
        .order('first_name')
        .map((data) => data.map((json) => ClientModel.fromJson(json)).toList());
  }

  Future<List<ClientModel>> searchClients(String query) async {
    final response = await _client
        .from('clients')
        .select()
        .or('first_name.ilike.%$query%,last_name.ilike.%$query%')
        .order('first_name');
    return (response as List)
        .map((json) => ClientModel.fromJson(json))
        .toList();
  }

  Future<void> createClient(ClientModel client) async {
    await _client.from('clients').insert(client.toJson());
  }

  Future<void> updateClient(String id, ClientModel client) async {
    await _client.from('clients').update(client.toJson()).eq('id', id);
  }

  Future<void> deleteClient(String id) async {
    await _client.from('clients').delete().eq('id', id);
  }

  Future<ClientModel?> getClient(String id) async {
    final response =
        await _client.from('clients').select().eq('id', id).single();
    return ClientModel.fromJson(response);
  }
}
