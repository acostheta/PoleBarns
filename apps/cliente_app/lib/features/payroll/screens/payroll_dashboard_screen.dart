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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: summaryAsync.when(
        data: (data) => _buildDashboard(context, data, ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildDashboard(
      BuildContext context, PayrollSummaryData data, WidgetRef ref) {
    final currencyFormatter =
        NumberFormat.currency(symbol: r'$', decimalDigits: 2);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
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
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
              Row(
                children: [
                  _buildPeriodDropdown(),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showNewPaymentDialog(context),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Nuevo Pago',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706), // Orange-ish
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Total Card
          _buildMainTotalCard(context, data.totalPagado, currencyFormatter),
          const SizedBox(height: 24),

          // Categories Grid
          Row(
            children: [
              Expanded(
                child: _buildCategoryCard(
                  context,
                  'Diario',
                  data.diarioTotal,
                  Icons.calendar_today_outlined,
                  const Color(0xFFFFF7ED),
                  const Color(0xFFEA580C),
                  () => _navigateToDetail(context, 0),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildCategoryCard(
                  context,
                  'Destajo',
                  data.destajoTotal,
                  Icons.inventory_2_outlined,
                  const Color(0xFFF0FDF4),
                  const Color(0xFF16A34A),
                  () => _navigateToDetail(context, 1),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildCategoryCard(
                  context,
                  'Instalación',
                  data.instalacionTotal,
                  Icons.build_outlined,
                  const Color(0xFFEFF6FF),
                  const Color(0xFF2563EB),
                  () => _navigateToDetail(context, 2),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildCategoryCard(
                  context,
                  'Por Hora',
                  data.porHoraTotal,
                  Icons.access_time_outlined,
                  const Color(0xFFF5F3FF),
                  const Color(0xFF7C3AED),
                  () => _navigateToDetail(context, 3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Recent Transactions
          _buildRecentTransactionsTable(context, data.recentTransactions, currencyFormatter),
        ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Pagado por Nómina (Este Mes)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            formatter.format(total),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: const Color(0xFF92400E), // Amber-800
                  fontWeight: FontWeight.bold,
                  fontSize: 48,
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
              1: FlexColumnWidth(2),   // Empleado
              2: FlexColumnWidth(1.5), // Tipo
              3: FlexColumnWidth(2),   // Proyecto
              4: FlexColumnWidth(1.2), // Monto
            },
            children: [
              // Header
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                children: [
                  _buildTableCell('Fecha', isHeader: true),
                  _buildTableCell('Empleado/Equipo', isHeader: true),
                  _buildTableCell('Tipo de Nómina', isHeader: true),
                  _buildTableCell('Proyecto', isHeader: true),
                  _buildTableCell('Monto', isHeader: true, isNumeric: true),
                ],
              ),
              // Body
              ...transactions.map((tx) {
                return TableRow(
                  children: [
                    _buildTableCell(DateFormat('yyyy-MM-dd').format(tx.fecha)),
                    _buildTableCell(tx.empleadoName ?? 'Usuario', isBold: true),
                    _buildTipoPill(tx.tipo),
                    _buildTableCell(tx.proyectoName ?? '-'),
                    _buildTableCell(formatter.format(tx.monto), isBold: true, isNumeric: true),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
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

  void _showNewPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Registro de Nómina'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Pago Diario'),
              onTap: () {
                Navigator.pop(context);
                _navigateToDetail(context, 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.construction),
              title: const Text('Soldadores (Destajo)'),
              onTap: () {
                Navigator.pop(context);
                _navigateToDetail(context, 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.home_work),
              title: const Text('Nómina Instalación'),
              onTap: () {
                Navigator.pop(context);
                _navigateToDetail(context, 2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_car),
              title: const Text('Horas Chofer'),
              onTap: () {
                Navigator.pop(context);
                _navigateToDetail(context, 3);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, int initialTab) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Detalles de Nómina')),
          body: DefaultTabController(
            length: 4,
            initialIndex: initialTab,
            child: Column(
              children: [
                const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Pagos Diarios'),
                    Tab(text: 'Soldadores'),
                    Tab(text: 'Instalación'),
                    Tab(text: 'Choferes'),
                  ],
                ),
                const Expanded(
                  child: TabBarView(
                    children: [
                      PagosDiariosScreen(),
                      DestajoSoldadoresScreen(),
                      NominaInstalacionScreen(),
                      NominaChoferScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
