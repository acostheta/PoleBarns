import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payroll_models.dart';

final payrollRepositoryProvider = Provider((ref) => PayrollRepository());

class PayrollRepository {
  final _client = Supabase.instance.client;

  // --- Pagos Diarios ---
  Stream<List<NominaPagoDiario>> getPagosDiariosStream() {
    return _client
        .from('nomina_pagos_diarios')
        .stream(primaryKey: ['id'])
        .order('fecha', ascending: false)
        .map((data) =>
            data.map((json) => NominaPagoDiario.fromJson(json)).toList());
  }

  Future<void> createPagoDiario(NominaPagoDiario item) async {
    await _client.from('nomina_pagos_diarios').insert(item.toJson());
  }

  Future<void> updatePagoDiario(String id, NominaPagoDiario item) async {
    await _client
        .from('nomina_pagos_diarios')
        .update(item.toJson())
        .eq('id', id);
  }

  Future<void> deletePagoDiario(String id) async {
    await _client.from('nomina_pagos_diarios').delete().eq('id', id);
  }

  // --- Soldadores (Destajo) ---
  Stream<List<NominaDestajoSoldador>> getSoldadoresStream() {
    return _client
        .from('nomina_destajo_soldadores')
        .stream(primaryKey: ['id'])
        .order('fecha', ascending: false)
        .map((data) =>
            data.map((json) => NominaDestajoSoldador.fromJson(json)).toList());
  }

  Future<void> createSoldador(NominaDestajoSoldador item) async {
    await _client.from('nomina_destajo_soldadores').insert(item.toJson());
  }

  Future<void> updateSoldador(String id, NominaDestajoSoldador item) async {
    await _client
        .from('nomina_destajo_soldadores')
        .update(item.toJson())
        .eq('id', id);
  }

  Future<void> deleteSoldador(String id) async {
    await _client.from('nomina_destajo_soldadores').delete().eq('id', id);
  }

  // --- Instalacion ---
  Stream<List<NominaInstalacion>> getInstalacionStream() {
    return _client.from('nomina_instalacion').stream(primaryKey: ['id']).map(
        (data) =>
            data.map((json) => NominaInstalacion.fromJson(json)).toList());
  }

  Future<void> createInstalacion(NominaInstalacion item) async {
    await _client.from('nomina_instalacion').insert(item.toJson());
  }

  Future<void> updateInstalacion(String id, NominaInstalacion item) async {
    await _client.from('nomina_instalacion').update(item.toJson()).eq('id', id);
  }

  Future<void> deleteInstalacion(String id) async {
    await _client.from('nomina_instalacion').delete().eq('id', id);
  }

  // --- Chofer ---
  Stream<List<NominaChofer>> getChoferStream() {
    return _client
        .from('nomina_horas_chofer')
        .stream(primaryKey: ['id'])
        .order('fecha', ascending: false)
        .map(
            (data) => data.map((json) => NominaChofer.fromJson(json)).toList());
  }

  Future<void> createChofer(NominaChofer item) async {
    await _client.from('nomina_horas_chofer').insert(item.toJson());
  }

  Future<void> updateChofer(String id, NominaChofer item) async {
    await _client
        .from('nomina_horas_chofer')
        .update(item.toJson())
        .eq('id', id);
  }

  Future<void> deleteChofer(String id) async {
    await _client.from('nomina_horas_chofer').delete().eq('id', id);
  }

  // --- Employees (Profiles) ---
  Stream<List<Map<String, dynamic>>> getEmployeesStream() {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id']).order('full_name', ascending: true);
  }

  // --- Payment Destajo ---
  Future<void> createPaymentDestajo(PaymentDestajo item) async {
    await _client.from('payment_destajo').insert(item.toJson());
  }

  Stream<List<PaymentDestajo>> getPaymentsForSoldador(String soldadorId) {
    return _client
        .from('payment_destajo')
        .stream(primaryKey: ['id'])
        .eq('id_nomina_soldadura', soldadorId)
        .map((data) =>
            data.map((json) => PaymentDestajo.fromJson(json)).toList());
  }

  Stream<List<PaymentDestajo>> getPaymentsForInstalacion(String instalacionId) {
    return _client
        .from('payment_destajo')
        .stream(primaryKey: ['id'])
        .eq('id_nomina_instalacion', instalacionId)
        .map((data) =>
            data.map((json) => PaymentDestajo.fromJson(json)).toList());
  }

  // --- Catalog/Reference Streams ---
  Stream<List<Map<String, dynamic>>> getRawMaterialsStream() {
    return _client
        .from('raw_materials')
        .stream(primaryKey: ['id']).order('name', ascending: true);
  }

  Stream<List<Map<String, dynamic>>> getProjectsStream() {
    return _client
        .from('projects')
        .stream(primaryKey: ['id']).order('name', ascending: true);
  }

  Stream<List<Map<String, dynamic>>> getPoleBarnsStream() {
    return _client
        .from('PoleBarns')
        .stream(primaryKey: ['id']).order('name', ascending: true);
  }
}
