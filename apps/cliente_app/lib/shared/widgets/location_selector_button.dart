import 'package:flutter/material.dart';
import '../../config/app_styles.dart';
import './location_picker.dart';

class LocationSelectorButton extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const LocationSelectorButton({
    super.key,
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.labelStyle),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final result = await Navigator.push<String>(
              context,
              MaterialPageRoute(
                builder: (context) => LocationPicker(
                  initialAddress: controller.text,
                ),
              ),
            );
            if (result != null) {
              controller.text = result;
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.map_outlined, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, child) {
                      return Text(
                        value.text.isEmpty
                            ? 'Seleccionar ubicación en el mapa...'
                            : value.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: value.text.isEmpty
                              ? Colors.grey.shade500
                              : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
