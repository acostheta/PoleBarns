import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_styles.dart';
import '../models/payroll_models.dart';
import 'pagos_soldadores_form.dart';

class PagosSoldadoresFormDialog extends ConsumerWidget {
  final NominaSoldador? item;
  const PagosSoldadoresFormDialog({super.key, this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 750),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                      item == null
                          ? 'Nuevo Pago a Soldador'
                          : 'Editar Pago a Soldador',
                      style: AppStyles.dialogTitleStyle),
                ),
                IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PagosSoldadoresForm(item: item),
            ),
          ],
        ),
      ),
    );
  }
}
