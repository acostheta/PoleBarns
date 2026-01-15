import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/app_styles.dart';
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
  final _apellidoController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  String? _photoUrl;
  bool _isLoading = false;
  bool _isUploading = false;

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
        _nombreController.text = client.firstName;
        _apellidoController.text = client.lastName;
        _phoneController.text = client.telefono ?? '';
        _emailController.text = client.email ?? '';
        _addressController.text = client.direccion ?? '';
        _notesController.text = client.notas ?? '';
        _photoUrl = client.photoUrl;
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
        firstName: _nombreController.text,
        lastName: _apellidoController.text,
        telefono: _phoneController.text,
        email: _emailController.text,
        direccion: _addressController.text,
        notas: _notesController.text,
        photoUrl: _photoUrl,
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

  Future<void> _pickAndUploadImage() async {
    debugPrint('*** CLICK DETECTED ***');
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await picked.readAsBytes();
      debugPrint('Image picked: ${bytes.length} bytes');

      final fileName = 'clients/${DateTime.now().millisecondsSinceEpoch}.jpg';

      debugPrint('Uploading to avatars/$fileName');
      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(fileName, bytes);

      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);

      debugPrint('Upload success: $publicUrl');
      setState(() {
        _photoUrl = publicUrl;
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto subida. No olvides guardar.')),
        );
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir foto: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.clientId != null && widget.clientId != 'new';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Cliente' : 'Nuevo Cliente',
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _isUploading
                                          ? null
                                          : _pickAndUploadImage,
                                      borderRadius: BorderRadius.circular(60),
                                      child: CircleAvatar(
                                        radius: 60,
                                        backgroundColor:
                                            const Color(0xFFF3F4F6),
                                        backgroundImage: _photoUrl != null
                                            ? NetworkImage(_photoUrl!)
                                            : null,
                                        child: _photoUrl == null &&
                                                !_isUploading
                                            ? const Icon(Icons.person,
                                                size: 60,
                                                color: Color(0xFF9CA3AF))
                                            : _isUploading
                                                ? const CircularProgressIndicator()
                                                : null,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Material(
                                      color: const Color(0xFFD97706),
                                      shape: const CircleBorder(),
                                      child: InkWell(
                                        onTap: _isUploading
                                            ? null
                                            : _pickAndUploadImage,
                                        customBorder: const CircleBorder(),
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(Icons.camera_alt,
                                              size: 20, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed:
                                    _isUploading ? null : _pickAndUploadImage,
                                icon: const Icon(Icons.upload),
                                label: const Text('Cambiar Foto'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),
                        const Text('Información del Cliente',
                            style: AppStyles.dialogTitleStyle),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                  'Nombre *', _nombreController,
                                  required: true),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildTextField(
                                  'Apellido *', _apellidoController,
                                  required: true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                                child: _buildTextField(
                                    'Teléfono', _phoneController,
                                    keyboardType: TextInputType.phone)),
                            const SizedBox(width: 24),
                            Expanded(
                                child: _buildTextField(
                                    'Email', _emailController,
                                    keyboardType: TextInputType.emailAddress)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildTextField('Dirección', _addressController),
                        const SizedBox(height: 24),
                        _buildTextField('Notas', _notesController, maxLines: 4),
                        const SizedBox(height: 48),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _save,
                            style: AppStyles.primaryButtonStyle,
                            child: Text(isEditing
                                ? 'Actualizar Cliente'
                                : 'Crear Cliente'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool required = false, TextInputType? keyboardType, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.labelStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          keyboardType: keyboardType,
          validator: required
              ? (v) => v == null || v.isEmpty ? 'Requerido' : null
              : null,
          decoration: AppStyles.inputDecoration(),
        )
      ],
    );
  }
}
