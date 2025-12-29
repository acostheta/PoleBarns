import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
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
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddDialog(context, ref),
                icon: const Icon(Icons.add_business, size: 16),
                label: const Text('Asociar Caballeriza'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          barnsAsync.when(
            data: (barns) {
              if (barns.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      'No hay caballerizas asociadas a este proyecto.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: barns.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final barn = barns[index];
                  return _PoleBarnRow(barn: barn, currency: currency);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, __) => Text('Error: $e'),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E5E4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.architecture, color: Color(0xFFD97706)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  barn.poleBarnName ?? 'Pole Barn #${barn.poleBarnId}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'ID: ${barn.poleBarnId}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Precio de Venta',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text(
                currency.format(barn.salePrice),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF15803D),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
            onPressed: () => _showEditPriceDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
            onPressed: () => _delete(ref),
          ),
        ],
      ),
    );
  }

  void _showEditPriceDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: barn.salePrice.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Precio de Venta'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Nuevo Precio',
            prefixText: r'$ ',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final newPrice = double.tryParse(controller.text) ?? 0;
              await ref
                  .read(projectRepositoryProvider)
                  .updateProjectPoleBarnPrice(barn.id, newPrice);
              ref.invalidate(projectPoleBarnsProvider(barn.projectId));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(WidgetRef ref) async {
    await ref.read(projectRepositoryProvider).deleteProjectPoleBarn(barn.id);
    ref.invalidate(projectPoleBarnsProvider(barn.projectId));
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

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(poleBarnsCatalogProvider);

    return AlertDialog(
      title: const Text('Asociar Caballeriza del Catálogo'),
      content: SizedBox(
        width: 400,
        child: catalogAsync.when(
          data: (catalog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  hint: const Text('Seleccionar Caballeriza'),
                  value: _selectedBarnId,
                  items: catalog.map((b) {
                    return DropdownMenuItem<int>(
                      value: b['id'],
                      child: Text(b['name'] ?? 'ID: ${b['id']}'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    final barn = catalog.firstWhere((b) => b['id'] == val);
                    setState(() {
                      _selectedBarnId = val;
                      _salePrice =
                          (barn['precio_venta'] as num?)?.toDouble() ?? 0.0;
                    });
                  },
                ),
                const SizedBox(height: 24),
                if (_selectedBarnId != null)
                  TextFormField(
                    initialValue: _salePrice.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Precio de Venta Sugerido',
                      prefixText: r'$ ',
                    ),
                    onChanged: (val) {
                      _salePrice = double.tryParse(val) ?? 0;
                    },
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, __) => Text('Error: $e'),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: (_selectedBarnId == null || _isSaving) ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Asociar'),
        ),
      ],
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
