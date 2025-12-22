import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:design_system/design_system.dart';
import '../infrastructure/raw_materials_repository.dart';
import 'package:measures/measures.dart';

class RawMaterialsScreen extends ConsumerStatefulWidget {
  const RawMaterialsScreen({super.key});

  @override
  ConsumerState<RawMaterialsScreen> createState() => _RawMaterialsScreenState();
}

class _RawMaterialsScreenState extends ConsumerState<RawMaterialsScreen> {
  String? _selectedMaterialId;
  String _searchQuery = '';

  Future<void> _createNewMaterial(List<Map<String, dynamic>> measures) async {
    if (measures.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('No hay medidas disponibles. Crea una medida primero.')),
      );
      return;
    }

    try {
      // Create a placeholder material immediately
      // Default to the first measure found
      final newId =
          await ref.read(rawMaterialsRepositoryProvider).createRawMaterial(
                name: 'Nueva Materia Prima',
                measureId: measures.first['id'],
                coverage: 0,
                cost: 0,
                price: 0,
              );

      setState(() {
        _selectedMaterialId = newId;
      });

      ref.invalidate(rawMaterialsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawMaterialsAsync = ref.watch(rawMaterialsProvider);
    final measuresAsync = ref.watch(measuresProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return rawMaterialsAsync.when(
      data: (materials) {
        final filteredMaterials = materials.where((m) {
          final name = (m['name'] as String? ?? '').toLowerCase();
          final q = _searchQuery.toLowerCase();
          return name.contains(q);
        }).toList();

        final selectedMaterial = _selectedMaterialId != null
            ? materials.firstWhere(
                (m) => m['id'] == _selectedMaterialId,
                orElse: () => <String, dynamic>{},
              )
            : null;

        return Container(
          color: AppColors.backgroundLight,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Materia Prima',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                    measuresAsync.when(
                      data: (measures) => ElevatedButton.icon(
                        onPressed: () => _createNewMaterial(measures),
                        icon: const Icon(Icons.add),
                        label: const Text('Nueva Materia Prima'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const SizedBox(),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sidebar List
                    Container(
                      width: 350,
                      margin: const EdgeInsets.only(left: 24, bottom: 24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.stone200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Search Bar
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.stone100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextField(
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val;
                                  });
                                },
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.search,
                                      color: AppColors.stone400),
                                  hintText: 'Buscar materia prima...',
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ),

                          // List
                          Expanded(
                            child: filteredMaterials.isEmpty
                                ? const Center(
                                    child: Text('No se encontraron resultados'))
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    itemCount: filteredMaterials.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final material = filteredMaterials[index];
                                      final isSelected =
                                          material['id'] == _selectedMaterialId;

                                      return Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedMaterialId =
                                                  material['id'];
                                            });
                                          },
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColors.accentGreenLight
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: isSelected
                                                  ? const Border(
                                                      left: BorderSide(
                                                          color: AppColors
                                                              .accentGreen,
                                                          width: 4))
                                                  : Border.all(
                                                      color:
                                                          Colors.transparent),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  material['name'] ??
                                                      'Sin nombre',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: isSelected
                                                        ? AppColors
                                                            .accentGreenDark
                                                        : AppColors.textLight,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${currencyFormat.format(material['cost'] ?? 0)} - ${currencyFormat.format(material['price'] ?? 0)}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: isSelected
                                                        ? AppColors.accentGreen
                                                        : AppColors.stone500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),

                    // Detail Panel
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: (selectedMaterial != null &&
                                selectedMaterial.isNotEmpty)
                            ? RawMaterialDetailPanel(
                                key: ValueKey(selectedMaterial['id']),
                                initialData: selectedMaterial,
                                onDeleted: () {
                                  setState(() {
                                    _selectedMaterialId = null;
                                  });
                                },
                              )
                            : _buildEmptyState(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.stone200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.stone50,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.stone100),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                size: 64, color: AppColors.stone300),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ninguna materia prima seleccionada',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecciona una del listado o crea una nueva.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.stone500),
          ),
        ],
      ),
    );
  }
}

class RawMaterialDetailPanel extends ConsumerStatefulWidget {
  final Map<String, dynamic> initialData;
  final VoidCallback onDeleted;

  const RawMaterialDetailPanel({
    super.key,
    required this.initialData,
    required this.onDeleted,
  });

  @override
  ConsumerState<RawMaterialDetailPanel> createState() =>
      _RawMaterialDetailPanelState();
}

