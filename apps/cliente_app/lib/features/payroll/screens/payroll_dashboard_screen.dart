import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/payroll_summary_provider.dart';
import 'pagos_diarios_screen.dart';
import 'destajo_soldadores_screen.dart';
import 'nomina_instalacion_screen.dart';
import 'nomina_chofer_screen.dart';

class PayrollDashboardScreen extends ConsumerWidget {
  const PayrollDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(combinedPayrollSummaryProvider);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Nómina',
              style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Color(0xFFD97706),
            unselectedLabelColor: Color(0xFF64748B),
            indicatorColor: Color(0xFFD97706),
            tabs: [
              Tab(text: 'Dashboard'),
              Tab(text: 'Diario'),
              Tab(text: 'Destajo'),
              Tab(text: 'Instalación'),
              Tab(text: 'Chofer'),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: () => _showUnifiedCreationDialog(context),
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text('Nuevo Pago',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Dashboard Tab
            summaryAsync.when(
              data: (data) => _buildDashboardTab(context, data, ref),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
            // Other Tabs
            const PagosDiariosScreen(),
            const DestajoSoldadoresScreen(),
            const NominaInstalacionScreen(),
            const NominaChoferScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab(
      BuildContext context, PayrollSummaryData data, WidgetRef ref) {
    final currencyFormatter =
        NumberFormat.currency(symbol: r'$', decimalDigits: 2);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen General de Nómina',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vista general de todos los pagos de nómina.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF64748B),
                            ),
                      ),
                    ],
                  ),
                  _buildPeriodDropdown(),
                ],
              ),
              const SizedBox(height: 32),

              // NEW LAYOUT: 3 Columns
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Col 1
                    Expanded(
                      flex: 3,
                      child: _buildMainTotalCard(
                          context, data.totalPagado, currencyFormatter),
                    ),
                    const SizedBox(width: 24),

                    // Col 2
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Expanded(
                            child: _buildCategoryCard(
                              context,
                              'Diario',
                              data.diarioTotal,
                              Icons.calendar_today_outlined,
                              const Color(0xFFFFF7ED),
                              const Color(0xFFEA580C),
                              () =>
                                  DefaultTabController.of(context).animateTo(1),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: _buildCategoryCard(
                              context,
                              'Instalación',
                              data.instalacionTotal,
                              Icons.build_outlined,
                              const Color(0xFFEFF6FF),
                              const Color(0xFF2563EB),
                              () =>
                                  DefaultTabController.of(context).animateTo(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Col 3
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Expanded(
                            child: _buildCategoryCard(
                              context,
                              'Destajo',
                              data.destajoTotal,
                              Icons.inventory_2_outlined,
                              const Color(0xFFF0FDF4),
                              const Color(0xFF16A34A),
                              () =>
                                  DefaultTabController.of(context).animateTo(2),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: _buildCategoryCard(
                              context,
                              'Por Hora',
                              data.porHoraTotal,
                              Icons.access_time_outlined,
                              const Color(0xFFF5F3FF),
                              const Color(0xFF7C3AED),
                              () =>
                                  DefaultTabController.of(context).animateTo(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Recent Transactions
              _buildRecentTransactionsTable(
                  context, data.recentTransactions, currencyFormatter),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainTotalCard(
      BuildContext context, double total, NumberFormat formatter) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Pagado por Nómina (Este Mes)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 24),
          Text(
            formatter.format(total),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: const Color(0xFF92400E),
                  fontWeight: FontWeight.bold,
                  fontSize: 64,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    double amount,
    IconData icon,
    Color bgColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    final currencyFormatter =
        NumberFormat.currency(symbol: r'$', decimalDigits: 2);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  currencyFormatter.format(amount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: 'Este Mes',
          items: const [
            DropdownMenuItem(value: 'Este Mes', child: Text('Este Mes')),
            DropdownMenuItem(value: 'Hoy', child: Text('Hoy')),
            DropdownMenuItem(value: 'Esta Semana', child: Text('Esta Semana')),
          ],
          onChanged: (v) {},
        ),
      ),
    );
  }

  void _showUnifiedCreationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UnifiedPayrollDialog(),
    );
  }

  Widget _buildRecentTransactionsTable(BuildContext context,
      List<PayrollTransaction> transactions, NumberFormat formatter) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Transacciones Recientes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
            ),
          ),
          const Divider(height: 1),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.2), // Fecha
              1: FlexColumnWidth(2), // Empleado
              2: FlexColumnWidth(1.5), // Tipo
              3: FlexColumnWidth(1.2), // Monto
            },
            children: [
              // Header
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                children: [
                  _buildTableCell('Fecha', isHeader: true),
                  _buildTableCell('Empleado/Equipo', isHeader: true),
                  _buildTableCell('Tipo de Nómina', isHeader: true),
                  _buildTableCell('Monto', isHeader: true, isNumeric: true),
                ],
              ),
              // Body
              if (transactions.isEmpty)
                const TableRow(children: [
                  TableCell(child: SizedBox(height: 24)),
                  TableCell(child: SizedBox(height: 24)),
                  TableCell(child: SizedBox(height: 24)),
                  TableCell(child: SizedBox(height: 24)),
                ]),

              ...transactions.map((tx) {
                return TableRow(
                  children: [
                    _buildTableCell(DateFormat('yyyy-MM-dd').format(tx.fecha)),
                    _buildTableCell(tx.empleadoName ?? 'Usuario', isBold: true),
                    _buildTipoPill(tx.tipo),
                    _buildTableCell(formatter.format(tx.monto),
                        isBold: true, isNumeric: true),
                  ],
                );
              }),
            ],
          ),
          if (transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                  child: Text('No hay transacciones recientes',
                      style: TextStyle(color: Color(0xFF64748B)))),
            ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text,
      {bool isHeader = false, bool isBold = false, bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        textAlign: isNumeric ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontWeight: isHeader || isBold ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? const Color(0xFF64748B) : const Color(0xFF1E293B),
          fontSize: isHeader ? 12 : 14,
        ),
      ),
    );
  }

  Widget _buildTipoPill(String tipo) {
    Color bgColor;
    Color textColor;

    switch (tipo) {
      case 'Diario':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        break;
      case 'Destajo':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF166534);
        break;
      case 'Instalación':
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF1E40AF);
        break;
      case 'Por Hora':
        bgColor = const Color(0xFFEDE9FE);
        textColor = const Color(0xFF5B21B6);
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: bgColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            tipo,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class UnifiedPayrollDialog extends StatelessWidget {
  const UnifiedPayrollDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
        child: DefaultTabController(
          length: 4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nuevo Registro de Nómina',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Container(
                color: const Color(0xFFF8FAFC),
                child: const TabBar(
                  labelColor: Color(0xFFD97706),
                  unselectedLabelColor: Color(0xFF64748B),
                  indicatorColor: Color(0xFFD97706),
                  tabs: [
                    Tab(text: 'Diario'),
                    Tab(text: 'Destajo'),
                    Tab(text: 'Instalación'),
                    Tab(text: 'Chofer'),
                  ],
                ),
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(24.0),
                      child: PagoDiarioForm(),
                    ),
                    Padding(
                      padding: EdgeInsets.all(24.0),
                      child: SoldadorForm(),
                    ),
                    Padding(
                      padding: EdgeInsets.all(24.0),
                      child: InstalacionForm(),
                    ),
                    Padding(
                      padding: EdgeInsets.all(24.0),
                      child: ChoferForm(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
