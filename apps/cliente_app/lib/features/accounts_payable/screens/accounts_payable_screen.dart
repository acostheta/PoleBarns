import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/accounts_payable_provider.dart';
import '../models/account_payable_model.dart';
import '../widgets/add_account_dialog.dart';
import '../widgets/register_payment_dialog.dart';

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
  final int _rowsPerPage = 5;
  int _currentPage = 0;

  // Filters
  String _statusFilter = 'Todos'; // Todos, Pendiente, Parcial, Pagado
  DateTimeRange? _dateRange;
  String? _providerFilter;
  double? _minBalance;
  bool _onlyDebt = false;
  String _searchQuery = ''; // Search query

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(accountsPayableListProvider);
    final stats = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas por Pagar'),
      ),
      body: Column(
        children: [
          // Dashboard Cards
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildStatCard(
                  context,
                  title: 'Total Deuda',
                  amount: stats['totalDebt']!,
                  color: Colors.orange,
                  isMoney: true,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  context,
                  title: 'Total Pagado',
                  amount: stats['totalPaid']!,
                  color: Colors.green,
                  isMoney: true,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  context,
                  title: 'Por Pagar',
                  amount: stats['pendingBalance']!,
                  color: Colors.redAccent,
                  isMoney: true,
                ),
              ],
            ),
          ),

          // Toolbar (Search, Filter, Export, Add)
          _buildToolbar(context, accountsState.asData?.value),

          // List
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: accountsState.when(
                  data: (accounts) {
                    final processedAccounts =
                        _getFilteredAndSortedAccounts(accounts);

                    if (processedAccounts.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'No hay facturas que coincidan con los filtros.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    // Pagination Logic
                    final totalItems = processedAccounts.length;
                    final totalPages = (totalItems / _rowsPerPage).ceil();
                    // Ensure current page is valid after filters/deletes
                    if (_currentPage >= totalPages) {
                      _currentPage = totalPages > 0 ? totalPages - 1 : 0;
                    }

                    final startIndex = _currentPage * _rowsPerPage;
                    final endIndex =
                        (startIndex + _rowsPerPage).clamp(0, totalItems);
                    final pagedAccounts =
                        processedAccounts.sublist(startIndex, endIndex);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 1000),
                            child: DataTable(
                              sortColumnIndex: _sortColumnIndex,
                              sortAscending: _isAscending,
                              headingRowColor: WidgetStateProperty.all(
                                  const Color(0xFFFAFAF9)),
                              dataRowColor:
                                  WidgetStateProperty.resolveWith<Color?>(
                                      (Set<WidgetState> states) {
                                if (states.contains(WidgetState.hovered)) {
                                  return const Color(0xFFF5F5F4);
                                }
                                return Colors.white;
                              }),
                              dividerThickness: 1,
                              horizontalMargin: 24,
                              columnSpacing: 24,
                              columns: [
                                DataColumn(
                                  label: Text('PROVEEDOR',
                                      style: _tableHeaderStyle),
                                  onSort: (index, ascending) =>
                                      _sort(index, ascending),
                                ),
                                DataColumn(
                                  label: Text('NRO INVOICE INTERNO',
                                      style: _tableHeaderStyle),
                                  onSort: (index, ascending) =>
                                      _sort(index, ascending),
                                ),
                                DataColumn(
                                  label:
                                      Text('FECHA', style: _tableHeaderStyle),
                                  onSort: (index, ascending) =>
                                      _sort(index, ascending),
                                ),
                                DataColumn(
                                  label:
                                      Text('MONTO', style: _tableHeaderStyle),
                                  numeric: true,
                                  onSort: (index, ascending) =>
                                      _sort(index, ascending),
                                ),
                                DataColumn(
                                  label:
                                      Text('PAGADO', style: _tableHeaderStyle),
                                  numeric: true,
                                  onSort: (index, ascending) =>
                                      _sort(index, ascending),
                                ),
                                DataColumn(
                                  label:
                                      Text('SALDO', style: _tableHeaderStyle),
                                  numeric: true,
                                  onSort: (index, ascending) =>
                                      _sort(index, ascending),
                                ),
                                DataColumn(
                                  label:
                                      Text('ESTADO', style: _tableHeaderStyle),
                                  numeric: false,
                                  // Status sort optional, implemented below
                                  onSort: (index, ascending) =>
                                      _sort(index, ascending),
                                ),
                                const DataColumn(label: SizedBox(width: 24)),
                              ],
                              rows: pagedAccounts.map((account) {
                                return DataRow(
                                  onSelectChanged: (_) =>
                                      _showPaymentDialog(context, account),
                                  cells: [
                                    DataCell(
                                      Text(
                                        account.provider?.name ??
                                            'Proveedor Desconocido',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF111827)),
                                      ),
                                    ),
                                    DataCell(Text(
                                        account.invoiceInternRef ?? '-',
                                        style: const TextStyle(
                                            color: Color(0xFF44403C)))),
                                    DataCell(Text(
                                        DateFormat('yyyy-MM-dd')
                                            .format(account.invoiceDate),
                                        style: const TextStyle(
                                            color: Color(0xFF44403C)))),
                                    DataCell(Text(
                                      NumberFormat.simpleCurrency()
                                          .format(account.totalAmount),
                                      style: const TextStyle(
                                          color: Color(0xFF44403C)),
                                    )),
                                    DataCell(Text(
                                      NumberFormat.simpleCurrency()
                                          .format(account.totalPaid),
                                      style: account.totalPaid > 0
                                          ? const TextStyle(
                                              color: Color(0xFF166534))
                                          : const TextStyle(
                                              color: Color(0xFF991B1B)),
                                    )),
                                    DataCell(Text(
                                      NumberFormat.simpleCurrency()
                                          .format(account.currentBalance),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF111827)),
                                    )),
                                    DataCell(_buildStatusBadge(account)),
                                    DataCell(const Icon(Icons.more_vert,
                                        color: Color(0xFFA8A29E))),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        // Pagination Controls
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${startIndex + 1}-$endIndex de $totalItems',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: _currentPage > 0
                                    ? () => setState(() => _currentPage--)
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: _currentPage < totalPages - 1
                                    ? () => setState(() => _currentPage++)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, s) => SizedBox(
                    height: 200,
                    child: Center(child: Text('Error: $e')),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(
      BuildContext context, List<AccountPayableModel>? accounts) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por proveedor o referencia...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          const SizedBox(width: 16),

          // Filter Button
          OutlinedButton.icon(
            onPressed: () => _showFilterDialog(accounts),
            icon: const Icon(Icons.filter_list),
            label: const Text('Filtrar'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(width: 8),

          // Export Button (Stub)
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Función de exportar próximamente')),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Exportar'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(width: 8),

          // Add Button
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const AddAccountDialog(),
              );
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Nueva Factura',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111827), // dark
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  // --- Logic Methods ---

  List<AccountPayableModel> _getFilteredAndSortedAccounts(
      List<AccountPayableModel> allAccounts) {
    // 1. Filter
    final filtered = allAccounts.where((a) {
      // Search Query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final provider = a.provider?.name.toLowerCase() ?? '';
        final ref = a.invoiceInternRef?.toLowerCase() ?? '';
        if (!provider.contains(query) && !ref.contains(query)) {
          return false;
        }
      }
      // Status
      if (_statusFilter != 'Todos') {
        final status = _getStatusString(a);
        if (status != _statusFilter) return false;
      }
      // Date Range
      if (_dateRange != null) {
        if (a.invoiceDate.isBefore(_dateRange!.start) ||
            a.invoiceDate
                .isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }
      // Provider
      if (_providerFilter != null && _providerFilter != 'Todos') {
        if (a.provider?.name != _providerFilter) return false;
      }
      // Min Balance
      if (_minBalance != null) {
        if (a.currentBalance < _minBalance!) return false;
      }
      // Only Debt
      if (_onlyDebt) {
        if (a.currentBalance <= 0) return false;
      }
      return true;
    }).toList();

    // 2. Sort
    filtered.sort((a, b) {
      int cmp = 0;
      switch (_sortColumnIndex) {
        case 0: // Proveedor
          cmp = (a.provider?.name ?? '').compareTo(b.provider?.name ?? '');
          break;
        case 1: // Internal Ref
          cmp = (a.invoiceInternRef ?? '').compareTo(b.invoiceInternRef ?? '');
          break;
        case 2: // Date
          cmp = a.invoiceDate.compareTo(b.invoiceDate);
          break;
        case 3: // Amount
          cmp = a.totalAmount.compareTo(b.totalAmount);
          break;
        case 4: // Paid
          cmp = a.totalPaid.compareTo(b.totalPaid);
          break;
        case 5: // Balance
          cmp = a.currentBalance.compareTo(b.currentBalance);
          break;
        case 6: // Status
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
    // Extract unique providers for dropdown
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
          return AlertDialog(
            title: const Text('Filtrar Facturas'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Estado'),
                    value: _statusFilter,
                    items: ['Todos', 'Pagado', 'Parcial', 'Pendiente']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setStateSB(() => _statusFilter = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Provider
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Proveedor'),
                    value: _providerFilter ?? 'Todos',
                    items: providers
                        .map((p) => DropdownMenuItem(value: p, child: Text(p!)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setStateSB(() => _providerFilter = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date Range Button
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        initialDateRange: _dateRange,
                      );
                      if (picked != null) {
                        setStateSB(() => _dateRange = picked);
                      }
                    },
                    icon: const Icon(Icons.date_range),
                    label: Text(_dateRange == null
                        ? 'Rango de Fechas (Todos)'
                        : '${DateFormat('dd/MM/yyyy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange!.end)}'),
                  ),
                  if (_dateRange != null)
                    TextButton(
                      onPressed: () => setStateSB(() => _dateRange = null),
                      child: const Text('Limpiar Fechas'),
                    ),
                  const SizedBox(height: 16),

                  // Min Balance
                  TextFormField(
                    initialValue:
                        _minBalance != null ? _minBalance.toString() : '',
                    decoration: const InputDecoration(
                      labelText: 'Saldo Mínimo',
                      prefixText: '\$ ',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) {
                      final n = double.tryParse(val);
                      setStateSB(() => _minBalance = n);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Only Debt Switch
                  SwitchListTile(
                    title: const Text('Solo con Deuda'),
                    value: _onlyDebt,
                    onChanged: (val) => setStateSB(() => _onlyDebt = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Reset logic if needed, or just close
                  setState(() {
                    _statusFilter = 'Todos';
                    _dateRange = null;
                    _providerFilter = 'Todos';
                    _minBalance = null;
                    _onlyDebt = false;
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Limpiar Todo'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Apply filters is redundant because we update state variables directly
                  // but we trigger parent rebuild on close by popping?
                  // Wait, modifying local variables in StatefulBuilder only updates the dialog.
                  // We need to update the parent state.
                  // Since I'm referring to `_statusFilter` etc which are in the parent State,
                  // updating them inside setStateSB updates the reference, BUT parent widget doesn't rebuild yet.
                  // We need to call parent setState when applying or as we go.
                  // Better UX: Apply on "Aplicar".
                  setState(() {}); // Rebuild parent to reflect changes
                  Navigator.of(context).pop();
                },
                child: const Text('Aplicar'),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required double amount,
    required Color color,
    bool isMoney = false,
  }) {
    final currencyFormat = NumberFormat.simpleCurrency(decimalDigits: 2);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              isMoney ? currencyFormat.format(amount) : amount.toString(),
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  static const _tableHeaderStyle = TextStyle(
    color: Color(0xFF44403C), // stone-700
    fontSize: 12,
    fontWeight: FontWeight.bold,
  );

  Widget _buildStatusBadge(AccountPayableModel account) {
    if (account.currentBalance <= 0) {
      return _badge(
        text: 'Pagado',
        color: const Color(0xFF14532D), // green-900
        bgColor: const Color(0xFFDCFCE7), // green-100
      );
    } else if (account.totalPaid > 0) {
      return _badge(
        text: 'Parcial',
        color: const Color(0xFF92400E), // amber-800
        bgColor: const Color(0xFFFEF3C7), // amber-100
      );
    } else {
      return _badge(
        text: 'Pendiente',
        color: const Color(0xFF991B1B), // red-900
        bgColor: const Color(0xFFFEE2E2), // red-100
      );
    }
  }

  Widget _badge(
      {required String text, required Color color, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, AccountPayableModel account) {
    if (account.currentBalance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta cuenta ya está saldada.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => RegisterPaymentDialog(account: account),
    );
  }
}
