import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/app_styles.dart';
import '../providers/accounts_payable_provider.dart';
import '../models/account_payable_model.dart';
import '../widgets/add_account_dialog.dart';

import '../widgets/account_payable_detail_view.dart';

class AccountsPayableScreen extends ConsumerStatefulWidget {
  const AccountsPayableScreen({super.key});

  @override
  ConsumerState<AccountsPayableScreen> createState() =>
      _AccountsPayableScreenState();
}

class _AccountsPayableScreenState extends ConsumerState<AccountsPayableScreen> {
  // Sorting
  int _sortColumnIndex = 2; // Default by Date
  bool _isAscending = false; // Default Descending (newest first)

  // Pagination
  final int _rowsPerPage = 10;
  int _currentPage = 0;

  // Filters
  String _statusFilter = 'Todos';
  DateTimeRange? _dateRange;
  String? _providerFilter;
  double? _minBalance;
  bool _onlyDebt = false;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(accountsPayableListProvider);
    final stats = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Cuentas por Pagar',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Dashboard Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: MediaQuery.of(context).size.width < 800
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 220,
                          child: _buildStatCard(
                            context,
                            title: 'TOTAL DEUDA',
                            amount: stats['totalDebt']!,
                            color: Colors.black87,
                            isMoney: true,
                            icon: Icons.receipt_long_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 220,
                          child: _buildStatCard(
                            context,
                            title: 'TOTAL PAGADO',
                            amount: stats['totalPaid']!,
                            color: const Color(0xFF059669),
                            isMoney: true,
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 220,
                          child: _buildStatCard(
                            context,
                            title: 'SALDO PENDIENTE',
                            amount: stats['pendingBalance']!,
                            color: Colors.redAccent,
                            isMoney: true,
                            icon: Icons.pending_actions,
                          ),
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          title: 'TOTAL DEUDA',
                          amount: stats['totalDebt']!,
                          color: Colors.black87,
                          isMoney: true,
                          icon: Icons.receipt_long_outlined,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          title: 'TOTAL PAGADO',
                          amount: stats['totalPaid']!,
                          color: const Color(0xFF059669),
                          isMoney: true,
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          title: 'SALDO PENDIENTE',
                          amount: stats['pendingBalance']!,
                          color: Colors.redAccent,
                          isMoney: true,
                          icon: Icons.pending_actions,
                        ),
                      ),
                    ],
                  ),
          ),

          // Toolbar
          _buildToolbar(context, accountsState.asData?.value),

          // List Container
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: accountsState.when(
                  data: (accounts) {
                    final processedAccounts =
                        _getFilteredAndSortedAccounts(accounts);

                    if (processedAccounts.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay facturas que coincidan con los filtros.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    final totalItems = processedAccounts.length;
                    final totalPages = (totalItems / _rowsPerPage).ceil();
                    if (_currentPage >= totalPages) {
                      _currentPage = totalPages > 0 ? totalPages - 1 : 0;
                    }

                    final startIndex = _currentPage * _rowsPerPage;
                    final endIndex =
                        (startIndex + _rowsPerPage).clamp(0, totalItems);
                    final pagedAccounts =
                        processedAccounts.sublist(startIndex, endIndex);

                    final isMobile = MediaQuery.of(context).size.width < 800;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: isMobile
                              ? _buildMobileList(pagedAccounts)
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                        minWidth:
                                            MediaQuery.of(context).size.width -
                                                48),
                                    child: DataTable(
                                      sortColumnIndex: _sortColumnIndex,
                                      sortAscending: _isAscending,
                                      headingRowColor: WidgetStateProperty.all(
                                          const Color(0xFFF9FAFB)),
                                      headingTextStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                        letterSpacing: 0.5,
                                      ),
                                      dataRowMinHeight: 64,
                                      dataRowMaxHeight: 64,
                                      horizontalMargin: 24,
                                      columnSpacing: 24,
                                      columns: [
                                        DataColumn(
                                            label: const Text('PROVEEDOR'),
                                            onSort: _sort),
                                        const DataColumn(
                                            label: Text('PROYECTO')),
                                        DataColumn(
                                            label: const Text('NRO INVOICE'),
                                            onSort: _sort),
                                        DataColumn(
                                            label: const Text('FECHA'),
                                            onSort: _sort),
                                        DataColumn(
                                            label: const Text('MONTO'),
                                            numeric: true,
                                            onSort: _sort),
                                        DataColumn(
                                            label: const Text('PAGADO'),
                                            numeric: true,
                                            onSort: _sort),
                                        DataColumn(
                                            label: const Text('SALDO'),
                                            numeric: true,
                                            onSort: _sort),
                                        DataColumn(
                                            label: const Text('ESTADO'),
                                            onSort: _sort),
                                        const DataColumn(
                                            label: SizedBox(width: 48)),
                                      ],
                                      rows: pagedAccounts.map((account) {
                                        return DataRow(
                                          onSelectChanged: (_) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => Scaffold(
                                                  appBar: AppBar(
                                                    title: const Text(
                                                        'Detalle de Cuenta'),
                                                    backgroundColor:
                                                        Colors.white,
                                                    foregroundColor:
                                                        Colors.black,
                                                    elevation: 0.5,
                                                  ),
                                                  backgroundColor:
                                                      const Color(0xFFF9FAFB),
                                                  body:
                                                      AccountPayableDetailView(
                                                          accountId:
                                                              account.id),
                                                ),
                                              ),
                                            );
                                          },
                                          cells: [
                                            DataCell(Text(
                                                account.provider?.name ?? 'S/N',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF111827)))),
                                            DataCell(Text(
                                                account.projectName ?? '-',
                                                style: TextStyle(
                                                    color: Colors.blue.shade700,
                                                    fontSize: 12))),
                                            DataCell(Text(
                                                account.invoiceInternRef ?? '-',
                                                style: const TextStyle(
                                                    color: Color(0xFF4B5563)))),
                                            DataCell(Text(
                                                DateFormat('MM/dd/yyyy').format(
                                                    account.invoiceDate),
                                                style: const TextStyle(
                                                    color: Color(0xFF4B5563)))),
                                            DataCell(Text(
                                                NumberFormat.simpleCurrency()
                                                    .format(
                                                        account.totalAmount))),
                                            DataCell(Text(
                                                NumberFormat.simpleCurrency()
                                                    .format(account.totalPaid),
                                                style: const TextStyle(
                                                    color: Color(0xFF059669)))),
                                            DataCell(Text(
                                                NumberFormat.simpleCurrency()
                                                    .format(
                                                        account.currentBalance),
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF111827)))),
                                            DataCell(
                                                _buildStatusBadge(account)),
                                            DataCell(const Icon(
                                                Icons.chevron_right,
                                                color: Colors.grey)),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                        ),
                        _buildPaginationFooter(
                            startIndex, endIndex, totalItems, totalPages),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: $e')),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter(
      int startIndex, int endIndex, int totalItems, int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
              'Mostrando ${startIndex + 1} a $endIndex de $totalItems resultados',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          Row(
            children: [
              _paginationButton(
                  Icons.chevron_left,
                  _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null),
              const SizedBox(width: 8),
              _paginationButton(
                  Icons.chevron_right,
                  _currentPage < totalPages - 1
                      ? () => setState(() => _currentPage++)
                      : null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paginationButton(IconData icon, VoidCallback? onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(6),
          color: onPressed == null ? Colors.transparent : Colors.white,
        ),
        child: Icon(icon,
            size: 20,
            color: onPressed == null ? Colors.grey.shade300 : Colors.black87),
      ),
    );
  }

  Widget _buildToolbar(
      BuildContext context, List<AccountPayableModel>? accounts) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  decoration: AppStyles.inputDecoration(
                          hintText: 'Buscar por proveedor o referencia...')
                      .copyWith(
                    prefixIcon:
                        const Icon(Icons.search, size: 20, color: Colors.grey),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _toolbarButton('Filtrar', Icons.filter_list,
                          () => _showFilterDialog(accounts)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _toolbarButton('Exportar', Icons.download_outlined,
                          () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Función de exportar próximamente')));
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => showDialog(
                      context: context,
                      builder: (_) => const AddAccountDialog()),
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text('Nueva Factura'),
                  style: AppStyles.primaryButtonStyle.copyWith(
                    padding: WidgetStateProperty.all(const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16)),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: AppStyles.inputDecoration(
                            hintText: 'Buscar por proveedor o referencia...')
                        .copyWith(
                      prefixIcon: const Icon(Icons.search,
                          size: 20, color: Colors.grey),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 16),
                _toolbarButton('Filtrar', Icons.filter_list,
                    () => _showFilterDialog(accounts)),
                const SizedBox(width: 8),
                _toolbarButton('Exportar', Icons.download_outlined, () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Función de exportar próximamente')));
                }),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => showDialog(
                      context: context,
                      builder: (_) => const AddAccountDialog()),
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text('Nueva Factura'),
                  style: AppStyles.primaryButtonStyle.copyWith(
                    padding: WidgetStateProperty.all(const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _toolbarButton(String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF374151),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  List<AccountPayableModel> _getFilteredAndSortedAccounts(
      List<AccountPayableModel> allAccounts) {
    final filtered = allAccounts.where((a) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final provider = a.provider?.name.toLowerCase() ?? '';
        final ref = a.invoiceInternRef?.toLowerCase() ?? '';
        if (!provider.contains(query) && !ref.contains(query)) return false;
      }
      if (_statusFilter != 'Todos') {
        final status = _getStatusString(a);
        if (status != _statusFilter) return false;
      }
      if (_dateRange != null) {
        if (a.invoiceDate.isBefore(_dateRange!.start) ||
            a.invoiceDate
                .isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }
      if (_providerFilter != null && _providerFilter != 'Todos') {
        if (a.provider?.name != _providerFilter) return false;
      }
      if (_minBalance != null && a.currentBalance < _minBalance!) return false;
      if (_onlyDebt && a.currentBalance <= 0) return false;
      return true;
    }).toList();

    filtered.sort((a, b) {
      int cmp = 0;
      switch (_sortColumnIndex) {
        case 0:
          cmp = (a.provider?.name ?? '').compareTo(b.provider?.name ?? '');
          break;
        case 1:
          cmp = (a.invoiceInternRef ?? '').compareTo(b.invoiceInternRef ?? '');
          break;
        case 2:
          cmp = a.invoiceDate.compareTo(b.invoiceDate);
          break;
        case 3:
          cmp = a.totalAmount.compareTo(b.totalAmount);
          break;
        case 4:
          cmp = a.totalPaid.compareTo(b.totalPaid);
          break;
        case 5:
          cmp = a.currentBalance.compareTo(b.currentBalance);
          break;
        case 6:
          cmp = _getStatusString(a).compareTo(_getStatusString(b));
          break;
      }
      return _isAscending ? cmp : -cmp;
    });

    return filtered;
  }

  void _sort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
    });
  }

  String _getStatusString(AccountPayableModel a) {
    if (a.currentBalance <= 0) return 'Pagado';
    if (a.totalPaid > 0) return 'Parcial';
    return 'Pendiente';
  }

  void _showFilterDialog(List<AccountPayableModel>? accounts) {
    final providers = accounts
            ?.map((e) => e.provider?.name)
            .where((name) => name != null)
            .toSet()
            .toList() ??
        [];
    providers.sort();
    providers.insert(0, 'Todos');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateSB) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filtrar Facturas',
                      style: AppStyles.dialogTitleStyle),
                  const SizedBox(height: 32),
                  const Text('Estado', style: AppStyles.labelStyle),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: AppStyles.inputDecoration(),
                    value: _statusFilter,
                    items: ['Todos', 'Pagado', 'Parcial', 'Pendiente']
                        .map<DropdownMenuItem<String>>((s) =>
                            DropdownMenuItem<String>(
                                value: s,
                                child: Text(s,
                                    style: const TextStyle(fontSize: 14))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setStateSB(() => _statusFilter = val);
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text('Proveedor', style: AppStyles.labelStyle),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: AppStyles.inputDecoration(),
                    value: _providerFilter ?? 'Todos',
                    items: providers
                        .map<DropdownMenuItem<String>>((p) =>
                            DropdownMenuItem<String>(
                                value: p,
                                child: Text(p!,
                                    style: const TextStyle(fontSize: 14))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setStateSB(() => _providerFilter = val);
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text('Rango de Fechas', style: AppStyles.labelStyle),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          initialDateRange: _dateRange);
                      if (picked != null) setStateSB(() => _dateRange = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFF9FAFB)),
                      child: Row(children: [
                        const Icon(Icons.date_range,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(
                            _dateRange == null
                                ? 'Cualquier fecha'
                                : '${DateFormat('MM/dd').format(_dateRange!.start)} - ${DateFormat('MM/dd').format(_dateRange!.end)}',
                            style: const TextStyle(fontSize: 14)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Saldo Mínimo',
                                  style: AppStyles.labelStyle),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: _minBalance?.toString() ?? '',
                                decoration:
                                    AppStyles.inputDecoration(hintText: '0.00')
                                        .copyWith(prefixText: '\$ '),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                onChanged: (val) => setStateSB(
                                    () => _minBalance = double.tryParse(val)),
                              ),
                            ]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Opciones',
                                  style: AppStyles.labelStyle),
                              const SizedBox(height: 8),
                              SwitchListTile(
                                title: const Text('Con Deuda',
                                    style: TextStyle(fontSize: 13)),
                                value: _onlyDebt,
                                dense: true,
                                onChanged: (val) =>
                                    setStateSB(() => _onlyDebt = val),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton(
                        onPressed: () {
                          setState(() {
                            _statusFilter = 'Todos';
                            _dateRange = null;
                            _providerFilter = 'Todos';
                            _minBalance = null;
                            _onlyDebt = false;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Limpiar Todo')),
                    const SizedBox(width: 16),
                    ElevatedButton(
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(context);
                        },
                        style: AppStyles.primaryButtonStyle,
                        child: const Text('Aplicar Filtros')),
                  ]),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildStatCard(BuildContext context,
      {required String title,
      required double amount,
      required Color color,
      bool isMoney = false,
      required IconData icon}) {
    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 800 ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(
                isMoney
                    ? NumberFormat.simpleCurrency().format(amount)
                    : amount.toString(),
                style: TextStyle(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.bold,
                    fontSize: MediaQuery.of(context).size.width < 800 ? 18 : 20)),
          ]),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AccountPayableModel account) {
    if (account.currentBalance <= 0) {
      return _badge('Pagado', const Color(0xFF065F46), const Color(0xFFD1FAE5));
    }
    if (account.totalPaid > 0) {
      return _badge(
          'Parcial', const Color(0xFF92400E), const Color(0xFFFEF3C7));
    }
    return _badge(
        'Pendiente', const Color(0xFF991B1B), const Color(0xFFFEE2E2));
  }

  Widget _badge(String text, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.1))),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMobileList(List<AccountPayableModel> pagedAccounts) {
    if (pagedAccounts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No se encontraron cuentas.',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final currency = NumberFormat.simpleCurrency();

    return ListView.builder(
      itemCount: pagedAccounts.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final account = pagedAccounts[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title: const Text('Detalle de Cuenta'),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0.5,
                    ),
                    backgroundColor: const Color(0xFFF9FAFB),
                    body: AccountPayableDetailView(accountId: account.id),
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(account.provider?.name ?? 'S/N',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Ref: ${account.invoiceInternRef ?? "-"}',
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                      _buildStatusBadge(account),
                    ],
                  ),
                  if (account.projectName != null) ...[
                    const SizedBox(height: 8),
                    Text(account.projectName!,
                        style:
                            TextStyle(fontSize: 13, color: Colors.blue[700])),
                  ],
                  const SizedBox(height: 8),
                  Text(DateFormat('MM/dd/yyyy').format(account.invoiceDate),
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Monto',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(currency.format(account.totalAmount),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pagado',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(currency.format(account.totalPaid),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF059669))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Saldo',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(currency.format(account.currentBalance),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: account.currentBalance > 0
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF111827))),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