class _RawMaterialDetailPanelState
    extends ConsumerState<RawMaterialDetailPanel> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _coverageController;
  late TextEditingController _costController;
  late TextEditingController _priceController;
  late TextEditingController _measureController; // For DropdownMenu
  String? _selectedMeasureId;

  Timer? _debounce;
  final _currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData['name']);
    _coverageController =
        TextEditingController(text: widget.initialData['coverage']?.toString());

    final double initialCost =
        (widget.initialData['cost'] as num?)?.toDouble() ?? 0.0;
    final double initialPrice =
        (widget.initialData['price'] as num?)?.toDouble() ?? 0.0;

    _costController = TextEditingController(
        text: initialCost > 0 ? _currencyFormat.format(initialCost) : '');
    _priceController = TextEditingController(
        text: initialPrice > 0 ? _currencyFormat.format(initialPrice) : '');

    _selectedMeasureId = widget.initialData['measure_id'];
    _measureController =
        TextEditingController(); // Will set text when measures load if needed
  }

  @override
  void dispose() {
    _nameController.dispose();
    _coverageController.dispose();
    _costController.dispose();
    _priceController.dispose();
    _measureController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Auto-save logic
  void _onFieldChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _save);
  }

  double _parseCurrency(String value) {
    if (value.isEmpty) return 0.0;
    String cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  Future<void> _save() async {
    if (!mounted) return;
    // Basic validation implies fields shouldn't be empty if required,
    // but for auto-save we might save partial valid state.
    // However the prompt implies mandatory fields.
    // If name is empty, we probably shouldn't save or should warn.
    // For now we persist if valid.

    // Note: We don't use form validation blocker here heavily because it interrupts typing.
    // But we should ensure we don't save broken data.

    final name = _nameController.text;
    if (name.isEmpty) return;

    final coverage =
        double.tryParse(_coverageController.text.replaceAll(',', '')) ?? 0.0;
    final cost = _parseCurrency(_costController.text);
    final price = _parseCurrency(_priceController.text);
    final measureId = _selectedMeasureId;

    if (measureId == null) return;

    try {
      await ref.read(rawMaterialsRepositoryProvider).updateRawMaterial(
            id: widget.initialData['id'],
            name: name,
            measureId: measureId,
            coverage: coverage,
            cost: cost,
            price: price,
          );
      ref.invalidate(rawMaterialsProvider);
    } catch (e) {
      debugPrint('Error saving: $e');
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Está seguro de eliminar esta materia prima?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(rawMaterialsRepositoryProvider)
            .deleteRawMaterial(widget.initialData['id']);
        ref.invalidate(rawMaterialsProvider);
        widget.onDeleted();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final measuresAsync = ref.watch(measuresProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.stone200),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Editar Materia Prima',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                  ),
                ),
                IconButton(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Eliminar',
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Name
            _buildTextField(
              controller: _nameController,
              label: 'Nombre',
              hint: 'Nombre del producto',
              onChanged: (_) => _onFieldChanged(),
            ),
            const SizedBox(height: 16),

            // Measure DropdownMenu
            measuresAsync.when(
              data: (measures) {
                // Set initial text if needed only once
                // If we have an ID but controller is empty, find name
                if (_selectedMeasureId != null &&
                    _measureController.text.isEmpty) {
                  final m = measures.firstWhere(
                      (e) => e['id'] == _selectedMeasureId,
                      orElse: () => {});
                  if (m.isNotEmpty) {
                    _measureController.text = m['name'];
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Medida',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    LayoutBuilder(builder: (context, constraints) {
                      return DropdownMenu<String>(
                        width: constraints.maxWidth,
                        controller: _measureController,
                        enableFilter: true, // Enables searching
                        requestFocusOnTap: true,
                        label: const Text('Seleccionar medida'),
                        initialSelection: _selectedMeasureId,
                        dropdownMenuEntries:
                            measures.map<DropdownMenuEntry<String>>((m) {
                          return DropdownMenuEntry<String>(
                            value: m['id'],
                            label: m['name'],
                          );
                        }).toList(),
                        onSelected: (String? val) {
                          if (val != null) {
                            _selectedMeasureId = val;
                            _onFieldChanged();
                          }
                        },
                      );
                    }),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, s) => Text('Error al cargar medidas: $e'),
            ),
            const SizedBox(height: 16),

            // Coverage
            _buildTextField(
              controller: _coverageController,
              label: 'Cuánto Cubre por 1 Medida',
              hint: '0.0',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _onFieldChanged(),
            ),
            const SizedBox(height: 16),

            // Pricing Row
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _costController,
                    label: 'Costo',
                    hint: '\$0.00',
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    onChanged: (_) => _onFieldChanged(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _priceController,
                    label: 'Precio de venta',
                    hint: '\$0.00',
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    onChanged: (_) => _onFieldChanged(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.stone100,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.stone300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.stone300)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    double value = double.parse(newText) / 100;
    final formatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    String formatted = formatter.format(value);

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
