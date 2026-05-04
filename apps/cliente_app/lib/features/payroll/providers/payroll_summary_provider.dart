import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/payroll_repository.dart';

class PayrollSummaryData {
  final double totalPagado;
  final double diarioTotal;
  final double soldadoresTotal;
  final double instalacionTotal;
  final double porHoraTotal;
  final List<PayrollTransaction> recentTransactions;

  PayrollSummaryData({
    required this.totalPagado,
    required this.diarioTotal,
    required this.soldadoresTotal,
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
  final String tipo; // 'Diario', 'Soldadores', 'Instalación', 'Por Hora'
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
final paymentsPayrollProvider = StreamProvider(
    (ref) => ref.watch(payrollRepositoryProvider).getPaymentsStream());

final payrollPeriodFilterProvider = StateProvider<String>((ref) => 'Todos');

bool isDateInFilterRange(DateTime? date, String periodFilter) {
  if (date == null) return false;

  final now = DateTime.now();

  if (periodFilter == 'Hoy') {
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  } else if (periodFilter == 'Esta Semana') {
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDate =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeekDate = startOfWeekDate.add(const Duration(days: 7));
    return date.isAfter(startOfWeekDate.subtract(const Duration(milliseconds: 1))) &&
           date.isBefore(endOfWeekDate);
  } else if (periodFilter == 'Este Mes') {
    return date.year == now.year && date.month == now.month;
  }
  
  return true; // Todos
}

final combinedPayrollSummaryProvider =
    Provider<AsyncValue<PayrollSummaryData>>((ref) {
  final diarioAsync = ref.watch(pagosDiariosProvider);
  final soldadoresAsync = ref.watch(soldadoresProvider);
  final instalacionAsync = ref.watch(instalacionProvider);
  final choferAsync = ref.watch(choferProvider);
  final paymentsPayrollAsync = ref.watch(paymentsPayrollProvider);
  final employeesAsync = ref.watch(employeesProvider);
  final projectsAsync = ref.watch(projectsProvider);

  if (diarioAsync is AsyncLoading ||
      soldadoresAsync is AsyncLoading ||
      instalacionAsync is AsyncLoading ||
      choferAsync is AsyncLoading ||
      paymentsPayrollAsync is AsyncLoading ||
      employeesAsync is AsyncLoading ||
      projectsAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }

  final periodFilter = ref.watch(payrollPeriodFilterProvider);

  // Data
  final diarioRaw = diarioAsync.value ?? [];
  final soldadoresRaw = soldadoresAsync.value ?? [];
  final instalacionRaw = instalacionAsync.value ?? [];
  final choferRaw = choferAsync.value ?? [];
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
  final diarioThisMonth = diarioRaw.where((i) => isDateInFilterRange(i.fecha, periodFilter)).toList();
  double totalDiario =
      diarioThisMonth.fold(0, (sum, item) => sum + (item.monto ?? 0));

  // 2. Choferes
  final choferThisMonth = choferRaw.where((i) => isDateInFilterRange(i.fecha, periodFilter)).toList();
  double totalChofer =
      choferThisMonth.fold(0, (sum, item) => sum + (item.total ?? 0));

  // 3. Piecework (Soldadores & Instalación)
  final soldadoresThisMonth =
      soldadoresRaw.where((i) => isDateInFilterRange(i.fecha, periodFilter)).toList();
  double totalSoldadores =
      soldadoresThisMonth.fold(0, (sum, item) => sum + (item.total ?? 0));

  final instalacionThisMonth = instalacionRaw
      .where(
          (i) => i.fechaCulminacion != null && isDateInFilterRange(i.fechaCulminacion, periodFilter))
      .toList();
  double totalInstalacion = instalacionThisMonth.fold(
      0, (sum, item) => sum + (item.pagoProyecto ?? 0));

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

  for (var item in soldadoresThisMonth) {
    transactions.add(PayrollTransaction(
      id: item.id,
      fecha: item.fecha,
      empleadoId: item.idEmpleado,
      empleadoName: employeesMap[item.idEmpleado],
      tipo: 'Soldadores',
      monto: item.total ?? 0,
    ));
  }

  for (var item in instalacionThisMonth) {
    transactions.add(PayrollTransaction(
      id: item.id,
      fecha: item.fechaCulminacion!,
      empleadoId: item.idEmpleado,
      empleadoName: employeesMap[item.idEmpleado],
      tipo: 'Instalación',
      proyectoId: item.idProyecto,
      proyectoName: projectsMap[item.idProyecto],
      monto: item.pagoProyecto ?? 0,
    ));
  }

  transactions.sort((a, b) => b.fecha.compareTo(a.fecha));

  return AsyncValue.data(PayrollSummaryData(
    totalPagado: totalDiario + totalChofer + totalSoldadores + totalInstalacion,
    diarioTotal: totalDiario,
    soldadoresTotal: totalSoldadores,
    instalacionTotal: totalInstalacion,
    porHoraTotal: totalChofer,
    recentTransactions: transactions.take(10).toList(),
  ));
});
