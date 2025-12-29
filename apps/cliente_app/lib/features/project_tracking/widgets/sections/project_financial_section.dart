import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/project_models.dart';

class ProjectFinancialSection extends StatelessWidget {
  final ProjectModel project;

  const ProjectFinancialSection({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    // const primaryColor = Color(0xFFD97706); // Unused
    final currency = NumberFormat.simpleCurrency();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Costos del Proyecto',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              _FinancialCard(
                label: 'Venta Total',
                amount: currency.format(project.ventaTotal),
                bg: const Color(0xFFFAFAF9), // Stone-50
                borderColor: const Color(0xFFD6D3D1),
                textColor: const Color(0xFF1F2937),
              ),
              _FinancialCard(
                label: 'Costo Total',
                amount: currency.format(project.costosTotales),
                bg: const Color(0xFFFAFAF9), // Stone-50
                borderColor: const Color(0xFFD6D3D1),
                textColor: const Color(0xFF1F2937),
              ),
              _FinancialCard(
                label: 'Balance',
                amount: currency.format(project.profit),
                bg: const Color(0xFFF0FDF4), // Green-50
                borderColor: const Color(0xFF86EFAC), // Green-300
                textColor: const Color(0xFF15803D), // Green-700
                isBold: true,
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _FinancialCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color bg;
  final Color borderColor;
  final Color textColor;
  final bool isBold;

  const _FinancialCard({
    required this.label,
    required this.amount,
    required this.bg,
    required this.borderColor,
    required this.textColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700])),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 24,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
