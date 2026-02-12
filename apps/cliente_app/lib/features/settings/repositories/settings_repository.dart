import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/provider_model.dart';
import '../models/payment_method_model.dart';
import '../models/truss_model.dart';

final settingsRepositoryProvider = Provider((ref) => SettingsRepository());

class SettingsRepository {
  final _client = Supabase.instance.client;

  // Providers
  Future<List<ProviderModel>> getProviders() async {
    final data = await _client.from('providers').select().order('created_at');
    return (data as List).map((e) => ProviderModel.fromJson(e)).toList();
  }

  Future<void> createProvider(String name, String address) async {
    await _client.from('providers').insert({
      'name': name,
      'address': address,
    });
  }

  Future<void> updateProvider(ProviderModel provider) async {
    await _client.from('providers').update({
      'name': provider.name,
      'address': provider.address,
    }).eq('id', provider.id);
  }

  Future<void> deleteProvider(String id) async {
    await _client.from('providers').delete().eq('id', id);
  }

  // Payment Methods
  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    final data =
        await _client.from('payment_methods').select().order('created_at');
    return (data as List).map((e) => PaymentMethodModel.fromJson(e)).toList();
  }

  Future<void> createPaymentMethod(String name,
      {double serviceFee = 0.0}) async {
    await _client.from('payment_methods').insert({
      'name': name,
      'service_fee': serviceFee,
    });
  }

  Future<void> updatePaymentMethod(PaymentMethodModel method) async {
    await _client.from('payment_methods').update({
      'name': method.name,
      'service_fee': method.serviceFee,
    }).eq('id', method.id);
  }

  Future<void> deletePaymentMethod(String id) async {
    await _client.from('payment_methods').delete().eq('id', id);
  }

  // Trusses
  Future<List<Truss>> getTrusses() async {
    final data = await _client.from('trusses').select().order('name');
    return (data as List).map((e) => Truss.fromJson(e)).toList();
  }

  Stream<List<Truss>> getTrussesStream() {
    return _client
        .from('trusses')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((data) => (data as List).map((e) => Truss.fromJson(e)).toList());
  }

  Future<void> createTruss(String name, double cost) async {
    await _client.from('trusses').insert({
      'name': name,
      'cost': cost,
    });
  }

  Future<void> updateTruss(Truss truss) async {
    await _client.from('trusses').update({
      'name': truss.name,
      'cost': truss.cost,
    }).eq('id', truss.id);
  }

  Future<void> deleteTruss(String id) async {
    await _client.from('trusses').delete().eq('id', id);
  }
}

// Providers for State Management
final providersListProvider = FutureProvider<List<ProviderModel>>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.getProviders();
});

final paymentMethodsListProvider =
    FutureProvider<List<PaymentMethodModel>>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.getPaymentMethods();
});

final trussesListProvider = FutureProvider<List<Truss>>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.getTrusses();
});
