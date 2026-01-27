import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pole_barn_model.dart';
import '../providers/pole_barn_provider.dart';
import 'package:intl/intl.dart';

class PoleBarnListSidebar extends ConsumerStatefulWidget {
  const PoleBarnListSidebar({super.key});

  @override
  ConsumerState<PoleBarnListSidebar> createState() =>
      _PoleBarnListSidebarState();
}

class _PoleBarnListSidebarState extends ConsumerState<PoleBarnListSidebar> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedPoleBarnIdProvider);
    final currencyFormat = NumberFormat.currency(symbol: r'$');

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catálogo de Productos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(selectedPoleBarnIdProvider.notifier).state =
                          -1; // -1 for new
                    },
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Nuevo Producto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                fillColor: const Color(0xFFF5F5F4),
                filled: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // List
          Expanded(
            child: StreamBuilder(
              stream: Supabase.instance.client.from('PoleBarns').stream(
                  primaryKey: ['id']).order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final rawData = snapshot.data as List?;
                final barns = (rawData ?? [])
                    .map((e) => PoleBarn.fromJson(Map<String, dynamic>.from(e)))
                    .where((p) {
                  final query = _searchQuery.toLowerCase();
                  return (p.name?.toLowerCase().contains(query) ?? false);
                }).toList();

                if (barns.isEmpty) {
                  return const Center(
                      child: Text('No se encontraron productos'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: barns.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final barn = barns[index];
                    final isSelected = barn.id == selectedId;

                    return _PoleBarnListItem(
                      barn: barn,
                      isSelected: isSelected,
                      currencyFormat: currencyFormat,
                      onTap: () {
                        ref.read(selectedPoleBarnIdProvider.notifier).state =
                            barn.id;
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PoleBarnListItem extends StatelessWidget {
  final PoleBarn barn;
  final bool isSelected;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;

  const _PoleBarnListItem({
    required this.barn,
    required this.isSelected,
    required this.currencyFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isSelected ? const Color(0xFFFFFBEB) : Colors.transparent;
    final borderColor =
        isSelected ? const Color(0xFFF59E0B) : Colors.transparent;
    final titleColor =
        isSelected ? const Color(0xFF92400E) : const Color(0xFF1F2937);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: const Color(0xFFF5F5F4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: borderColor,
              width: 4,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              barn.name ?? 'Caballeriza #${barn.id}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: titleColor,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${barn.largo}x${barn.ancho}x${barn.alto}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Text(
                  currencyFormat.format(barn.precioVenta),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
