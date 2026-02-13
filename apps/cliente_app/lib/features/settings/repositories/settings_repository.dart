import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/provider_model.dart';
import '../models/payment_method_model.dart';
import '../models/truss_model.dart';
import '../models/lean_to_model.dart';

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

  // Lean To
  Future<List<LeanTo>> getLeanTos() async {
    final data = await _client.from('lean_to').select().order('name');
    return (data as List).map((e) => LeanTo.fromJson(e)).toList();
  }

  Stream<List<LeanTo>> getLeanTosStream() {
    return _client
        .from('lean_to')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((data) => (data as List).map((e) => LeanTo.fromJson(e)).toList());
  }

  Future<void> createLeanTo(String name, double cost) async {
    await _client.from('lean_to').insert({
      'name': name,
      'cost': cost,
    });
  }

  Future<void> updateLeanTo(LeanTo leanTo) async {
    await _client.from('lean_to').update({
      'name': leanTo.name,
      'cost': leanTo.cost,
    }).eq('id', leanTo.id);
  }

  Future<void> deleteLeanTo(String id) async {
    await _client.from('lean_to').delete().eq('id', id);
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

final leanTosListProvider = FutureProvider<List<LeanTo>>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.getLeanTos();
});

class ProductItem {
  final String id;
  final String name;
  final double cost;
  final String type; // 'truss' or 'lean_to'

  ProductItem({
    required this.id,
    required this.name,
    required this.cost,
    required this.type,
  });
}

// Combined stream
final allProductsStreamProvider = StreamProvider<List<ProductItem>>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);

  Stream<List<Truss>> trussesStream = repo.getTrussesStream();
  Stream<List<LeanTo>> leanTosStream = repo.getLeanTosStream();

  return Stream<List<ProductItem>>.multi((controller) {
    List<Truss> currentTrusses = [];
    List<LeanTo> currentLeanTos = [];

    void update() {
      // Create combined list
      final combined = <ProductItem>[
        ...currentTrusses.map((t) =>
            ProductItem(id: t.id, name: t.name, cost: t.cost, type: 'truss')),
        ...currentLeanTos.map((l) =>
            ProductItem(id: l.id, name: l.name, cost: l.cost, type: 'lean_to')),
      ];
      combined.sort((a, b) => a.name.compareTo(b.name));
      controller.add(combined);
    }

    final sub1 = trussesStream.listen((data) {
      currentTrusses = data;
      update();
    });

    final sub2 = leanTosStream.listen((data) {
      currentLeanTos = data;
      update();
    });

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
    };
  });
});
