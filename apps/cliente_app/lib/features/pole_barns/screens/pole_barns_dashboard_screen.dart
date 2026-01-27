import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pole_barn_model.dart';
import '../providers/pole_barn_provider.dart';
import '../widgets/pole_barn_list_sidebar.dart';
import 'pole_barn_detail_screen.dart';

class PoleBarnsDashboardScreen extends ConsumerWidget {
  const PoleBarnsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const bgLight = Color(0xFFFDFBF7);

    return Scaffold(
      backgroundColor: bgLight,
      body: Row(
        children: [
          // Left Sidebar (Products List)
          const SizedBox(
            width: 320,
            child: PoleBarnListSidebar(),
          ),

          // Vertical Divider
          VerticalDivider(width: 1, thickness: 1, color: Colors.grey[300]),

          // Right Content (Product Details)
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final selectedId = ref.watch(selectedPoleBarnIdProvider);

                if (selectedId == null) {
                  return const Center(
                    child: Text(
                      'Selecciona un producto para ver los detalles',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                // If selectedId is -1, we pass null to initialPoleBarn for a new one
                // Otherwise, we'd ideally fetch it.
                // However, PoleBarnDetailScreen handles its own state via family provider.
                // We'll pass the ID to a future widget or refactor PoleBarnDetailScreen.

                // For now, let's use a simpler approach:
                // Use a FutureProvider to get the barn if id > 0.

                return PoleBarnDetailScreenWrapper(id: selectedId);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PoleBarnDetailScreenWrapper extends ConsumerWidget {
  final int id;
  const PoleBarnDetailScreenWrapper({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (id == -1) {
      return const PoleBarnDetailScreen(
          initialPoleBarn: null, key: ValueKey('new'));
    }

    // Usually we'd use a provider to get the barn by ID
    // Since we are using StreamBuilder in sidebar, we can use a temporary FutureProvider or just fetch once.

    return FutureBuilder(
      future: Supabase.instance.client
          .from('PoleBarns')
          .select()
          .eq('id', id)
          .single(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final barn =
            PoleBarn.fromJson(Map<String, dynamic>.from(snapshot.data as Map));
        return PoleBarnDetailScreen(
          initialPoleBarn: barn,
          key: ValueKey(id),
        );
      },
    );
  }
}
