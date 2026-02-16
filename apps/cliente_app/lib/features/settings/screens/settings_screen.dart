import 'package:flutter/material.dart';
import 'package:raw_materials/raw_materials.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers_tab.dart';
import 'payment_methods_tab.dart';
import 'trusses_tab.dart';
import 'lean_to_tab.dart';
import 'package:users/users.dart';
import 'package:measures/measures.dart';
import 'rbac_tab.dart';
import 'help_tab.dart';

class SettingsScreen extends ConsumerWidget {
  final int initialIndex;
  const SettingsScreen({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 9,
      initialIndex: initialIndex,
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
                Tab(text: 'Trusses'),
                Tab(text: 'Lean Too'),
                Tab(text: 'Puestos de Trabajo'),
                Tab(text: 'Medidas'),
                Tab(text: 'Permisos'),
                Tab(text: 'Ayuda'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                RawMaterialsScreen(),
                ProvidersTab(),
                PaymentMethodsTab(),
                TrussesTab(),
                LeanToTab(),
                JobPositionsScreen(),
                MeasuresScreen(),
                RbacTab(),
                HelpTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
