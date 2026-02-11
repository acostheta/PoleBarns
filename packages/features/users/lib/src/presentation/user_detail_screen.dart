import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import '../infrastructure/users_repository.dart';
import 'user_form_screen.dart';

class UserDetailScreen extends ConsumerWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    final jobPositionsAsync = ref.watch(jobPositionsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Detalles del Trabajador'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              final user = usersAsync.value
                  ?.firstWhere((u) => u['id'] == userId, orElse: () => {});
              if (user != null && user.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          UserFormScreen(userId: userId, userMetadata: user)),
                );
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.stone200, height: 1),
        ),
      ),
      body: usersAsync.when(
        data: (users) {
          final user =
              users.firstWhere((u) => u['id'] == userId, orElse: () => {});
          if (user.isEmpty)
            return const Center(child: Text('Usuario no encontrado'));

          final isActive = user['is_active'] as bool? ?? false;
          final role = user['role'] as String? ?? 'Sin asigar';
          final jobPositionId = user['job_position_id'] as String?;

          String jobPositionName = 'Sin puesto';
          if (jobPositionsAsync.value != null) {
            final pos = jobPositionsAsync.value!
                .firstWhere((p) => p['id'] == jobPositionId, orElse: () => {});
            if (pos.isNotEmpty) jobPositionName = pos['name'];
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Profile Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.stone200),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.stone200,
                              shape: BoxShape.circle,
                              image: user['picture'] != null
                                  ? DecorationImage(
                                      image: NetworkImage(user['picture']),
                                      fit: BoxFit.cover)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: user['picture'] == null
                                ? Text((user['name'] ?? 'U')[0].toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.stone500))
                                : null,
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['name'] ?? 'Desconocido',
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textLight),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppColors.accentGreenLight
                                        : AppColors.stone200,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    isActive ? 'ACTIVO' : 'INACTIVO',
                                    style: TextStyle(
                                      color: isActive
                                          ? AppColors.accentGreenDark
                                          : AppColors.stone600,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Details Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.stone200),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Correo Electrónico',
                              user['email'] ?? 'No disponible'),
                          const Divider(height: 32),
                          _buildDetailRow('Rol del Sistema', role),
                          const Divider(height: 32),
                          _buildDetailRow('Puesto de Trabajo', jobPositionName),
                          const Divider(height: 32),
                          _buildDetailRow('Fecha de Registro',
                              _formatDate(user['created_at'])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(
                color: AppColors.stone500, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                color: AppColors.textLight,
                fontWeight: FontWeight.w600,
                fontSize: 16),
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr.toString();
    }
  }
}
