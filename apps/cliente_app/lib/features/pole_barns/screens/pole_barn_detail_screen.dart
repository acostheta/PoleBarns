import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pole_barn_model.dart';
import '../models/related_material_model.dart';
import '../providers/pole_barn_provider.dart';
import 'package:intl/intl.dart';

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
    super.dispose();
  }

  void _updatePoleBarnLocal() {
    // Solo actualizamos y guardamos si los campos básicos son válidos semánticamente
    // (aunque el Form lo valida visualmente, aquí prevenimos el guardado de basura)
    final largo = double.tryParse(_largoController.text);
    final ancho = double.tryParse(_anchoController.text);
    final alto = double.tryParse(_altoController.text);

    if (largo == null || ancho == null || alto == null) return;

    final notifier =
        ref.read(poleBarnFormProvider(widget.initialPoleBarn).notifier);
    final currentState =
        ref.read(poleBarnFormProvider(widget.initialPoleBarn)).poleBarn;

    notifier.updatePoleBarnField(currentState.copyWith(
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

    // HU-01: Los campos Total deben venir del stream del Trigger
    final parentStream = state.poleBarn.id != null
        ? ref.watch(poleBarnStreamProvider(state.poleBarn.id!)).value
        : null;

    // For immediate "automatic" feedback while editing materials, we use local calculations.
    // The stream is still used for server-side fields like alertStatus.
    final displayTotalMaterials = state.localTotalMaterials;
    final displayTotalSConcreto = state.localTotalSConcreto;

    // Alert status: If local total exceeds budget, show alert even if stream hasn't updated.
    String displayAlertStatus =
        parentStream?.alertStatus ?? state.poleBarn.alertStatus;
    if (displayTotalMaterials > state.poleBarn.budgetLimit &&
        state.poleBarn.budgetLimit > 0) {
      displayAlertStatus =
          "ALERTA LOCAL: Presupuesto excedido ($displayTotalMaterials > ${state.poleBarn.budgetLimit})";
    }

    // Sincronizar controlador de precio venta si no ha sido editado manualmente
    if (!state.isPriceManuallyEdited && state.poleBarn.id == null) {
      _precioVentaController.text = state.poleBarn.precioVenta.toString();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(state.poleBarn.id == null
            ? 'Catálogo: Nueva Caballeriza'
            : 'Catálogo: Editar Caballeriza'),
        actions: [
          if (state.isSaving || state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Icon(Icons.cloud_done, color: Colors.white70),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.error != null) _buildErrorBanner(state.error!),
              if (displayAlertStatus != 'OK')
                _buildAlertBanner(displayAlertStatus),
              _buildMainForm(displayTotalMaterials, displayTotalSConcreto),
              const SizedBox(height: 32),
              const Text(
                'Materiales (HU-02 - Realtime)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              _buildMaterialsList(state, notifier),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _showMaterialDialog(context, null),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Material al Catálogo'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(msg,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMainForm(double totalMaterials, double totalSConcreto) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildNumericField(
                        _largoController, 'Largo (ft)', Icons.straighten)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildNumericField(
                        _anchoController, 'Ancho (ft)', Icons.straighten)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _buildNumericField(
                        _altoController, 'Alto (ft)', Icons.height)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildNumericField(
                        _spacingController, 'Spacing', Icons.space_bar)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _buildNumericField(
                        _sheetController, 'Sheet', Icons.layers)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildNumericField(_budgetController,
                        'Presupuesto Máximo', Icons.money_off)),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildReadOnlyField('Total Materiales (Admin Only)',
                _currencyFormat.format(totalMaterials), Colors.blueGrey),
            const SizedBox(height: 8),
            _buildReadOnlyField('Total Sin Concreto',
                _currencyFormat.format(totalSConcreto), Colors.green),
            const SizedBox(height: 16),
            _buildNumericField(_precioVentaController,
                'Precio de Venta Sugerido', Icons.attach_money,
                isCurrency: true),
          ],
        ),
      ),
    );
  }

  Widget _buildNumericField(
      TextEditingController controller, String label, IconData icon,
      {bool isCurrency = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Requerido';
        final n = double.tryParse(val);
        if (n == null) return 'Número inválido';
        if (n < 0) return 'No puede ser negativo';
        return null;
      },
      onChanged: (_) => _updatePoleBarnLocal(),
    );
  }

  Widget _buildReadOnlyField(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildMaterialsList(
      PoleBarnFormState state, PoleBarnFormNotifier notifier) {
    // We prioritize local state to ensure the UI is snappy and reflects changes
    // immediately when adding/editing before saving.
    return _buildMaterialsTable(state.relatedMaterials, notifier);
  }

  Widget _buildMaterialsTable(
      List<RelatedMaterial> materials, PoleBarnFormNotifier notifier) {
    if (materials.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(
            child: Text('Sin materiales asociados',
                style: TextStyle(color: Colors.grey))),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: materials.length,
      itemBuilder: (context, index) {
        final m = materials[index];
        return ListTile(
          title: Text(m.materialName ?? 'Cargando...',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
              'Qty: ${m.qty} | Medida: ${m.medida} | Price: ${_currencyFormat.format(m.pricePorUnidad)}'),
          trailing: Text(_currencyFormat.format(m.calculatedTotal),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.indigo)),
          onTap: () => _showMaterialDialog(context, index),
        );
      },
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
      if (index == null)
        notifier.addMaterial(result);
      else
        notifier.updateMaterial(index, result);
    }
  }

  Widget _buildErrorBanner(String msg) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(msg,
                style: const TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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

    return AlertDialog(
      title: const Text('Configurar Material (HU-02)'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedId,
                isExpanded: true,
                validator: (v) => v == null ? 'Seleccione material' : null,
                decoration:
                    const InputDecoration(labelText: 'Material de Catálogo'),
                items: widget.rawMaterials
                    .map((m) => DropdownMenuItem<String>(
                        value: m['id'] as String, child: Text(m['name'])))
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
              const SizedBox(height: 16),
              TextFormField(
                  controller: _qtyController,
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => (v == null || double.tryParse(v) == null)
                      ? 'Numérico requerido'
                      : null,
                  onChanged: (_) => setState(() {})),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _medidaController,
                  decoration: const InputDecoration(labelText: 'Medida (Auto)'),
                  readOnly: true),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _priceController,
                  decoration:
                      const InputDecoration(labelText: 'Precio Unitario'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => (v == null || double.tryParse(v) == null)
                      ? 'Numérico requerido'
                      : null,
                  onChanged: (_) => setState(() {})),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _wasteController,
                  decoration:
                      const InputDecoration(labelText: 'Desperdicio (%)'),
                  validator: (v) => (v == null || double.tryParse(v) == null)
                      ? 'Numérico requerido'
                      : null,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 24),
              _buildRow('Total Fila (con Desperdicio):',
                  NumberFormat.currency(symbol: r'$').format(rowTotal)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
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
                    wastePercent: double.tryParse(_wasteController.text) ?? 0,
                    pricePorUnidad: double.tryParse(_priceController.text) ?? 0,
                  ));
            }
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(val,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.indigo)),
      ],
    );
  }
}
