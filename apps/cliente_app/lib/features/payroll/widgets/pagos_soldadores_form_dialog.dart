import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payroll_models.dart';
import 'pagos_soldadores_form.dart';

class PagosSoldadoresFormDialog extends ConsumerWidget {
  final NominaSoldador? item;
  const PagosSoldadoresFormDialog({super.key, this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item == null ? 'Nuevo Pago a Soldador' : 'Editar Pago a Soldador',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF173124))),
          const SizedBox(height: 32),
          Expanded(
            child: PagosSoldadoresForm(item: item),
          ),
        ],
      ),
    );
  }
}
