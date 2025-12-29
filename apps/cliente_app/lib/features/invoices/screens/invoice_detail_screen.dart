import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/invoice_models.dart';
import '../providers/invoice_providers.dart';
import '../utils/invoice_pdf_generator.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final int invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  final currency = NumberFormat.simpleCurrency();

  @override
  Widget build(BuildContext context) {
    // We use a stream for the invoice to get real-time balance updates
    final invoiceStream = ref.watch(invoiceStreamProvider(widget.invoiceId));
    final productsAsync = ref.watch(relatedProductsProvider(widget.invoiceId));
    final paymentsAsync = ref.watch(invoicePaymentsProvider(widget.invoiceId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de Factura #${widget.invoiceId}'),
        actions: [
          invoiceStream.when(
            data: (invoice) => IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () => _generatePDF(invoice),
              tooltip: 'Generar PDF',
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: invoiceStream.when(
        data: (invoice) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(invoice),
              const SizedBox(height: 24),
              _buildFinancialSummary(invoice),
              const SizedBox(height: 24),
              const Text('Estructuras / Productos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              _buildProductsList(productsAsync),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pagos y Reembolsos',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () => _showAddPaymentModal(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Pago'),
                  ),
                ],
              ),
              const Divider(),
              _buildPaymentsList(paymentsAsync),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeader(InvoiceModel invoice) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${invoice.clientName ?? "N/A"}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text('Dirección: ${invoice.address ?? "N/A"}'),
            const SizedBox(height: 4),
            Text('Proyecto: ${invoice.projectName ?? "Ver Proyecto"}'),
            const SizedBox(height: 4),
            Text('Fecha: ${DateFormat('dd/MM/yyyy').format(invoice.date)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummary(InvoiceModel invoice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFinTile('Total Venta', currency.format(invoice.totalVenta),
                  Colors.black),
              _buildFinTile(
                  'Pagado', currency.format(invoice.totalPagado), Colors.green),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFinTile('Reembolsado', currency.format(invoice.reembolsado),
                  Colors.orange),
              _buildFinTile(
                  'Saldo Pendiente', currency.format(invoice.saldo), Colors.red,
                  isHero: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinTile(String label, String value, Color color,
      {bool isHero = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(
          value,
          style: TextStyle(
            fontSize: isHero ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildProductsList(
      AsyncValue<List<RelatedProductModel>> productsAsync) {
    return productsAsync.when(
      data: (products) => ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];
          return ListTile(
            title: Text(p.poleBarnName ?? 'Producto'),
            subtitle: Text(
                'Cant: ${p.cantidad} x ${currency.format(p.precioPorUnidad)} + Tax ${p.tax}%'),
            trailing: Text(currency.format(p.totalPrice),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            onTap: () => _showEditProductModal(p),
          );
        },
      ),
      loading: () => const LinearProgressIndicator(),
      error: (e, __) => Text('Error al cargar productos: $e'),
    );
  }

  Widget _buildPaymentsList(
      AsyncValue<List<InvoicePaymentModel>> paymentsAsync) {
    return paymentsAsync.when(
      data: (payments) => ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final pay = payments[index];
          final isAbono = pay.tipo == 'Abono';
          return ListTile(
            leading: Icon(
              isAbono ? Icons.arrow_upward : Icons.arrow_downward,
              color: isAbono ? Colors.green : Colors.red,
            ),
            title: Text('${pay.tipo}: ${currency.format(pay.amount)}'),
            subtitle: Text(
                '${pay.metodoDePagoNombre ?? "Efectivo"} - ${DateFormat('dd/MM/yyyy').format(pay.createdAt)}'),
            trailing: pay.nota != null ? const Icon(Icons.info_outline) : null,
          );
        },
      ),
      loading: () => const SizedBox(),
      error: (e, __) => Text('Error cargando pagos: $e'),
    );
  }

  void _showAddPaymentModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddPaymentModal(
        invoiceId: widget.invoiceId,
        onAdded: () {
          ref.invalidate(invoicePaymentsProvider(widget.invoiceId));
          ref.invalidate(invoiceDetailProvider(widget.invoiceId));
        },
      ),
    );
  }

  void _showEditProductModal(RelatedProductModel product) {
    // Simple mock edit modal
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: product.estatus,
              items: ['Pendiente', 'En Proceso', 'Completado']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) async {
                await ref
                    .read(invoiceServiceProvider)
                    .updateRelatedProduct(product.id, {'Estatus': v});
                ref.invalidate(relatedProductsProvider(widget.invoiceId));
                Navigator.pop(context);
              },
              decoration: const InputDecoration(labelText: 'Estatus'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generatePDF(InvoiceModel invoice) async {
    final products =
        ref.read(relatedProductsProvider(widget.invoiceId)).asData?.value ?? [];
    final payments =
        ref.read(invoicePaymentsProvider(widget.invoiceId)).asData?.value ?? [];

    await InvoicePdfGenerator.generate(
      invoice: invoice,
      products: products,
      payments: payments,
    );
  }
}

// Separate widget for Add Payment
class AddPaymentModal extends ConsumerStatefulWidget {
  final int invoiceId;
  final VoidCallback onAdded;
  const AddPaymentModal(
      {super.key, required this.invoiceId, required this.onAdded});

  @override
  ConsumerState<AddPaymentModal> createState() => _AddPaymentModalState();
}

class _AddPaymentModalState extends ConsumerState<AddPaymentModal> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _tipo = 'Abono';
  // String? _selectedMethodId; // Removed unused

  @override
  Widget build(BuildContext context) {
    // In a real app we would fetch payment methods
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Registrar Movimiento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Abono', label: Text('Abono')),
              ButtonSegment(value: 'Reembolso', label: Text('Reembolso')),
            ],
            selected: {_tipo},
            onSelectionChanged: (v) => setState(() => _tipo = v.first),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Monto (\$)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Nota / Comentario'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(_amountController.text) ?? 0.0;
              if (amount <= 0) return;

              final pay = InvoicePaymentModel(
                id: 0,
                idInvoice: widget.invoiceId,
                tipo: _tipo,
                amount: amount,
                nota: _noteController.text,
                createdAt: DateTime.now(),
              );

              await ref.read(invoiceServiceProvider).addPayment(pay);
              widget.onAdded();
              Navigator.pop(context);
            },
            child: const Text('Confirmar'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
