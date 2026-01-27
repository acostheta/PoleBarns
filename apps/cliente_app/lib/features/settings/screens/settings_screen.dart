import 'package:flutter/material.dart';
import 'package:raw_materials/raw_materials.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers_tab.dart';
import 'payment_methods_tab.dart';
import 'package:users/users.dart';
import 'package:measures/measures.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).cardColor,
            child: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Materia Prima'),
                Tab(text: 'Proveedores'),
                Tab(text: 'Métodos de Pago'),
                Tab(text: 'Puestos de Trabajo'),
                Tab(text: 'Medidas'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                RawMaterialsScreen(),
                ProvidersTab(),
                PaymentMethodsTab(),
                JobPositionsScreen(),
                MeasuresScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
