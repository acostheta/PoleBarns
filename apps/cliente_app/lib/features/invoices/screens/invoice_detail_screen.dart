import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/app_styles.dart';
import '../models/invoice_models.dart';
import '../providers/invoice_providers.dart';
import '../utils/invoice_pdf_generator.dart';
import '../widgets/add_payment_dialog.dart';
import '../widgets/edit_payment_dialog.dart';
import '../../clients/repositories/client_repository.dart';
import '../../accounts_payable/providers/accounts_payable_provider.dart';
import '../../accounts_payable/widgets/add_account_dialog.dart';
import '../../accounts_payable/models/account_payable_model.dart';
import '../../project_tracking/widgets/project_create_dialog.dart';
import '../../../shared/widgets/location_map_card.dart';
import '../../../shared/widgets/app_bar_portal.dart';

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
    final apListAsync =
        ref.watch(invoiceAccountsPayableListProvider(widget.invoiceId));
    final apTotalAsync =
        ref.watch(invoiceAccountsPayableTotalProvider(widget.invoiceId));

    final isMobileAppBar = MediaQuery.of(context).size.width < 800;

    // We rely on the clientName already joined in the InvoiceModel

    return Scaffold(
      backgroundColor: AppStyles.stoneWhite,
      body: invoiceStream.when(
        data: (invoice) {
          final totalCosts = apTotalAsync.value ?? 0.0;
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
            totalVenta: calculatedTotalVenta,
            totalPagado: calculatedTotalPagado,
            reembolsado: calculatedReembolsado,
            saldo: calculatedSaldo,
          );

          final totalPurchaseCost = products.fold<double>(
              0, (sum, p) => sum + (p.purchaseCost ?? 0.0));
          final calculatedProfit =
              calculatedTotalVenta - totalPurchaseCost - totalCosts;

          return Column(
            children: [
              AppBarPortal(
                title: 'Detalle de Factura',
                actions: [
                  if (invoice.idProyecto == null)
                    IconButton(
                      onPressed: () => _showCreateProjectDialog(
                          context, enrichedInvoice, products),
                      icon: const Icon(Icons.business_outlined,
                          color: Colors.white70),
                      tooltip: 'Crear Proyecto',
                    ),
                  IconButton(
                    onPressed: () => _sendEmail(enrichedInvoice),
                    icon: const Icon(Icons.email_outlined,
                        color: Colors.white70),
                    tooltip: 'Enviar por Email',
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: () => _generatePDF(enrichedInvoice),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.secondaryEarth,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text(
                        'Imprimir',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon:
                        const Icon(Icons.edit_outlined, color: Colors.white70),
                    onPressed: () =>
                        context.push('/invoices/${invoice.id}/edit'),
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.white70),
                    onPressed: () => _confirmDeleteInvoice(context, invoice.id),
                    tooltip: 'Eliminar',
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              Container(height: 4, color: AppStyles.secondaryEarth),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                    _buildSummaryBadge(enrichedInvoice),
                    const SizedBox(height: 16),
                    _buildHeader(enrichedInvoice),
                    if ((enrichedInvoice.address ?? '').isNotEmpty) ...[
                      const SizedBox(height: 16),
                      LocationMapCard(address: enrichedInvoice.address ?? ''),
                    ],
                    const SizedBox(height: 24),
                    _buildFinancialSummary(
                      invoice: enrichedInvoice,
                      totalExpenses: totalCosts,
                      totalProductCost: totalPurchaseCost,
                      profit: calculatedProfit,
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const Text('Pagos y Reembolsos',
                            style: AppStyles.dialogTitleStyle),
                        ElevatedButton.icon(
                          onPressed: () => _showAddPaymentModal(
                              context,
                              enrichedInvoice.totalVenta,
                              enrichedInvoice.saldo),
                          icon: const Icon(Icons.add_card, size: 18),
                          label: const Text('Agregar Pago'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyles.primaryForest,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPaymentsList(paymentsAsync),
                    const SizedBox(height: 32),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const Text('Estructuras / Productos',
                            style: AppStyles.dialogTitleStyle),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildProductsList(productsAsync),
                    const SizedBox(height: 32),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const Text('Costos del Proyecto (Factura)',
                            style: AppStyles.dialogTitleStyle),
                        ElevatedButton.icon(
                          onPressed: () => _showAddCostDialog(context),
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text('Agregar Gasto'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyles.secondaryEarth,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCostsList(apListAsync),
                    const SizedBox(height: 50), // Extra bottom padding
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppStyles.paleSage),
        boxShadow: [
          BoxShadow(
              color: AppStyles.primaryForest.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detalles de Invoice #',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827))),
          const SizedBox(height: 24),
          Wrap(
            spacing: 32,
            runSpacing: 24,
            children: [
              SizedBox(
                  width: 300,
                  child: _buildReadFieldSimple(
                      'DIRECCIÓN', invoice.address ?? 'N/A')),
              SizedBox(
                  width: 300,
                  child: _buildReadFieldSimple(
                      'GRUPO', invoice.groupName ?? 'N/A')),
              SizedBox(
                width: 300,
                child: _buildReadFieldWithAvatar(
                    'RESPONSABLE',
                    invoice.responsible ?? 'N/A',
                    _getInitials(invoice.responsible ?? 'N/A')),
              ),
              SizedBox(
                  width: 300,
                  child: _buildReadFieldWithIcon('FECHA INICIO',
                      invoice.startDate, Icons.calendar_today_outlined)),
              SizedBox(
                  width: 300,
                  child: _buildReadFieldWithIcon(
                      'FECHA FIN', invoice.endDate, Icons.event_outlined)),
              SizedBox(
                  width: 300,
                  child: _buildReadStatusPill('ESTATUS', invoice.status)),
            ],
          ),
          const SizedBox(height: 24),
          _buildReadFieldWithIcon('COMENTARIOS', null, Icons.comment_outlined,
              customText: invoice.comentario ?? 'Sin comentarios'),
          if (invoice.notesForInvoice != null &&
              invoice.notesForInvoice!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildReadFieldWithIcon(
                'NOTES FOR INVOICE', null, Icons.notes_outlined,
                customText: invoice.notesForInvoice!),
          ],
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty || name == 'N/A') return '??';
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length >= 2 ? 2 : name.length).toUpperCase();
  }

  Widget _buildReadFieldWithAvatar(
      String label, String value, String initials) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9CA3AF),
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFE5E7EB),
              child: Text(initials,
                  style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Flexible(
                child: Text(value.isEmpty ? '-' : value,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937)),
                    overflow: TextOverflow.ellipsis)),
          ],
        )
      ],
    );
  }

  Widget _buildReadStatusPill(String label, String status) {
    Color bgColor;
    Color textColor;
    switch (status.toLowerCase()) {
      case 'pagado':
      case 'completado':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF166534);
        break;
      case 'pendiente':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        break;
      default:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF374151);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9CA3AF),
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
              color: bgColor, borderRadius: BorderRadius.circular(16)),
          child: Text(status.isEmpty ? 'Unknown' : status,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
        ),
      ],
    );
  }

  Widget _buildReadFieldSimple(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9CA3AF),
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Text(value.isEmpty ? '-' : value,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937))),
      ],
    );
  }

  Widget _buildReadFieldWithIcon(String label, DateTime? date, IconData icon,
      {String? customText}) {
    final text = customText ??
        (date != null ? DateFormat('MMM d, yyyy').format(date) : '-');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9CA3AF),
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151))),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildSummaryBadge(InvoiceModel invoice) {
    String status = 'Pendiente';
    if (invoice.status.toLowerCase() == 'cancelada' ||
        invoice.status.toLowerCase() == 'cancelado') {
      status = 'Cancelado';
    } else if (invoice.saldo <= 0) {
      status = 'Pagado';
    } else if (invoice.totalPagado > 0) {
      status = 'Parcial';
    }

    Color color = Colors.grey;
    IconData icon = Icons.info_outline;
    if (status == 'Pagado') {
      color = const Color(0xFF166534);
      icon = Icons.check_circle_outline;
    }
    if (status == 'Parcial') {
      color = AppStyles.secondaryEarth;
      icon = Icons.pending_actions;
    }
    if (status == 'Pendiente') {
      color = const Color(0xFF991B1B);
      icon = Icons.warning_amber_rounded;
    }
    if (status == 'Cancelado') {
      color = const Color(0xFF374151);
      icon = Icons.cancel_outlined;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ESTADO DE LA FACTURA',
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontFamily: 'Manrope',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'SALDO PENDIENTE',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontFamily: 'Manrope',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                currency.format(invoice.saldo),
                style: TextStyle(
                  color:
                      invoice.saldo > 0 ? AppStyles.primaryForest : color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary({
    required InvoiceModel invoice,
    required double totalExpenses,
    required double totalProductCost,
    required double profit,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppStyles.paleSage),
        boxShadow: [
          BoxShadow(
            color: AppStyles.primaryForest.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFinTile('TOTAL VENTA',
                    currency.format(invoice.totalVenta), Colors.blue),
              ),
              _buildSeparator(),
              Expanded(
                child: _buildFinTile('COSTO TOTAL',
                    currency.format(totalProductCost), Colors.red.shade700),
              ),
              _buildSeparator(),
              Expanded(
                child: _buildFinTile('PROFIT', currency.format(profit),
                    profit >= 0 ? const Color(0xFF059669) : Colors.red,
                    isHero: true),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: _buildFinTile(
                    'SALDO CLIENTE',
                    currency.format(invoice.saldo),
                    invoice.saldo > 0 ? Colors.red : Colors.green),
              ),
              _buildSeparator(),
              Expanded(
                child: _buildFinTile(
                    'COSTOS (GASTOS)',
                    currency.format(totalExpenses + invoice.reembolsado),
                    Colors.orange),
              ),
              _buildSeparator(),
              Expanded(
                child: _buildFinTile(
                    'PAGADO (INGRESOS)',
                    currency.format(invoice.totalPagado),
                    const Color(0xFF059669)),
              ),
            ],
          ),
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
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: isHero ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsList(
      AsyncValue<List<RelatedProductModel>> productsAsync) {
    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 48, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No hay estructuras o productos registrados',
                    style: TextStyle(
                        color: Colors.grey[600], fontStyle: FontStyle.italic)),
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                    columnSpacing: 24,
                    horizontalMargin: 24,
                    headingRowHeight: 56,
                    dataRowMinHeight: 64,
                    dataRowMaxHeight: 64,
                    dividerThickness: 1,
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(
                          label: Text('DESCRIPCIÓN',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF6B7280)))),
                      DataColumn(
                          label: Text('CANTIDAD',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF6B7280)))),
                      DataColumn(
                          label: Text('PRECIO UNIT.',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF6B7280)))),
                      DataColumn(
                          label: Text('TAX (%)',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF6B7280)))),
                      DataColumn(
                          label: Text(r'TAX ($)',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF6B7280)))),
                      DataColumn(
                          label: Text('ESTATUS',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF6B7280)))),
                      DataColumn(
                          label: Text('TOTAL',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF6B7280)))),
                    ],
                    rows: products.map((p) {
                      return DataRow(
                        onSelectChanged: (_) => _showEditProductModal(p),
                        cells: [
                          DataCell(Text(p.poleBarnName ?? 'Producto',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF374151)))),
                          DataCell(Text(p.cantidad.toString(),
                              style:
                                  const TextStyle(color: Color(0xFF374151)))),
                          DataCell(Text(currency.format(p.precioPorUnidad),
                              style:
                                  const TextStyle(color: Color(0xFF374151)))),
                          DataCell(Text('${p.tax}%',
                              style:
                                  const TextStyle(color: Color(0xFF374151)))),
                          DataCell(Text(
                              currency.format(
                                  p.cantidad * p.precioPorUnidad * p.tax / 100),
                              style:
                                  const TextStyle(color: Color(0xFF374151)))),
                          DataCell(_buildStatusChip(p.estatus)),
                          DataCell(Text(currency.format(p.totalPrice),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppStyles.primaryOrange))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: LinearProgressIndicator(),
        ),
      ),
      error: (e, __) => Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('Error al cargar productos: $e',
              style: const TextStyle(color: Colors.red)),
        ),
      ),
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
      data: (payments) {
        if (payments.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Icon(Icons.payment_outlined, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No hay pagos registrados',
                    style: TextStyle(
                        color: Colors.grey[600], fontStyle: FontStyle.italic)),
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                    columnSpacing: 24,
                    horizontalMargin: 24,
                    headingRowHeight: 56,
                    dataRowMinHeight: 64,
                    dataRowMaxHeight: 64,
                    dividerThickness: 1,
                    columns: const [
                      DataColumn(
                          label: Text('FECHA',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF6B7280)))),
                      DataColumn(
                          label: Text('TIPO',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF6B7280)))),
                      DataColumn(
                          label: Text('MÉTODO',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF6B7280)))),
                      DataColumn(
                          label: Text('MONTO TOTAL',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF6B7280)))),
                      DataColumn(
                          label: Text('SERVICE FEE',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF6B7280)))),
                      DataColumn(
                          label: Text('NOTA',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF6B7280)))),
                      DataColumn(
                          label: Text('ACCIONES',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF6B7280)))),
                    ],
                    rows: payments.map((pay) {
                      final isAbono = pay.tipo == 'Abono';
                      return DataRow(
                        cells: [
                          DataCell(Text(
                              DateFormat('MM/dd/yyyy').format(pay.createdAt),
                              style:
                                  const TextStyle(color: Color(0xFF374151)))),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isAbono ? Colors.green : Colors.red)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              pay.tipo.toUpperCase(),
                              style: TextStyle(
                                color: isAbono
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFDC2626),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          )),
                          DataCell(Text(pay.paymentMethodName ?? '-',
                              style:
                                  const TextStyle(color: Color(0xFF374151)))),
                          DataCell(Text(currency.format(pay.amount),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827)))),
                          DataCell(pay.feeAmount > 0
                              ? Text(currency.format(pay.feeAmount),
                                  style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.bold))
                              : Text('-',
                                  style: TextStyle(color: Colors.grey[400]))),
                          DataCell(Text(
                            pay.nota ?? '-',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13),
                          )),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                color: Colors.blue[600],
                                onPressed: () => _showEditPaymentModal(pay),
                                tooltip: 'Editar',
                                visualDensity: VisualDensity.compact,
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete_outline, size: 18),
                                color: Colors.red[600],
                                onPressed: () => _confirmDeletePayment(pay),
                                tooltip: 'Eliminar',
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, __) => Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('Error cargando pagos: $e',
              style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  void _showAddPaymentModal(
      BuildContext context, double maxAmount, double initialAmount) {
    showDialog(
      context: context,
      builder: (context) => AddPaymentDialog(
        invoiceId: widget.invoiceId,
        maxAmount: maxAmount,
        initialAmount: initialAmount,
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
      final clientEmail = client?.email ?? '';

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Generando PDF y enlace de descarga...')),
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

      // Upload and get URL
      final pdfUrl = await service.uploadInvoicePdf(
        invoiceId: invoice.id,
        pdfBytes: pdfBytes,
      );

      // Construct Mailto
      final subject = 'Invoice para ${invoice.projectName ?? "Proyecto"}';

      final body = '''
Estimado/a ${client?.nombre ?? "Cliente"},

Adjunto encontrará el enlace para descargar la factura correspondiente a su proyecto "${invoice.projectName ?? ""}".

Puede ver y descargar su factura en el siguiente enlace:
$pdfUrl

Quedamos a su disposición para cualquier duda o consulta.

Atentamente,
J & P Pole Barns
''';

      final params = _encodeQueryParameters({
        'subject': subject,
        'body': body,
      });

      final uri = Uri.parse('mailto:$clientEmail?$params');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No se pudo abrir la aplicación de correo.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al preparar correo: $e')),
        );
      }
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  void _showEditPaymentModal(InvoicePaymentModel payment) {
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

  Future<void> _confirmDeletePayment(InvoicePaymentModel payment) async {
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

  void _showAddCostDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AddAccountDialog(initialInvoiceId: widget.invoiceId),
    );
  }

  void _showCreateProjectDialog(BuildContext context, InvoiceModel invoice,
      List<RelatedProductModel> products) {
    // Map products to structures format
    // Assuming products have 'idPoleBarns' that maps to a catalog item id
    // and 'poleBarnName' and 'precioPorUnidad' which matches 'precio_venta' in catalog
    // but the dialog expects List<Map<String, dynamic>>
    final List<Map<String, dynamic>> structures =
        products.where((p) => p.idPoleBarns != null).map((p) {
      return {
        'id': p.idPoleBarns,
        'name': p.poleBarnName ?? 'Estructura ${p.id}',
        'precio_venta': p.precioPorUnidad,
      };
    }).toList();

    showDialog(
      context: context,
      builder: (_) => ProjectCreateDialog(
        initialClientId: invoice.idCliente,
        initialProjectName: invoice.projectName ?? invoice.address,
        initialDireccion: invoice.address,
        initialComments: invoice.comentario,
        initialStartDate: invoice.startDate ?? invoice.date,
        initialEndDate: invoice.endDate,
        initialStatus: invoice.status,
        initialStructures: structures,
        // For Responsible and Group, we need the NAME string, not the ID.
        // Assuming invoice.responsible and invoice.groupName are already names from join
        initialResponsible: invoice.responsible,
        initialGroupId: invoice.groupName,
      ),
    );
  }

  Future<void> _confirmDeleteInvoice(BuildContext context, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Factura'),
        content: const Text(
            '¿Está seguro de que desea eliminar esta factura? Esta acción no se puede deshacer.'),
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
      // ignore: use_build_context_synchronously
      final navigator = Navigator.of(context);
      try {
        await ref.read(invoiceServiceProvider).deleteInvoice(id);
        navigator.pop(); // Close detail screen
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  Widget _buildCostsList(AsyncValue<List<AccountPayableModel>> apListAsync) {
    return apListAsync.when(
      data: (accounts) {
        if (accounts.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 48, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('No hay gastos registrados',
                    style: TextStyle(
                        color: Colors.grey, fontStyle: FontStyle.italic)),
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                    columnSpacing: 24,
                    horizontalMargin: 24,
                    headingRowHeight: 56,
                    dataRowMinHeight: 64,
                    dataRowMaxHeight: 64,
                    dividerThickness: 1,
                    columns: const [
                      DataColumn(
                          label: Text('FECHA',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF6B7280)))),
                      DataColumn(
                          label: Text('PROVEEDOR',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF6B7280)))),
                      DataColumn(
                          label: Text('REFERENCIA',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF6B7280)))),
                      DataColumn(
                          label: Text('MONTO',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF6B7280)))),
                    ],
                    rows: accounts.map((account) {
                      return DataRow(
                        cells: [
                          DataCell(Text(
                              DateFormat('MM/dd/yyyy')
                                  .format(account.invoiceDate),
                              style:
                                  const TextStyle(color: Color(0xFF374151)))),
                          DataCell(Text(account.provider?.name ?? '-',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF374151)))),
                          DataCell(Text(account.invoiceInternRef ?? '-',
                              style:
                                  const TextStyle(color: Color(0xFF374151)))),
                          DataCell(Text(currency.format(account.totalAmount),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827)))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, stack) => Text('Error al cargar gastos: $e'),
    );
  }
}
