import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import '../infrastructure/users_repository.dart';
import 'user_form_screen.dart';

class UserDetailScreen extends ConsumerWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  // Branded Colors
  static const Color primaryForest = Color(0xFF173124);
  static const Color secondaryEarth = Color(0xFF7C580F);
  static const Color backgroundLight = Color(0xFFFDFBF7);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    final jobPositionsAsync = ref.watch(jobPositionsProvider);

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text('Detalles del Trabajador', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: primaryForest,
        elevation: 0,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.edit_outlined, color: secondaryEarth),
              onPressed: () {
                final user = usersAsync.value?.firstWhere((u) => u['id'] == userId, orElse: () => {});
                if (user != null && user.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserFormScreen(userId: userId, userMetadata: user)),
                  );
                }
              },
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.black.withValues(alpha: 0.05), height: 1),
        ),
      ),
      body: usersAsync.when(
        data: (users) {
          final user = users.firstWhere((u) => u['id'] == userId, orElse: () => {});
          if (user.isEmpty) return const Center(child: Text('Usuario no encontrado'));

          final isActive = user['is_active'] as bool? ?? false;
          final role = user['role'] as String? ?? 'Sin asignar';
          final jobPositionId = user['job_position_id'] as String?;

          String jobPositionName = 'Sin puesto';
          if (jobPositionsAsync.value != null) {
            final pos = jobPositionsAsync.value!.firstWhere((p) => p['id'] == jobPositionId, orElse: () => {});
            if (pos.isNotEmpty) jobPositionName = pos['name'];
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header Card
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Hero(
                            tag: 'user_avatar_$userId',
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: secondaryEarth.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: secondaryEarth.withValues(alpha: 0.2), width: 2),
                                image: user['picture'] != null ? DecorationImage(image: NetworkImage(user['picture']), fit: BoxFit.cover) : null,
                              ),
                              alignment: Alignment.center,
                              child: user['picture'] == null
                                  ? Text(
                                      (user['name'] ?? 'U')[0].toUpperCase(),
                                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: secondaryEarth),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['name'] ?? 'Desconocido',
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryForest, letterSpacing: -0.5),
                                ),
                                const SizedBox(height: 12),
                                _buildStatusBadge(isActive),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Information Card
                    _buildSectionHeader('Información General'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildDetailItem(Icons.email_outlined, 'Correo Electrónico', user['email'] ?? 'No disponible'),
                          const Divider(height: 48),
                          _buildDetailItem(Icons.admin_panel_settings_outlined, 'Rol del Sistema', role),
                          const Divider(height: 48),
                          _buildDetailItem(Icons.work_outline, 'Puesto de Trabajo', jobPositionName),
                          const Divider(height: 48),
                          _buildDetailItem(Icons.calendar_today_outlined, 'Fecha de Registro', _formatDate(user['created_at'])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: primaryForest)),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: secondaryEarth, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: primaryForest.withValues(alpha: 0.6), letterSpacing: 1),
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: primaryForest.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: primaryForest),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.4), fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primaryForest)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    final color = isActive ? Colors.green : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(
            isActive ? 'ACTIVO' : 'INACTIVO',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
          ),
        ],
      ),
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
