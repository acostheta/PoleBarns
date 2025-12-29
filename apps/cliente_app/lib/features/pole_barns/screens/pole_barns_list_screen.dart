import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pole_barn_model.dart';
import 'pole_barn_detail_screen.dart';
import 'package:intl/intl.dart';

class PoleBarnsListScreen extends ConsumerWidget {
  const PoleBarnsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(symbol: r'$');

    return Scaffold(
      body: StreamBuilder(
        stream: Supabase.instance.client
            .from('PoleBarns')
            .stream(primaryKey: ['id']).order('created_at', ascending: false),
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
              .toList();

          if (barns.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.architecture, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No hay caballerizas registradas',
                      style: TextStyle(color: Colors.grey, fontSize: 18)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _openDetail(context, null),
                    child: const Text('Crear Primera Caballeriza'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: barns.length,
            itemBuilder: (context, index) {
              final barn = barns[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.architecture),
                  ),
                  title: Text(barn.name ?? 'Caballeriza #${barn.id}'),
                  subtitle: Text(
                      'Dimensiones: ${barn.largo}x${barn.ancho}x${barn.alto} | Spacing: ${barn.spacing}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(barn.precioVenta),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => _openDetail(context, barn),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openDetail(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openDetail(BuildContext context, PoleBarn? barn) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PoleBarnDetailScreen(initialPoleBarn: barn),
      ),
    );
  }
}
