import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import '../infrastructure/users_repository.dart';

class JobPositionsScreen extends ConsumerStatefulWidget {
  const JobPositionsScreen({super.key});

  @override
  ConsumerState<JobPositionsScreen> createState() => _JobPositionsScreenState();
}

class _JobPositionsScreenState extends ConsumerState<JobPositionsScreen> {

  @override
  Widget build(BuildContext context) {
    final positionsAsync = ref.watch(jobPositionsProvider);

    return Container(
      color: AppColors.backgroundLight,
      child: Column(
        children: [
          // Premium Branded Header
          Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0x0D000000))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 4, height: 24, decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 12),
                        const Text(
                          'Puestos de Trabajo',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: -0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Administra las categorías de cargos para el personal', style: TextStyle(color: AppColors.primary.withValues(alpha: 0.5), fontSize: 14)),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () => _showPositionDialog(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('NUEVO PUESTO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: positionsAsync.when(
                data: (positions) {
                  if (positions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.03), shape: BoxShape.circle),
                            child: Icon(Icons.work_outline_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.1)),
                          ),
                          const SizedBox(height: 24),
                          Text('No hay puestos registrados', style: TextStyle(color: AppColors.primary.withValues(alpha: 0.4), fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          Text('Comienza agregando un nuevo puesto de trabajo', style: TextStyle(color: AppColors.primary.withValues(alpha: 0.3), fontSize: 14)),
                        ],
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: ListView.separated(
                        itemCount: positions.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.black.withValues(alpha: 0.03), indent: 24, endIndent: 24),
                        itemBuilder: (context, index) {
                          final pos = positions[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.business_center_outlined, color: AppColors.secondary, size: 20),
                            ),
                            title: Text(pos['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildActionButton(
                                  icon: Icons.edit_outlined,
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  onPressed: () => _showPositionDialog(context, position: pos),
                                  tooltip: 'Editar',
                                ),
                                const SizedBox(width: 8),
                                _buildActionButton(
                                  icon: Icons.delete_outline_rounded,
                                  color: Colors.redAccent.withValues(alpha: 0.6),
                                  onPressed: () => _confirmDelete(context, pos),
                                  tooltip: 'Eliminar',
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onPressed, required String tooltip}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(border: Border.all(color: color.withValues(alpha: 0.1)), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  void _showPositionDialog(BuildContext context, {Map<String, dynamic>? position}) {
    final isEditing = position != null;
    final controller = TextEditingController(text: isEditing ? position['name'] : '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, 20))]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
                child: Row(
                  children: [
                    const Icon(Icons.work_outline_rounded, color: Colors.white70, size: 24),
                    const SizedBox(width: 16),
                    Text(isEditing ? 'Editar Puesto' : 'Nuevo Puesto', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nombre del Puesto', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary.withValues(alpha: 0.7))),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: controller,
                        autofocus: true,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'ej. Carpintero, Capataz',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.secondary, width: 2)),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'El nombre es obligatorio' : null,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black45))),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          try {
                            final name = controller.text.trim();
                            if (isEditing) {
                              await ref.read(usersRepositoryProvider).updateJobPosition(position['id'], name);
                            } else {
                              await ref.read(usersRepositoryProvider).createJobPosition(name);
                            }
                            ref.invalidate(jobPositionsProvider);
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
                          }
                        }
                      },
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text(isEditing ? 'GUARDAR' : 'CREAR PUESTO', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Eliminar Puesto', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        content: Text('¿Está seguro de que desea eliminar "${position['name']}"? Esta acción no se puede deshacer y fallará si hay usuarios asignados.', style: const TextStyle(fontSize: 15)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold))),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(usersRepositoryProvider).deleteJobPosition(position['id']);
                ref.invalidate(jobPositionsProvider);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) Navigator.pop(context);
                final errString = e.toString().toLowerCase();
                if (errString.contains('foreign key constraint')) {
                  _showErrorDialog(context, 'No se puede eliminar', 'Este puesto está asignado a usuarios activos. Reasígnalos primero.');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
                }
              }
            },
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ENTENDIDO', style: TextStyle(fontWeight: FontWeight.bold)))]),
    );
  }
}
