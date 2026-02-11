import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/payroll_repository.dart';

class PayrollSummaryData {
  final double totalPagado;
  final double diarioTotal;
  final double destajoTotal;
  final double instalacionTotal;
  final double porHoraTotal;
  final List<PayrollTransaction> recentTransactions;

  PayrollSummaryData({
    required this.totalPagado,
    required this.diarioTotal,
    required this.destajoTotal,
    required this.instalacionTotal,
    required this.porHoraTotal,
    required this.recentTransactions,
  });
}

class PayrollTransaction {
  final String id;
  final DateTime fecha;
  final String empleadoId;
  final String? empleadoName;
  final String tipo; // 'Diario', 'Destajo', 'Instalación', 'Por Hora'
  final String? proyectoId;
  final String? proyectoName;
  final double monto;

  PayrollTransaction({
    required this.id,
    required this.fecha,
    required this.empleadoId,
    this.empleadoName,
    required this.tipo,
    this.proyectoId,
    this.proyectoName,
    required this.monto,
  });
}

// Base Providers
final pagosDiariosProvider = StreamProvider(
    (ref) => ref.watch(payrollRepositoryProvider).getPagosDiariosStream());
final soldadoresProvider = StreamProvider(
    (ref) => ref.watch(payrollRepositoryProvider).getSoldadoresStream());
final instalacionProvider = StreamProvider(
    (ref) => ref.watch(payrollRepositoryProvider).getInstalacionStream());
final choferProvider = StreamProvider(
    (ref) => ref.watch(payrollRepositoryProvider).getChoferStream());
final employeesProvider = StreamProvider(
    (ref) => ref.watch(payrollRepositoryProvider).getEmployeesStream());
final projectsProvider = StreamProvider(
    (ref) => ref.watch(payrollRepositoryProvider).getProjectsStream());
final paymentsDestajoProvider = StreamProvider(
    (ref) => ref.watch(payrollRepositoryProvider).getPaymentsDestajoStream());

final combinedPayrollSummaryProvider =
    Provider<AsyncValue<PayrollSummaryData>>((ref) {
  final diarioAsync = ref.watch(pagosDiariosProvider);
  final soldadoresAsync = ref.watch(soldadoresProvider);
  final instalacionAsync = ref.watch(instalacionProvider);
  final choferAsync = ref.watch(choferProvider);
  final paymentsDestajoAsync = ref.watch(paymentsDestajoProvider);
  final employeesAsync = ref.watch(employeesProvider);
  final projectsAsync = ref.watch(projectsProvider);

  if (diarioAsync is AsyncLoading ||
      soldadoresAsync is AsyncLoading ||
      instalacionAsync is AsyncLoading ||
      choferAsync is AsyncLoading ||
      paymentsDestajoAsync is AsyncLoading ||
      employeesAsync is AsyncLoading ||
      projectsAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }

  final now = DateTime.now();
  bool isThisMonth(DateTime? date) {
    if (date == null) return false;
    return date.year == now.year && date.month == now.month;
  }

  // Data
  final diarioRaw = diarioAsync.value ?? [];
  final soldadoresRaw = soldadoresAsync.value ?? [];
  final instalacionRaw = instalacionAsync.value ?? [];
  final choferRaw = choferAsync.value ?? [];
  final paymentsDestajoRaw = paymentsDestajoAsync.value ?? [];
  final employees = employeesAsync.value ?? [];
  final projects = projectsAsync.value ?? [];

  final employeesMap = {
    for (var e in employees)
      e['id'].toString(): (e['full_name'] ?? e['name'])?.toString() ?? 'N/A'
  };
  final projectsMap = {
    for (var p in projects)
      p['id'] as String: p['address'] as String? ?? 'Desconocido'
  };

  // --- Calculations (Filtered by Month) ---

  // 1. Diario
  final diarioThisMonth = diarioRaw.where((i) => isThisMonth(i.fecha)).toList();
  double totalDiario =
      diarioThisMonth.fold(0, (sum, item) => sum + (item.monto ?? 0));

  // 2. Choferes
  final choferThisMonth = choferRaw.where((i) => isThisMonth(i.fecha)).toList();
  double totalChofer =
      choferThisMonth.fold(0, (sum, item) => sum + (item.total ?? 0));

  // 3. Piecework (Destajo Soldadores & Instalación)
  // We sum records from 'payment_destajo' table as requested.
  final paymentsThisMonth =
      paymentsDestajoRaw.where((p) => isThisMonth(p.createdAt)).toList();

  double totalDestajo = 0;
  double totalInstalacion = 0;

  for (var p in paymentsThisMonth) {
    if (p.tipo == 'Soldadura') {
      totalDestajo += p.amount;
    } else if (p.tipo == 'Instalación') {
      totalInstalacion += p.amount;
    }
  }

  // Transactions list (Recent 10)
  List<PayrollTransaction> transactions = [];

  for (var item in diarioThisMonth) {
    transactions.add(PayrollTransaction(
      id: item.id,
      fecha: item.fecha,
      empleadoId: item.idEmpleado,
      empleadoName: employeesMap[item.idEmpleado],
      tipo: 'Diario',
      monto: item.monto ?? 0,
    ));
  }

  for (var item in choferThisMonth) {
    transactions.add(PayrollTransaction(
      id: item.id,
      fecha: item.fecha,
      empleadoId: item.idEmpleado,
      empleadoName: employeesMap[item.idEmpleado],
      tipo: 'Por Hora',
      monto: item.total ?? 0,
    ));
  }

  // For Soldadura/Instalacion transactions, we can show either the parent record or individual payments.
  // User image showed "Equipo A - Diario", "Carlos Perez - Destajo".
  // Let's show the parent records that had activity this month.
  for (var item in soldadoresRaw) {
    if (isThisMonth(item.fecha) && (item.pagoParcial ?? 0) > 0) {
      transactions.add(PayrollTransaction(
        id: item.id,
        fecha: item.fecha,
        empleadoId: item.idEmpleado,
        empleadoName: employeesMap[item.idEmpleado],
        tipo: 'Destajo',
        monto: item.pagoParcial ?? 0,
      ));
    }
  }

  for (var item in instalacionRaw) {
    if (isThisMonth(item.fechaCulminacion) && (item.pagoParcial ?? 0) > 0) {
      transactions.add(PayrollTransaction(
        id: item.id,
        fecha: item.fechaCulminacion!,
        empleadoId: item.idEmpleado,
        empleadoName: employeesMap[item.idEmpleado],
        tipo: 'Instalación',
        proyectoId: item.idProyecto,
        proyectoName: projectsMap[item.idProyecto],
        monto: item.pagoParcial ?? 0,
      ));
    }
  }

  transactions.sort((a, b) => b.fecha.compareTo(a.fecha));

  return AsyncValue.data(PayrollSummaryData(
    totalPagado: totalDiario + totalChofer + totalDestajo + totalInstalacion,
    diarioTotal: totalDiario,
    destajoTotal: totalDestajo,
    instalacionTotal: totalInstalacion,
    porHoraTotal: totalChofer,
    recentTransactions: transactions.take(10).toList(),
  ));
});
