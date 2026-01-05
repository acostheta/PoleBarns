import 'package:flutter/material.dart';
import 'pagos_diarios_screen.dart';
import 'destajo_soldadores_screen.dart';
import 'nomina_instalacion_screen.dart';
import 'nomina_chofer_screen.dart';

class PayrollDashboardScreen extends StatelessWidget {
  const PayrollDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Material(
        child: Column(
          children: [
            Container(
              color: Theme.of(context).cardColor,
              child: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Pagos Diarios', icon: Icon(Icons.calendar_today)),
                  Tab(text: 'Soldadores', icon: Icon(Icons.construction)),
                  Tab(text: 'Instalación', icon: Icon(Icons.home_work)),
                  Tab(text: 'Choferes', icon: Icon(Icons.directions_car)),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  PagosDiariosScreen(),
                  DestajoSoldadoresScreen(),
                  NominaInstalacionScreen(),
                  NominaChoferScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
