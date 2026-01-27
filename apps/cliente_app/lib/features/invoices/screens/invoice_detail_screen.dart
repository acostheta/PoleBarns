import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/app_styles.dart';
import '../models/invoice_models.dart';
import '../providers/invoice_providers.dart';
import '../utils/invoice_pdf_generator.dart';
import '../widgets/add_payment_dialog.dart';
import '../widgets/edit_payment_dialog.dart';
import '../../clients/repositories/client_repository.dart';
import '../../project_tracking/providers/project_providers.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final int invoiceId;
  final bool showAppBar;
  const InvoiceDetailScreen({
    super.key,
    required this.invoiceId,
    this.showAppBar = true,
  });

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  final currency = NumberFormat.simpleCurrency();

  @override
  Widget build(BuildContext context) {
    final invoiceStream = ref.watch(invoiceStreamProvider(widget.invoiceId));
    final productsAsync = ref.watch(relatedProductsProvider(widget.invoiceId));
    final paymentsAsync = ref.watch(invoicePaymentsProvider(widget.invoiceId));

    // Fetch related project and client for display
    final invoiceData = invoiceStream.asData?.value;
    final project = (invoiceData?.idProyecto != null)
        ? ref.watch(projectDetailProvider(invoiceData!.idProyecto!))
        : null;

    final clientsAsync = ref.watch(clientListProvider);
    final client = (project != null && clientsAsync.hasValue)
        ? clientsAsync.value!
            .where((c) => c.id == project.refCliente)
            .firstOrNull
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: widget.showAppBar
          ? AppBar(
              title: Text('Factura #${widget.invoiceId}',
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              elevation: 0.5,
              iconTheme: const IconThemeData(color: Colors.black),
              actions: [
                invoiceStream.when(
                  data: (invoice) {
                    final products = productsAsync.value ?? [];
                    final payments = paymentsAsync.value ?? [];

                    final calculatedTotalVenta = products.fold<double>(
                        0, (sum, p) => sum + p.totalPrice);
                    final calculatedTotalPagado = payments
                        .where((p) => p.tipo == 'Abono')
                        .fold<double>(0, (sum, p) => sum + p.amount);
                    final calculatedReembolsado = payments
                        .where((p) => p.tipo == 'Reembolso')
                        .fold<double>(0, (sum, p) => sum + p.amount);
                    final calculatedSaldo = calculatedTotalVenta -
                        calculatedTotalPagado +
                        calculatedReembolsado;

                    final enrichedInvoice = invoice.copyWith(
                      clientName: client?.fullName,
                      projectName: project?.address,
                      totalVenta: calculatedTotalVenta,
                      totalPagado: calculatedTotalPagado,
                      reembolsado: calculatedReembolsado,
                      saldo: calculatedSaldo,
                    );
                    return Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.email_outlined,
                              color: Colors.blue),
                          onPressed: () => _sendEmail(enrichedInvoice),
                          tooltip: 'Enviar por correo',
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            icon: const Icon(Icons.picture_as_pdf_outlined,
                                color: Colors.red),
                            onPressed: () => _generatePDF(enrichedInvoice),
                            tooltip: 'Generar PDF',
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            )
          : null,
      body: invoiceStream.when(
        data: (invoice) {
          final products = productsAsync.value ?? [];
          final payments = paymentsAsync.value ?? [];

          final calculatedTotalVenta =
              products.fold<double>(0, (sum, p) => sum + p.totalPrice);
          final calculatedTotalPagado = payments
              .where((p) => p.tipo == 'Abono')
              .fold<double>(0, (sum, p) => sum + p.amount);
          final calculatedReembolsado = payments
              .where((p) => p.tipo == 'Reembolso')
              .fold<double>(0, (sum, p) => sum + p.amount);
          final calculatedSaldo = calculatedTotalVenta -
              calculatedTotalPagado +
              calculatedReembolsado;

          final enrichedInvoice = invoice.copyWith(
            clientName: client?.fullName,
            projectName: project?.address,
            totalVenta: calculatedTotalVenta,
            totalPagado: calculatedTotalPagado,
            reembolsado: calculatedReembolsado,
            saldo: calculatedSaldo,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.showAppBar) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Factura #${widget.invoiceId}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.email_outlined,
                                color: Colors.blue),
                            onPressed: () => _sendEmail(enrichedInvoice),
                            tooltip: 'Enviar por correo',
                          ),
                          IconButton(
                            icon: const Icon(Icons.picture_as_pdf_outlined,
                                color: Colors.red),
                            onPressed: () => _generatePDF(enrichedInvoice),
                            tooltip: 'Generar PDF',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                _buildHeader(enrichedInvoice),
                const SizedBox(height: 24),
                _buildFinancialSummary(enrichedInvoice),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estructuras / Productos',
                        style: AppStyles.dialogTitleStyle),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),
                _buildProductsList(productsAsync),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pagos y Reembolsos',
                        style: AppStyles.dialogTitleStyle),
                    ElevatedButton.icon(
                      onPressed: () => _showAddPaymentModal(
                          context, enrichedInvoice.totalVenta),
                      icon: const Icon(Icons.add_card, size: 18),
                      label: const Text('Agregar Pago'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade50,
                        foregroundColor: Colors.indigo.shade700,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPaymentsList(paymentsAsync),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeader(InvoiceModel invoice) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CLIENTE',
                      style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(invoice.clientName ?? "N/A",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('FECHA',
                      style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(DateFormat('MM/dd/yyyy').format(invoice.date),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.location_on_outlined, 'Dirección',
              invoice.address ?? "N/A"),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.business_center_outlined, 'Proyecto',
              invoice.projectName ?? "N/A"),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialSummary(InvoiceModel invoice) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
              child: _buildFinTile('TOTAL VENTA',
                  currency.format(invoice.totalVenta), Colors.black)),
          _buildSeparator(),
          Expanded(
              child: _buildFinTile(
                  'PAGADO',
                  currency.format(invoice.totalPagado),
                  const Color(0xFF059669))),
          _buildSeparator(),
          Expanded(
              child: _buildFinTile(
                  'REEMBOLSADO',
                  currency.format(invoice.reembolsado),
                  const Color(0xFFD97706))),
          _buildSeparator(),
          Expanded(
              child: _buildFinTile('SALDO PENDIENTE',
                  currency.format(invoice.saldo), const Color(0xFFDC2626),
                  isHero: true)),
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    return Container(
        height: 40,
        width: 1,
        color: const Color(0xFFE5E7EB),
        margin: const EdgeInsets.symmetric(horizontal: 16));
  }

  Widget _buildFinTile(String label, String value, Color color,
      {bool isHero = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isHero ? 22 : 18,
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
      data: (products) => Column(
        children: products
            .map((p) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: Text(p.poleBarnName ?? 'Producto',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        'Cantidad: ${p.cantidad} x ${currency.format(p.precioPorUnidad)} + Tax ${p.tax}%'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStatusChip(p.estatus),
                        const SizedBox(width: 16),
                        Text(currency.format(p.totalPrice),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppStyles.primaryOrange)),
                      ],
                    ),
                    onTap: () => _showEditProductModal(p),
                  ),
                ))
            .toList(),
      ),
      loading: () => const LinearProgressIndicator(),
      error: (e, __) => Text('Error al cargar productos: $e'),
    );
  }

  Widget _buildStatusChip(String? status) {
    Color color = Colors.grey;
    if (status == 'Completado') color = Colors.green;
    if (status == 'En Proceso') color = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(status ?? 'Pendiente',
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPaymentsList(
      AsyncValue<List<InvoicePaymentModel>> paymentsAsync) {
    return paymentsAsync.when(
      data: (payments) => Column(
        children: payments.map((pay) {
          final isAbono = pay.tipo == 'Abono';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isAbono ? Colors.green : Colors.red)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAbono ? Icons.add : Icons.remove,
                  color: isAbono ? Colors.green : Colors.red,
                  size: 20,
                ),
              ),
              title: Text('${pay.tipo}: ${currency.format(pay.amount)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('MM/dd/yyyy').format(pay.createdAt)),
                  if (pay.nota != null && pay.nota!.isNotEmpty)
                    Text(pay.nota!,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  if (pay.paymentMethodName != null)
                    Text('Método: ${pay.paymentMethodName}',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: Colors.blue,
                    onPressed: () => _showEditPaymentModal(context, pay),
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.red,
                    onPressed: () => _confirmDeletePayment(context, pay),
                    tooltip: 'Eliminar',
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
      loading: () => const SizedBox(),
      error: (e, __) => Text('Error cargando pagos: $e'),
    );
  }

  void _showAddPaymentModal(BuildContext context, double maxAmount) {
    showDialog(
      context: context,
      builder: (context) => AddPaymentDialog(
        invoiceId: widget.invoiceId,
        maxAmount: maxAmount,
        onAdded: () {
          ref.invalidate(invoicePaymentsProvider(widget.invoiceId));
          ref.invalidate(invoiceDetailProvider(widget.invoiceId));
        },
      ),
    );
  }

  void _showEditProductModal(RelatedProductModel product) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Estatus del Producto',
                  style: AppStyles.dialogTitleStyle),
              const SizedBox(height: 32),
              const Text('Estatus', style: AppStyles.labelStyle),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: product.estatus,
                decoration: AppStyles.inputDecoration(),
                items: ['Pendiente', 'En Proceso', 'Completado']
                    .map<DropdownMenuItem<String>>((e) =>
                        DropdownMenuItem<String>(
                            value: e,
                            child:
                                Text(e, style: const TextStyle(fontSize: 14))))
                    .toList(),
                onChanged: (v) async {
                  if (v == null) return;
                  final updated = product.copyWith(estatus: v);
                  await ref
                      .read(invoiceServiceProvider)
                      .saveRelatedProduct(updated);
                  // No need to invalidate manually if using StreamProvider properly,
                  // but it doesn't hurt.
                  ref.invalidate(relatedProductsProvider(widget.invoiceId));
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
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

  Future<void> _sendEmail(InvoiceModel invoice) async {
    try {
      final service = ref.read(invoiceServiceProvider);
      final clientRepo = ref.read(clientRepositoryProvider);

      if (invoice.idCliente == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Esta factura no tiene un cliente asociado.')),
          );
        }
        return;
      }

      final client = await clientRepo.getClient(invoice.idCliente!);

      if (client?.email == null || client!.email!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('El cliente no tiene un email configurado.')),
          );
        }
        return;
      }

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enviando factura por correo...')),
        );
      }

      final products =
          ref.read(relatedProductsProvider(widget.invoiceId)).asData?.value ??
              [];

      final pdfBytes = await InvoicePdfGenerator.getBytes(
        invoice: invoice,
        products: products,
        payments: [],
      );

      await service.sendInvoiceByEmail(
        invoiceId: invoice.id,
        pdfBytes: pdfBytes,
        clientEmail: client.email!,
        clientName: client.nombre,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Factura enviada exitosamente.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar correo: $e')),
        );
      }
    }
  }

  void _showEditPaymentModal(
      BuildContext context, InvoicePaymentModel payment) {
    final enrichedInvoice =
        ref.read(invoiceDetailProvider(widget.invoiceId)).asData?.value;
    if (enrichedInvoice == null) return;

    showDialog(
      context: context,
      builder: (context) => EditPaymentDialog(
        payment: payment,
        maxAmount: enrichedInvoice.totalVenta,
        onUpdated: () {
          ref.invalidate(invoicePaymentsProvider(widget.invoiceId));
          ref.invalidate(invoiceDetailProvider(widget.invoiceId));
        },
      ),
    );
  }

  Future<void> _confirmDeletePayment(
      BuildContext context, InvoicePaymentModel payment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Pago'),
        content: Text(
          '¿Está seguro de que desea eliminar este ${payment.tipo.toLowerCase()} de ${currency.format(payment.amount)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(invoiceServiceProvider).deletePayment(payment.id);
        ref.invalidate(invoicePaymentsProvider(widget.invoiceId));
        ref.invalidate(invoiceDetailProvider(widget.invoiceId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pago eliminado exitosamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar el pago: $e')),
          );
        }
      }
    }
  }
}
