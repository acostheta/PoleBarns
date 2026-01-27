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

    final displayTotalMaterials = state.localTotalMaterials;
    final displayTotalSConcreto = state.localTotalSConcreto;

    String displayAlertStatus =
        parentStream?.alertStatus ?? state.poleBarn.alertStatus;
    if (displayTotalMaterials > state.poleBarn.budgetLimit &&
        state.poleBarn.budgetLimit > 0) {
      displayAlertStatus =
          "ALERTA LOCAL: Presupuesto excedido ($displayTotalMaterials > ${state.poleBarn.budgetLimit})";
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
            state.poleBarn.id == null
                ? 'Catálogo: Nueva Caballeriza'
                : 'Catálogo: Editar Caballeriza',
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (state.poleBarn.id != null)
            IconButton(
              onPressed: () => _confirmDelete(context, ref, state.poleBarn.id!),
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.error != null) _buildErrorBanner(state.error!),
              if (displayAlertStatus != 'OK')
                _buildAlertBanner(displayAlertStatus),
              const Text('Información del Producto',
                  style: AppStyles.dialogTitleStyle),
              const SizedBox(height: 24),
              _buildNameField(),
              const SizedBox(height: 32),
              const Text('Especificaciones Generales',
                  style: AppStyles.dialogTitleStyle),
              const SizedBox(height: 32),
              _buildMainForm(displayTotalMaterials, displayTotalSConcreto),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Materiales (Realtime)',
                    style: AppStyles.dialogTitleStyle,
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showMaterialDialog(context, null),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar Material'),
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
              const SizedBox(height: 24),
              _buildMaterialsList(state, notifier),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertBanner(String msg) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
          const SizedBox(width: 16),
          Expanded(
            child: Text(msg,
                style: TextStyle(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildMainForm(double totalMaterials, double totalSConcreto) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildNumericField(
                    _anchoController, 'Ancho (ft)', Icons.straighten)),
            const SizedBox(width: 24),
            Expanded(
                child: _buildNumericField(
                    _largoController, 'Largo (ft)', Icons.straighten)),
            const SizedBox(width: 24),
            Expanded(
                child: _buildNumericField(
                    _altoController, 'Alto (ft)', Icons.height)),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
                child: _buildNumericField(
                    _spacingController, 'Spacing', Icons.space_bar)),
            const SizedBox(width: 24),
            Expanded(
                child: _buildNumericField(
                    _sheetController, 'Sheet', Icons.layers)),
            const SizedBox(width: 24),
            Expanded(
                child: _buildNumericField(
                    _budgetController,
                    'Presupuesto Máximo',
                    Icons.account_balance_wallet_outlined)),
          ],
        ),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard('Total Materiales',
                  _currencyFormat.format(totalMaterials), Colors.blueGrey),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildSummaryCard('Total Sin Concreto',
                  _currencyFormat.format(totalSConcreto), Colors.green),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildNumericField(_precioVentaController, 'Precio de Venta Sugerido',
            Icons.sell_outlined,
            isCurrency: true),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 22)),
        ],
      ),
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
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (val) {
            if (val == null || val.isEmpty) return 'Requerido';
            final n = int.tryParse(val);
            if (n == null) return 'Inválido';
            if (n < 0) return 'No negativo';
            return null;
          },
          onChanged: (_) => _updatePoleBarnLocal(),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nombre del Producto', style: AppStyles.labelStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          decoration: AppStyles.inputDecoration().copyWith(
            prefixIcon:
                const Icon(Icons.label_outline, size: 20, color: Colors.grey),
            hintText: 'Ej: POLE BARN 30x40x12 @ 10',
          ),
          validator: (val) {
            if (val == null || val.isEmpty) return 'Requerido';
            return null;
          },
          onChanged: (val) {
            _updatePoleBarnLocal();
          },
        ),
      ],
    );
  }

  Widget _buildMaterialsList(
      PoleBarnFormState state, PoleBarnFormNotifier notifier) {
    final materials = state.relatedMaterials;
    if (materials.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Sin materiales asociados',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return Column(
      children: materials.asMap().entries.map((entry) {
        final index = entry.key;
        final m = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(m.materialName ?? 'Cargando...',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                  'Cantidad: ${m.qty} | Medida: ${m.medida} | Precio: ${_currencyFormat.format(m.pricePorUnidad)}',
                  style: const TextStyle(fontSize: 12)),
            ),
            trailing: Text(_currencyFormat.format(m.calculatedTotal),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                    fontSize: 16)),
            onTap: () => _showMaterialDialog(context, index),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showMaterialDialog(BuildContext context, int? index) async {
    final state = ref.read(poleBarnFormProvider(widget.initialPoleBarn));
    final notifier =
        ref.read(poleBarnFormProvider(widget.initialPoleBarn).notifier);
    final rawMaterials = await ref.read(rawMaterialsProvider.future);

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

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, int poleBarnId) async {
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
      await ref.read(poleBarnRepositoryProvider).deletePoleBarn(poleBarnId);
      ref.read(selectedPoleBarnIdProvider.notifier).state =
          null; // Clear selection
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
                      const Text('Total Fila:',
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
          inputFormatters:
              isNumberField ? [FilteringTextInputFormatter.digitsOnly] : null,
          validator: required
              ? (v) => (v == null || (isNumberField && int.tryParse(v) == null))
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
