import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payroll_models.dart';
import '../../settings/models/truss_model.dart';

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

  Stream<NominaPagoDiario?> getPagoDiarioStreamById(String id) {
    return _client
        .from('nomina_pagos_diarios')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) =>
            data.isEmpty ? null : NominaPagoDiario.fromJson(data.first));
  }

  // --- Soldadores ---
  Stream<List<NominaSoldador>> getSoldadoresStream() {
    return _client
        .from('nomina_soldadores')
        .stream(primaryKey: ['id'])
        .order('fecha', ascending: false)
        .map((data) =>
            data.map((json) => NominaSoldador.fromJson(json)).toList());
  }

  Future<String> createSoldador(NominaSoldador item) async {
    final response = await _client
        .from('nomina_soldadores')
        .insert(item.toJson())
        .select('id')
        .maybeSingle();

    if (response == null) {
      throw Exception('Error creating soldador record');
    }

    return response['id'].toString();
  }

  Future<void> updateSoldador(String id, NominaSoldador item) async {
    await _client.from('nomina_soldadores').update(item.toJson()).eq('id', id);
  }

  Future<void> deleteSoldador(String id) async {
    await _client.from('nomina_soldadores').delete().eq('id', id);
  }

  Stream<NominaSoldador?> getSoldadorStream(String id) {
    return _client
        .from('nomina_soldadores')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) =>
            data.isEmpty ? null : NominaSoldador.fromJson(data.first));
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

  Stream<NominaChofer?> getChoferStreamById(String id) {
    return _client
        .from('nomina_horas_chofer')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) => data.isEmpty ? null : NominaChofer.fromJson(data.first));
  }

  Stream<NominaInstalacion?> getInstalacionStreamById(String id) {
    return _client
        .from('nomina_instalacion')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) =>
            data.isEmpty ? null : NominaInstalacion.fromJson(data.first));
  }

  // --- Employees (Profiles) ---
  Stream<List<Map<String, dynamic>>> getEmployeesStream() {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id']).order('full_name', ascending: true);
  }

  // --- Pagos de Nómina ---
  Stream<List<NominaPago>> getPaymentsStream() {
    return _client
        .from('nomina_pagos')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => NominaPago.fromJson(json)).toList());
  }

  Future<void> createPayment(NominaPago item) async {
    await _client.from('nomina_pagos').insert(item.toJson());
  }

  Future<void> deletePayment(String id) async {
    await _client.from('nomina_pagos').delete().eq('id', id);
  }

  Future<void> updatePayment(String id, NominaPago item) async {
    await _client.from('nomina_pagos').update({
      'amount': item.amount,
      'metodo_pago': item.metodoPago,
      'category': item.category,
      'nota': item.nota,
      'fecha_pago': item.fechaPago?.toIso8601String().split('T')[0],
    }).eq('id', id);
  }

  Stream<List<NominaPago>> getPaymentsForSoldador(String soldadorId) {
    return _client
        .from('nomina_pagos')
        .stream(primaryKey: ['id'])
        .eq('id_nomina_soldadura', soldadorId)
        .map((data) => data.map((json) => NominaPago.fromJson(json)).toList());
  }

  Stream<List<NominaPago>> getPaymentsForInstalacion(String instalacionId) {
    return _client
        .from('nomina_pagos')
        .stream(primaryKey: ['id'])
        .eq('id_nomina_instalacion', instalacionId)
        .map((data) => data.map((json) => NominaPago.fromJson(json)).toList());
  }

  Stream<List<NominaPago>> getPaymentsForPagoDiario(String pagoDiarioId) {
    return _client
        .from('nomina_pagos')
        .stream(primaryKey: ['id'])
        .eq('id_nomina_pago_diario', pagoDiarioId)
        .map((data) => data.map((json) => NominaPago.fromJson(json)).toList());
  }

  Stream<List<NominaPago>> getPaymentsForChofer(String choferId) {
    return _client
        .from('nomina_pagos')
        .stream(primaryKey: ['id'])
        .eq('id_nomina_chofer', choferId)
        .map((data) => data.map((json) => NominaPago.fromJson(json)).toList());
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
        .stream(primaryKey: ['id']).order('address', ascending: true);
  }

  Stream<List<Map<String, dynamic>>> getPoleBarnsStream() {
    return _client
        .from('PoleBarns')
        .stream(primaryKey: ['id']).order('name', ascending: true);
  }

  // --- Specific Trusses (Trazabilidad) ---
  Future<void> createSpecificTrusses(
      String nominaSoldadorId, List<Map<String, dynamic>> trusses) async {
    final trussesData = trusses
        .map((t) => {
              'nomina_soldador_id': nominaSoldadorId,
              'truss_id': t['truss_id'],
              'truss_name': t['truss_name'],
              'quantity': t['quantity'],
              'unit_price': t['unit_price'],
            })
        .toList();

    await _client.from('specific_trusses').insert(trussesData);
  }

  Future<List<SpecificTruss>> getSpecificTrussesBySoldador(
      String nominaSoldadorId) async {
    final data = await _client
        .from('specific_trusses')
        .select()
        .eq('nomina_soldador_id', nominaSoldadorId)
        .order('created_at');
    return (data as List).map((e) => SpecificTruss.fromJson(e)).toList();
  }

  Stream<List<SpecificTruss>> getSpecificTrussesBySoldadorStream(
      String nominaSoldadorId) {
    return _client
        .from('specific_trusses')
        .stream(primaryKey: ['id'])
        .eq('nomina_soldador_id', nominaSoldadorId)
        .order('created_at')
        .map((data) =>
            (data as List).map((e) => SpecificTruss.fromJson(e)).toList());
  }

  Future<void> deleteSpecificTrussesBySoldador(String nominaSoldadorId) async {
    await _client
        .from('specific_trusses')
        .delete()
        .eq('nomina_soldador_id', nominaSoldadorId);
  }
}
