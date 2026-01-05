import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/client_model.dart';
import '../repositories/client_repository.dart';

class ClientDetailScreen extends ConsumerStatefulWidget {
  final String? clientId;

  const ClientDetailScreen({super.key, this.clientId});

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.clientId != null && widget.clientId != 'new') {
      _loadClient();
    }
  }

  Future<void> _loadClient() async {
    setState(() => _isLoading = true);
    try {
      final client =
          await ref.read(clientRepositoryProvider).getClient(widget.clientId!);
      if (client != null) {
        _nombreController.text = client.nombre;
        _phoneController.text = client.telefono ?? '';
        _emailController.text = client.email ?? '';
        _addressController.text = client.direccion ?? '';
        _notesController.text = client.notas ?? '';
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final client = ClientModel(
        id: widget.clientId == 'new' ? '' : widget.clientId!,
        nombre: _nombreController.text,
        telefono: _phoneController.text,
        email: _emailController.text,
        direccion: _addressController.text,
        notas: _notesController.text,
      );

      final repo = ref.read(clientRepositoryProvider);
      if (widget.clientId == 'new') {
        await repo.createClient(client);
      } else {
        await repo.updateClient(widget.clientId!, client);
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Cliente guardado')));
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.clientId != null && widget.clientId != 'new';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Cliente' : 'Nuevo Cliente'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                          labelText: 'Nombre *', border: OutlineInputBorder()),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                          labelText: 'Teléfono', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                          labelText: 'Email', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                          labelText: 'Dirección', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                          labelText: 'Notas', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        child: Text(isEditing ? 'Actualizar' : 'Crear'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
