import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import '../infrastructure/users_repository.dart';

class UserFormScreen extends ConsumerStatefulWidget {
  final String? userId; // If null, creating new user
  final Map<String, dynamic>? userMetadata; // If editing, pass existing data

  const UserFormScreen({super.key, this.userId, this.userMetadata});

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  String? _selectedRole;
  String? _selectedJobPositionId;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.userMetadata?['name'] ?? '');
    _emailController =
        TextEditingController(text: widget.userMetadata?['email'] ?? '');
    _passwordController = TextEditingController();
    _selectedRole = widget.userMetadata?['role'] ?? 'Trabajador';
    _selectedJobPositionId = widget.userMetadata?['job_position_id'];
    _isActive = widget.userMetadata?['is_active'] ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (widget.userId == null) {
        // Create
        await ref.read(usersRepositoryProvider).registerWorker(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
              name: _nameController.text.trim(),
              role: _selectedRole ?? 'Trabajador',
              jobPositionId: _selectedJobPositionId,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trabajador creado exitosamente')),
          );
          Navigator.pop(context);
        }
      } else {
        // Update
        // Update profile fields
        await ref.read(usersRepositoryProvider).updateUser(
          widget.userId!,
          {
            'name': _nameController.text.trim(),
            'role': _selectedRole,
            'job_position_id': _selectedJobPositionId,
            'is_active': _isActive,
          },
        );

        // Update password if provided
        final newPassword = _passwordController.text.trim();
        if (newPassword.isNotEmpty) {
          await ref.read(usersRepositoryProvider).updatePassword(
                widget.userId!,
                newPassword,
              );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Trabajador actualizado exitosamente')),
          );
          Navigator.pop(context);
        }
      }
      ref.invalidate(allUsersProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.userId != null;
    final jobPositionsAsync = ref.watch(jobPositionsProvider);
    final rolesAsync = ref.watch(appRolesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Trabajador' : 'Nuevo Trabajador'),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.stone200, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.stone200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(Icons.person, 'Información del Perfil'),
                  const SizedBox(height: 24),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _nameController,
                          label: 'Nombre Completo *',
                          hint: 'Ej: Juan Pérez',
                          validator: (v) => v?.trim().isEmpty ?? true
                              ? 'El nombre es obligatorio'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildTextField(
                          controller: _emailController,
                          label: 'Correo Electrónico *',
                          hint: 'correo@ejemplo.com',
                          readOnly:
                              isEditing, // Usually can't change email easily
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'El correo es obligatorio';
                            }
                            if (!v.contains('@')) return 'Email inválido';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: _passwordController,
                    label: isEditing
                        ? 'Nueva Contraseña (Opcional)'
                        : 'Contraseña *',
                    hint: isEditing
                        ? 'Dejar vacío para no cambiar'
                        : 'Mínimo 6 caracteres',
                    isPassword: true,
                    validator: (v) {
                      if (!isEditing && (v?.trim().length ?? 0) < 6) {
                        return 'Mínimo 6 caracteres (Obligatorio)';
                      }
                      if (isEditing && v!.isNotEmpty && v.trim().length < 6) {
                        return 'Mínimo 6 caracteres si desea cambiarla';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 32),

                  _buildSectionHeader(
                      Icons.admin_panel_settings, 'Rol y Acceso'),
                  const SizedBox(height: 24),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: rolesAsync.when(
                          data: (roles) => _buildDropdown(
                            label: 'Rol del Sistema',
                            value: roles.contains(_selectedRole)
                                ? _selectedRole
                                : null,
                            items: roles,
                            onChanged: (v) => setState(() => _selectedRole = v),
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => _buildDropdown(
                            label: 'Rol del Sistema',
                            value: _selectedRole,
                            items: ['Administrador', 'Trabajador'],
                            onChanged: (v) => setState(() => _selectedRole = v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: jobPositionsAsync.when(
                          data: (positions) => _buildDropdown(
                            label: 'Puesto de Trabajo',
                            value: positions.any(
                                    (p) => p['id'] == _selectedJobPositionId)
                                ? _selectedJobPositionId
                                : null,
                            itemsMaps: positions
                                .map((p) => {
                                      'value': p['id'] as String,
                                      'label': p['name'] as String
                                    })
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedJobPositionId = v),
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const SizedBox(),
                        ),
                      ),
                    ],
                  ),

                  // Status Switch (Only for Edit)
                  if (isEditing) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Switch(
                          value: _isActive,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isActive ? 'Usuario Activo' : 'Usuario Inactivo',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(isEditing
                              ? 'Guardar Cambios'
                              : 'Crear Trabajador'),
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

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isPassword = false,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          readOnly: readOnly,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: readOnly ? AppColors.stone100 : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.stone300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.stone300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    List<String>? items,
    List<Map<String, String>>? itemsMaps,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.stone300),
            ),
          ),
          items: itemsMaps != null
              ? itemsMaps
                  .map((m) => DropdownMenuItem(
                      value: m['value'], child: Text(m['label']!)))
                  .toList()
              : items!
                  .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                  .toList(),
        ),
      ],
    );
  }
}
