import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/invoice_models.dart';
import '../providers/invoice_providers.dart';
import 'create_invoice_screen.dart';

class InvoicesListScreen extends ConsumerStatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  ConsumerState<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends ConsumerState<InvoicesListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesListProvider);
    final selectedId = ref.watch(selectedInvoiceIdProvider);
    final currency = NumberFormat.simpleCurrency();
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Facturas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    invoicesAsync.when(
                      data: (list) => Text(
                        '${list.length} Total',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateInvoiceScreen(),
                        ),
                      ).then((_) => ref.refresh(invoicesListProvider));
                    },
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Nueva Factura'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Buscar facturas...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                fillColor: const Color(0xFFF5F5F4),
                filled: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // List
          Expanded(
            child: invoicesAsync.when(
              data: (invoices) {
                final filtered = invoices.where((inv) {
                  final query = _searchQuery.toLowerCase();
                  return inv.id.toString().contains(query) ||
                      (inv.clientName?.toLowerCase().contains(query) ??
                          false) ||
                      (inv.address?.toLowerCase().contains(query) ?? false);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No hay facturas'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final invoice = filtered[index];
                    final isSelected = invoice.id == selectedId;

                    return _InvoiceListItem(
                      invoice: invoice,
                      isSelected: isSelected,
                      currency: currency,
                      dateFormat: dateFormat,
                      onTap: () {
                        ref.read(selectedInvoiceIdProvider.notifier).state =
                            invoice.id;
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceListItem extends StatelessWidget {
  final InvoiceModel invoice;
  final bool isSelected;
  final NumberFormat currency;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  const _InvoiceListItem({
    required this.invoice,
    required this.isSelected,
    required this.currency,
    required this.dateFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isSelected ? const Color(0xFFFFFBEB) : Colors.transparent;
    final borderColor =
        isSelected ? const Color(0xFFF59E0B) : Colors.transparent;
    final titleColor =
        isSelected ? const Color(0xFF92400E) : const Color(0xFF1F2937);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: const Color(0xFFF5F5F4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: borderColor,
              width: 4,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    invoice.clientName ?? 'Sin Cliente',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  dateFormat.format(invoice.date),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Invoice #${invoice.id} - ${invoice.address ?? "No Project"}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currency.format(invoice.totalVenta),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        invoice.saldo > 0 ? Colors.red[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    invoice.saldo > 0
                        ? 'Saldo: ${currency.format(invoice.saldo)}'
                        : 'Pagado',
                    style: TextStyle(
                      color: invoice.saldo > 0
                          ? Colors.red[700]
                          : Colors.green[700],
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
