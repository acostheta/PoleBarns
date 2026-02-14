import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../../config/app_styles.dart';
import '../models/pole_barn_model.dart';
import '../models/related_material_model.dart';
import '../providers/pole_barn_provider.dart';

class PoleBarnDetailScreen extends ConsumerStatefulWidget {
  final PoleBarn? initialPoleBarn;

  const PoleBarnDetailScreen({super.key, this.initialPoleBarn});

  @override
  ConsumerState<PoleBarnDetailScreen> createState() =>
      _PoleBarnDetailScreenState();
}

class _PoleBarnDetailScreenState extends ConsumerState<PoleBarnDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _largoController;
  late TextEditingController _anchoController;
  late TextEditingController _altoController;
  late TextEditingController _spacingController;
  late TextEditingController _sheetController;
  late TextEditingController _precioVentaController;
  late TextEditingController _budgetController;
  late TextEditingController _nameController;
  late TextEditingController _labourController;

  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: r'$');

  @override
  void initState() {
    super.initState();
    final pb = widget.initialPoleBarn;
    _largoController = TextEditingController(text: pb?.largo.toString() ?? '0');
    _anchoController = TextEditingController(text: pb?.ancho.toString() ?? '0');
    _altoController = TextEditingController(text: pb?.alto.toString() ?? '0');
    _spacingController =
        TextEditingController(text: pb?.spacing.toString() ?? '0');
    _sheetController = TextEditingController(text: pb?.sheet.toString() ?? '0');
    _precioVentaController =
        TextEditingController(text: pb?.precioVenta.toString() ?? '0');
    _budgetController =
        TextEditingController(text: pb?.budgetLimit.toString() ?? '0');
    _nameController = TextEditingController(text: pb?.name ?? '');
    _labourController =
        TextEditingController(text: pb?.labour.toString() ?? '0');
  }

  @override
  void dispose() {
    _largoController.dispose();
    _anchoController.dispose();
    _altoController.dispose();
    _spacingController.dispose();
    _sheetController.dispose();
    _precioVentaController.dispose();
    _budgetController.dispose();
    _nameController.dispose();
    _labourController.dispose();
    super.dispose();
  }

  void _updatePoleBarnLocal() {
    final largo = double.tryParse(_largoController.text);
    final ancho = double.tryParse(_anchoController.text);
    final alto = double.tryParse(_altoController.text);

    if (largo == null || ancho == null || alto == null) return;

    final notifier =
        ref.read(poleBarnFormProvider(widget.initialPoleBarn).notifier);
    final currentState =
        ref.read(poleBarnFormProvider(widget.initialPoleBarn)).poleBarn;

    notifier.updatePoleBarnField(currentState.copyWith(
      name: _nameController.text,
      largo: largo,
      ancho: ancho,
      alto: alto,
      spacing: double.tryParse(_spacingController.text) ?? currentState.spacing,
      sheet: double.tryParse(_sheetController.text) ?? currentState.sheet,
      precioVenta: double.tryParse(_precioVentaController.text) ??
          currentState.precioVenta,
      budgetLimit:
          double.tryParse(_budgetController.text) ?? currentState.budgetLimit,
      labour: double.tryParse(_labourController.text) ?? currentState.labour,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(poleBarnFormProvider(widget.initialPoleBarn));
    final notifier =
        ref.read(poleBarnFormProvider(widget.initialPoleBarn).notifier);

    final parentStream = state.poleBarn.id != null
        ? ref.watch(poleBarnStreamProvider(state.poleBarn.id!)).value
        : null;

    final displayTotal = state.localTotal;
    final displayLabour = state.poleBarn.labour;

    String displayAlertStatus =
        parentStream?.alertStatus ?? state.poleBarn.alertStatus;
    if (displayTotal > state.poleBarn.budgetLimit &&
        state.poleBarn.budgetLimit > 0) {
      displayAlertStatus =
          "ALERTA LOCAL: Presupuesto excedido ($displayTotal > ${state.poleBarn.budgetLimit})";
    }

    if (!state.isPriceManuallyEdited) {
      if (_precioVentaController.text !=
          state.poleBarn.precioVenta.toString()) {
        _precioVentaController.text = state.poleBarn.precioVenta.toString();
      }
    }

    if (!state.isNameManuallyEdited) {
      if (_nameController.text != state.poleBarn.name) {
        _nameController.text = state.poleBarn.name ?? '';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Detalle de Producto',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (state.poleBarn.id != null)
            IconButton(
              onPressed: () => _confirmDelete(state.poleBarn.id!),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Eliminar Producto',
            ),
          if (state.isSaving || state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppStyles.primaryOrange,
                  ),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Icon(Icons.cloud_done, color: Colors.green),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            if (state.error != null) _buildErrorBanner(state.error!),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Top Section: Info & Specs
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 8),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeaderCard(state, displayAlertStatus),
                              const SizedBox(height: 24),
                              _buildSpecificationsCard(
                                  displayTotal, displayLabour),
                              const SizedBox(height: 24),
                              _buildServiceDetailsCard(state),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Middle Section: Materials Table
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(32, 8, 32, 16),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: _buildMaterialsCard(state, notifier),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDetailsCard(PoleBarnFormState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RESUMEN DE PRECIOS',
              style: TextStyle(
                  color: AppStyles.primaryOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.2)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Protagonist: Configure Price
              SizedBox(
                width: 250,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CONFIGURE PRECIO DE VENTA',
                        style: TextStyle(
                            color: AppStyles.primaryOrange,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _precioVentaController,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                      decoration: AppStyles.inputDecoration().copyWith(
                        prefixIcon: const Icon(Icons.sell,
                            size: 24, color: AppStyles.primaryOrange),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        fillColor: Colors.orange.shade50,
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      onChanged: (_) => _updatePoleBarnLocal(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // 2. Mano de Obra
              SizedBox(
                width: 180,
                child: _buildNumericField(
                    _labourController, 'Mano de Obra', Icons.work_outline,
                    isCurrency: true),
              ),
              _buildStatSeparator(),
              // 3. Price Sugerido
              _buildServiceStat('Precio Sugerido',
                  _currencyFormat.format(state.localTotalPrice),
                  isPrimary: true),
              _buildStatSeparator(),
              // 4. Total Venta Materiales
              _buildServiceStat('Total Venta Materiales',
                  _currencyFormat.format(state.localTotal)),
              _buildStatSeparator(),
              // 5. Costo Materiales
              _buildServiceStat(
                  'Costo Materiales', _currencyFormat.format(state.localCost)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceStat(String label, String value,
      {bool isPrimary = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(
                color:
                    isPrimary ? AppStyles.primaryOrange : Colors.grey.shade600,
                fontSize: 11,
                fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: isPrimary
                    ? AppStyles.primaryOrange
                    : const Color(0xFF1E293B),
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatSeparator() {
    return Container(
      height: 32,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 32),
      color: Colors.grey.shade300,
    );
  }

  Widget _buildHeaderCard(PoleBarnFormState state, String alertStatus) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PRODUCTO',
                        style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 1.0)),
                    const SizedBox(height: 4),
                    _buildNameFieldInline(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              _buildStatusIndicator(alertStatus),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),
          Wrap(
            spacing: 32,
            runSpacing: 16,
            children: [
              _buildHeaderStat(
                  'ID', '#${state.poleBarn.id ?? "NUEVO"}', Icons.tag),
              _buildHeaderStat(
                  'PRECIO VENTA',
                  _currencyFormat.format(state.poleBarn.precioVenta),
                  Icons.sell_outlined),
              _buildHeaderStat(
                  'DIMENSIONES',
                  '${state.poleBarn.ancho}x${state.poleBarn.largo}x${state.poleBarn.alto}',
                  Icons.square_foot_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    final isOk = status == 'OK';
    final color = isOk ? const Color(0xFF059669) : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isOk ? Icons.check_circle_outline : Icons.warning_amber_rounded,
              size: 16, color: color),
          const SizedBox(width: 8),
          Text(isOk ? 'PRESUPUESTO OK' : 'ALERTA DE COSTO',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildNameFieldInline() {
    return TextFormField(
      controller: _nameController,
      style: const TextStyle(
          fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
      decoration: const InputDecoration(
        hintText: 'Nombre del Producto...',
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        isDense: true,
      ),
      onChanged: (val) => _updatePoleBarnLocal(),
    );
  }

  Widget _buildSpecificationsCard(double total, double labour) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Especificaciones y Costos',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827))),
          const SizedBox(height: 32),
          _buildMainForm(total, labour),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard(
      PoleBarnFormState state, PoleBarnFormNotifier notifier) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lista de Materiales de Catálogo',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827))),
                ElevatedButton.icon(
                  onPressed: () => _showMaterialDialog(null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar Material'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildMaterialsDataTable(state, notifier),
        ],
      ),
    );
  }

  Widget _buildMaterialsDataTable(
      PoleBarnFormState state, PoleBarnFormNotifier notifier) {
    final materials = state.relatedMaterials;
    if (materials.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(
            child: Text('No hay materiales asociados',
                style: TextStyle(color: Colors.grey))),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                    letterSpacing: 0.5),
                horizontalMargin: 20,
                columnSpacing: 16,
                dataRowMinHeight: 56,
                dataRowMaxHeight: 56,
                columns: const [
                  DataColumn(label: Text('MATERIAL')),
                  DataColumn(label: Text('CANTIDAD'), numeric: true),
                  DataColumn(label: Text('MEDIDA')),
                  DataColumn(label: Text('PRECIO UNIT.'), numeric: true),
                  DataColumn(label: Text('DESPERDICIO'), numeric: true),
                  DataColumn(label: Text('TOTAL'), numeric: true),
                  DataColumn(label: Text('ACCIONES')),
                ],
                rows: materials.asMap().entries.map((entry) {
                  final index = entry.key;
                  final m = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 250,
                          child: Text(
                            m.materialName ?? 'N/A',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF1E293B)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text(m.qty.toString(),
                          style: const TextStyle(fontSize: 13))),
                      DataCell(Text(m.medida ?? '-',
                          style: const TextStyle(fontSize: 13))),
                      DataCell(Text(_currencyFormat.format(m.pricePorUnidad),
                          style: const TextStyle(fontSize: 13))),
                      DataCell(Text('${m.wastePercent}%',
                          style: const TextStyle(fontSize: 13))),
                      DataCell(Text(_currencyFormat.format(m.calculatedTotal),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.indigo))),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 16, color: Colors.blueGrey),
                              onPressed: () => _showMaterialDialog(index)),
                          IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 16, color: Colors.red),
                              onPressed: () => notifier.removeMaterial(index)),
                        ],
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMainForm(double total, double labour) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child:
              _buildNumericField(_anchoController, 'Ancho', Icons.straighten),
        ),
        const SizedBox(width: 24),
        Expanded(
          child:
              _buildNumericField(_largoController, 'Largo', Icons.straighten),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildNumericField(_altoController, 'Alto', Icons.height),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildNumericField(
              _spacingController, 'Spacing', Icons.space_bar),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildNumericField(_sheetController, 'Sheet', Icons.layers),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildNumericField(_budgetController, 'Presupuesto Máximo',
              Icons.account_balance_wallet_outlined),
        ),
      ],
    );
  }

  Widget _buildNumericField(
      TextEditingController controller, String label, IconData icon,
      {bool isCurrency = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.labelStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          decoration: AppStyles.inputDecoration().copyWith(
            prefixIcon: Icon(icon, size: 20, color: Colors.grey),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          validator: (val) {
            if (val == null || val.isEmpty) return 'Requerido';
            final n = double.tryParse(val);
            if (n == null) return 'Inválido';
            if (n < 0) return 'No negativo';
            return null;
          },
          onChanged: (_) => _updatePoleBarnLocal(),
        ),
      ],
    );
  }

  Future<void> _showMaterialDialog(int? index) async {
    final state = ref.read(poleBarnFormProvider(widget.initialPoleBarn));
    final notifier =
        ref.read(poleBarnFormProvider(widget.initialPoleBarn).notifier);
    final rawMaterials = await ref.read(rawMaterialsProvider.future);
    if (!mounted) return;

    RelatedMaterial material = index != null
        ? state.relatedMaterials[index]
        : RelatedMaterial(qty: 0, wastePercent: 0, pricePorUnidad: 0);

    final result = await showDialog<RelatedMaterial>(
      context: context,
      builder: (context) => MaterialEditDialog(
          initialMaterial: material, rawMaterials: rawMaterials),
    );

    if (result != null) {
      if (index == null) {
        notifier.addMaterial(result);
      } else {
        notifier.updateMaterial(index, result);
      }
    }
  }

  Widget _buildErrorBanner(String msg) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.orange),
          const SizedBox(width: 16),
          Expanded(
            child: Text(msg,
                style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(int poleBarnId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Producto?'),
        content: const Text(
            'Esta acción no se puede deshacer. Se eliminará el producto del catálogo permanentemente.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      if (context.mounted) {
        await ref.read(poleBarnRepositoryProvider).deletePoleBarn(poleBarnId);
        ref.read(selectedPoleBarnIdProvider.notifier).state = null;
      }
    }
  }
}

class MaterialEditDialog extends StatefulWidget {
  final RelatedMaterial initialMaterial;
  final List<Map<String, dynamic>> rawMaterials;

  const MaterialEditDialog(
      {super.key, required this.initialMaterial, required this.rawMaterials});

  @override
  State<MaterialEditDialog> createState() => _MaterialEditDialogState();
}

class _MaterialEditDialogState extends State<MaterialEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late String? _selectedId;
  late TextEditingController _qtyController;
  late TextEditingController _wasteController;
  late TextEditingController _priceController;
  late TextEditingController _medidaController;
  String? _materialName;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialMaterial.materialId;
    _qtyController =
        TextEditingController(text: widget.initialMaterial.qty.toString());
    _wasteController = TextEditingController(
        text: widget.initialMaterial.wastePercent.toString());
    _priceController = TextEditingController(
        text: widget.initialMaterial.pricePorUnidad.toString());
    _medidaController =
        TextEditingController(text: widget.initialMaterial.medida ?? '');
    _materialName = widget.initialMaterial.materialName;
  }

  @override
  Widget build(BuildContext context) {
    double qty = double.tryParse(_qtyController.text) ?? 0;
    double price = double.tryParse(_priceController.text) ?? 0;
    double waste = double.tryParse(_wasteController.text) ?? 0;
    double rowTotal = (qty * price) * (1 + (waste / 100));

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Configurar Material',
                        style: AppStyles.dialogTitleStyle),
                    IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 32),
                const Text('Material de Catálogo', style: AppStyles.labelStyle),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedId,
                  isExpanded: true,
                  validator: (v) => v == null ? 'Seleccione material' : null,
                  decoration: AppStyles.inputDecoration(),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: widget.rawMaterials
                      .map<DropdownMenuItem<String>>((m) =>
                          DropdownMenuItem<String>(
                              value: m['id'] as String,
                              child: Text(m['name'],
                                  style: const TextStyle(fontSize: 14))))
                      .toList(),
                  onChanged: (val) {
                    final m =
                        widget.rawMaterials.firstWhere((e) => e['id'] == val);
                    setState(() {
                      _selectedId = val;
                      _materialName = m['name'];
                      _priceController.text = m['price'].toString();
                      _medidaController.text =
                          m['measures']?['name']?.toString() ?? '';
                    });
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                        child: _buildTextField('Cantidad', _qtyController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true))),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildTextField(
                            'Medida (Auto)', _medidaController,
                            readOnly: true)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                        child: _buildTextField(
                            'Precio Unitario', _priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            prefixText: '\$ ')),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildTextField(
                            'Desperdicio (%)', _wasteController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true))),
                  ],
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(NumberFormat.currency(symbol: r'$').format(rowTotal),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.indigo)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.pop(
                            context,
                            RelatedMaterial(
                              id: widget.initialMaterial.id,
                              materialId: _selectedId,
                              materialName: _materialName,
                              medida: _medidaController.text,
                              qty: double.tryParse(_qtyController.text) ?? 0,
                              wastePercent:
                                  double.tryParse(_wasteController.text) ?? 0,
                              pricePorUnidad:
                                  double.tryParse(_priceController.text) ?? 0,
                            ));
                      }
                    },
                    style: AppStyles.primaryButtonStyle,
                    child: const Text('Agregar Material'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool required = true,
      TextInputType? keyboardType,
      String? prefixText,
      bool readOnly = false}) {
    final isNumberField =
        keyboardType == const TextInputType.numberWithOptions(decimal: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.labelStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          style: TextStyle(
              fontSize: 14, color: readOnly ? Colors.grey : Colors.black87),
          keyboardType: isNumberField ? TextInputType.number : keyboardType,
          inputFormatters: isNumberField
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
              : null,
          validator: required
              ? (v) =>
                  (v == null || (isNumberField && double.tryParse(v) == null))
                      ? 'Inválido'
                      : null
              : null,
          decoration: AppStyles.inputDecoration().copyWith(
            prefixText: prefixText,
            fillColor:
                readOnly ? const Color(0xFFF3F4F6) : const Color(0xFFF9FAFB),
          ),
          onChanged: (_) => setState(() {}),
        )
      ],
    );
  }
}
