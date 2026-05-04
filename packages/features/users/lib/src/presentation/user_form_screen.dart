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
    _nameController = TextEditingController(text: widget.userMetadata?['name'] ?? '');
    _emailController = TextEditingController(text: widget.userMetadata?['email'] ?? '');
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
        await ref.read(usersRepositoryProvider).registerWorker(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
              name: _nameController.text.trim(),
              role: _selectedRole ?? 'Trabajador',
              jobPositionId: _selectedJobPositionId,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trabajador creado exitosamente'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        await ref.read(usersRepositoryProvider).updateUser(
          widget.userId!,
          {
            'name': _nameController.text.trim(),
            'role': _selectedRole,
            'job_position_id': _selectedJobPositionId,
            'is_active': _isActive,
          },
        );

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
              content: Text('Trabajador actualizado exitosamente'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      }
      ref.invalidate(allUsersProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
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
        title: Text(isEditing ? 'Editar Trabajador' : 'Nuevo Trabajador', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.black.withValues(alpha: 0.05), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBrandedCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(Icons.person_outline, 'Información del Perfil'),
                        const SizedBox(height: 32),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _nameController,
                                label: 'Nombre Completo',
                                hint: 'Ej: Juan Pérez',
                                icon: Icons.badge_outlined,
                                validator: (v) => v?.trim().isEmpty ?? true ? 'El nombre es obligatorio' : null,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildTextField(
                                controller: _emailController,
                                label: 'Correo Electrónico',
                                hint: 'correo@ejemplo.com',
                                icon: Icons.email_outlined,
                                readOnly: isEditing,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'El correo es obligatorio';
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
                          label: isEditing ? 'Nueva Contraseña (Opcional)' : 'Contraseña de Acceso',
                          hint: isEditing ? 'Dejar vacío para no cambiar' : 'Mínimo 6 caracteres',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          validator: (v) {
                            if (!isEditing && (v?.trim().length ?? 0) < 6) return 'Mínimo 6 caracteres';
                            if (isEditing && v!.isNotEmpty && v.trim().length < 6) return 'Mínimo 6 caracteres';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildBrandedCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(Icons.admin_panel_settings_outlined, 'Rol y Puesto de Trabajo'),
                        const SizedBox(height: 32),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: rolesAsync.when(
                                data: (roles) => _buildDropdown(
                                  label: 'Rol del Sistema',
                                  value: roles.contains(_selectedRole) ? _selectedRole : null,
                                  items: roles,
                                  onChanged: (v) => setState(() => _selectedRole = v),
                                ),
                                loading: () => const LinearProgressIndicator(color: AppColors.primary),
                                error: (_, __) => const SizedBox(),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: jobPositionsAsync.when(
                                data: (positions) => _buildDropdown(
                                  label: 'Puesto de Trabajo',
                                  value: positions.any((p) => p['id'] == _selectedJobPositionId) ? _selectedJobPositionId : null,
                                  itemsMaps: positions.map((p) => {'value': p['id'] as String, 'label': p['name'] as String}).toList(),
                                  onChanged: (v) => setState(() => _selectedJobPositionId = v),
                                ),
                                loading: () => const LinearProgressIndicator(color: AppColors.primary),
                                error: (_, __) => const SizedBox(),
                              ),
                            ),
                          ],
                        ),
                        if (isEditing) ...[
                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Transform.scale(
                                scale: 0.9,
                                child: Switch(
                                  value: _isActive,
                                  activeColor: AppColors.primary,
                                  onChanged: (v) => setState(() => _isActive = v),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isActive ? 'Usuario Activo' : 'Usuario Inactivo',
                                style: TextStyle(fontWeight: FontWeight.bold, color: _isActive ? AppColors.primary : Colors.redAccent),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isEditing ? 'GUARDAR CAMBIOS' : 'CREAR TRABAJADOR', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandedCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppColors.secondary, size: 20),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool isPassword = false,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary.withValues(alpha: 0.7))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          readOnly: readOnly,
          validator: validator,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.3), fontSize: 14),
            prefixIcon: Icon(icon, color: AppColors.primary.withValues(alpha: 0.4), size: 20),
            filled: true,
            fillColor: readOnly ? AppColors.backgroundLight : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.secondary, width: 2)),
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
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary.withValues(alpha: 0.7))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.primary),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.secondary, width: 2)),
          ),
          items: itemsMaps != null
              ? itemsMaps.map((m) => DropdownMenuItem(value: m['value'], child: Text(m['label']!))).toList()
              : items!.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        ),
      ],
    );
  }
}
