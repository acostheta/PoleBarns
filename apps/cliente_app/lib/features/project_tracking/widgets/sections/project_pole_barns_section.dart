import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../config/app_styles.dart';
import '../../models/project_models.dart';
import '../../providers/project_providers.dart';

class ProjectPoleBarnsSection extends ConsumerWidget {
  final String projectId;

  const ProjectPoleBarnsSection({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barnsAsync = ref.watch(projectPoleBarnsProvider(projectId));
    final currency = NumberFormat.simpleCurrency();

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estructuras (Pole Barns)',
                style: AppStyles.dialogTitleStyle,
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddDialog(context, ref),
                icon: const Icon(Icons.add_home_work_outlined, size: 18),
                label: const Text('Asociar Caballeriza'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppStyles.primaryOrange.withValues(alpha: 0.1),
                  foregroundColor: AppStyles.primaryOrange,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 24),
          barnsAsync.when(
            data: (barns) {
              if (barns.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.house_siding_outlined,
                          size: 48, color: Colors.grey.shade200),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay caballerizas asociadas.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: barns
                    .map((barn) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PoleBarnRow(barn: barn, currency: currency),
                        ))
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, __) =>
                Text('Error: $e', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _AddPoleBarnDialog(projectId: projectId),
    );
  }
}

class _PoleBarnRow extends ConsumerWidget {
  final ProjectPoleBarnModel barn;
  final NumberFormat currency;

  const _PoleBarnRow({required this.barn, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppStyles.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.architecture_rounded,
                color: AppStyles.primaryOrange, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  barn.poleBarnName ?? 'Pole Barn #${barn.poleBarnId}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF111827)),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID Catálogo: ${barn.poleBarnId}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('PRECIO VENTA',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(
                currency.format(barn.salePrice),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF047857),
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 20, color: Colors.blueGrey),
            onPressed: () => _showEditPriceDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 20, color: Colors.redAccent),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar Asociación'),
        content: const Text(
            '¿Está seguro de que desea desvincular esta caballeriza del proyecto?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(projectRepositoryProvider).deleteProjectPoleBarn(barn.id);
      ref.invalidate(projectPoleBarnsProvider(barn.projectId));
    }
  }

  void _showEditPriceDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: barn.salePrice.toString());
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Editar Precio de Venta',
                  style: AppStyles.dialogTitleStyle),
              const SizedBox(height: 32),
              const Text('Precio de Venta', style: AppStyles.labelStyle),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 14),
                decoration: AppStyles.inputDecoration().copyWith(
                  prefixText: r'$ ',
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final newPrice = double.tryParse(controller.text) ?? 0;
                    await ref
                        .read(projectRepositoryProvider)
                        .updateProjectPoleBarnPrice(barn.id, newPrice);
                    ref.invalidate(projectPoleBarnsProvider(barn.projectId));
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: AppStyles.primaryButtonStyle,
                  child: const Text('Guardar Cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddPoleBarnDialog extends ConsumerStatefulWidget {
  final String projectId;
  const _AddPoleBarnDialog({required this.projectId});

  @override
  ConsumerState<_AddPoleBarnDialog> createState() => _AddPoleBarnDialogState();
}

class _AddPoleBarnDialogState extends ConsumerState<_AddPoleBarnDialog> {
  int? _selectedBarnId;
  double _salePrice = 0;
  bool _isSaving = false;
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(poleBarnsCatalogProvider);

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Asociar Caballeriza',
                  style: AppStyles.dialogTitleStyle),
              const SizedBox(height: 32),
              const Text('Seleccionar del Catálogo',
                  style: AppStyles.labelStyle),
              const SizedBox(height: 8),
              catalogAsync.when(
                data: (catalog) {
                  return DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: _selectedBarnId,
                    decoration: AppStyles.inputDecoration(),
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: catalog.map<DropdownMenuItem<int>>((b) {
                      return DropdownMenuItem<int>(
                        value: b['id'],
                        child: Text(b['name'] ?? 'ID: ${b['id']}',
                            style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      final barn = catalog.firstWhere((b) => b['id'] == val);
                      setState(() {
                        _selectedBarnId = val;
                        _salePrice =
                            (barn['precio_venta'] as num?)?.toDouble() ?? 0.0;
                        _priceController.text = _salePrice.toString();
                      });
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, __) => Text('Error: $e',
                    style: const TextStyle(color: Colors.red)),
              ),
              if (_selectedBarnId != null) ...[
                const SizedBox(height: 24),
                const Text('Precio de Venta Sugerido',
                    style: AppStyles.labelStyle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 14),
                  decoration: AppStyles.inputDecoration().copyWith(
                    prefixText: r'$ ',
                  ),
                  onChanged: (val) {
                    _salePrice = double.tryParse(val) ?? 0;
                  },
                ),
              ],
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (_selectedBarnId == null || _isSaving) ? null : _submit,
                  style: AppStyles.primaryButtonStyle,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Asociar al Proyecto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(projectRepositoryProvider).addProjectPoleBarn(
            widget.projectId,
            _selectedBarnId!,
            _salePrice,
          );
      ref.invalidate(projectPoleBarnsProvider(widget.projectId));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isSaving = false);
      }
    }
  }
}
