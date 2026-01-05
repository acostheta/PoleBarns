import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/client_model.dart';

final clientRepositoryProvider = Provider((ref) => ClientRepository());

class ClientRepository {
  final _client = Supabase.instance.client;

  Stream<List<ClientModel>> getClientsStream() {
    return _client
        .from('clientes')
        .stream(primaryKey: ['id'])
        .order('nombre')
        .map((data) => data.map((json) => ClientModel.fromJson(json)).toList());
  }

  Future<List<ClientModel>> searchClients(String query) async {
    final response = await _client
        .from('clientes')
        .select()
        .ilike('nombre', '%$query%')
        .order('nombre');
    return (response as List)
        .map((json) => ClientModel.fromJson(json))
        .toList();
  }

  Future<void> createClient(ClientModel client) async {
    await _client.from('clientes').insert(client.toJson());
  }

  Future<void> updateClient(String id, ClientModel client) async {
    await _client.from('clientes').update(client.toJson()).eq('id', id);
  }

  Future<void> deleteClient(String id) async {
    await _client.from('clientes').delete().eq('id', id);
  }

  Future<ClientModel?> getClient(String id) async {
    final response =
        await _client.from('clientes').select().eq('id', id).single();
    return ClientModel.fromJson(response);
  }
}
