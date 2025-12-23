import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/settings_repository.dart';
import '../models/provider_model.dart';

class ProvidersTab extends ConsumerWidget {
  const ProvidersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(providersListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProviderDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: providersAsync.when(
        data: (providers) {
          if (providers.isEmpty) {
            return const Center(child: Text('No hay proveedores registrados.'));
          }
          return ListView.builder(
            itemCount: providers.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final provider = providers[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                      child: Text(provider.name.substring(0, 1).toUpperCase())),
                  title: Text(provider.name),
                  subtitle: Text(provider.address),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showProviderDialog(context, ref,
                            provider: provider),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirmar'),
                              content: const Text(
                                  '¿Estás seguro de eliminar este proveedor?'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancelar')),
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Eliminar')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ref
                                .read(settingsRepositoryProvider)
                                .deleteProvider(provider.id);
                            ref.invalidate(providersListProvider);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showProviderDialog(BuildContext context, WidgetRef ref,
      {ProviderModel? provider}) {
    final nameController = TextEditingController(text: provider?.name ?? '');
    final addressController =
        TextEditingController(text: provider?.address ?? '');
    final isEditing = provider != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Editar Proveedor' : 'Nuevo Proveedor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Dirección')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nombre es requerido')),
                );
                return;
              }

              try {
                if (provider != null) {
                  final updated = provider.copyWith(
                    name: nameController.text,
                    address: addressController.text,
                  );
                  await ref
                      .read(settingsRepositoryProvider)
                      .updateProvider(updated);
                } else {
                  await ref.read(settingsRepositoryProvider).createProvider(
                        nameController.text,
                        addressController.text,
                      );
                }
                ref.invalidate(providersListProvider);
                if (context.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al guardar: $e')),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
