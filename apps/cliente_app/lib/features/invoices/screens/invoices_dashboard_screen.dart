import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'invoices_list_screen.dart';

class InvoicesDashboardScreen extends ConsumerWidget {
  const InvoicesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const InvoicesListScreen();
  }
}
