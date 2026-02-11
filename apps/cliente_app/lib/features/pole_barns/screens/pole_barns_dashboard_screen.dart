import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pole_barns_list_screen.dart';

class PoleBarnsDashboardScreen extends ConsumerWidget {
  const PoleBarnsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const PoleBarnsListScreen();
  }
}
