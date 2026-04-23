import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/pole_barn_model.dart';
import '../models/related_material_model.dart';

class PoleBarnPdfGenerator {
  static const String companyName = 'J&P Pole barns LLC';
  static const String companyAddress = '331 kudzu rd\ncomer, GA 30629';
  static const String companyPhone = '(678) 549-0269';

  static Future<void> generate({
    required PoleBarn poleBarn,
    required List<RelatedMaterial> materials,
    required double totalCost,
    required double totalPrice,
    required double suggestedPrice,
  }) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
        italic: pw.Font.helveticaOblique(),
        boldItalic: pw.Font.helveticaBoldOblique(),
      ),
    );

    // Load logo
    pw.ImageProvider? logoImage;
    try {
      final logoData = await rootBundle.load('assets/branding/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      // Fallback
    }

    final currencyFormat = NumberFormat.currency(symbol: '\$');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(50),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(companyName,
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
                    pw.SizedBox(height: 4),
                    pw.Text(companyAddress, style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(companyPhone, style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                if (logoImage != null)
                  pw.Container(
                    height: 60,
                    width: 60,
                    child: pw.Image(logoImage),
                  ),
              ],
            ),
            pw.SizedBox(height: 30),

            pw.Center(
                child: pw.Text("Detalle de Producto",
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold))),

            pw.SizedBox(height: 20),

            // Product General Info
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Column(
                     crossAxisAlignment: pw.CrossAxisAlignment.start,
                     children: [
                       pw.Text('PRODUCTO', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
                       pw.SizedBox(height: 4),
                       pw.Text(poleBarn.name ?? 'Sin nombre', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                       pw.SizedBox(height: 10),
                       pw.Text('DIMENSIONES: ${poleBarn.ancho}x${poleBarn.largo}x${poleBarn.alto}', style: pw.TextStyle(fontSize: 12)),
                     ]
                   ),
                   pw.Column(
                     crossAxisAlignment: pw.CrossAxisAlignment.start,
                     children: [
                       pw.Text('ID: #${poleBarn.id ?? "NUEVO"}', style: pw.TextStyle(fontSize: 12)),
                       pw.SizedBox(height: 8),
                       pw.Text('PRECIO DE VENTA: ${currencyFormat.format(poleBarn.precioVenta)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
                     ]
                   ),
                ]
              )
            ),

            pw.SizedBox(height: 20),

            // Specifications & Costs Summary
            pw.Text('Especificaciones', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Wrap(
              spacing: 20,
              runSpacing: 10,
              children: [
                _buildInfoItem('Ancho', poleBarn.ancho.toString()),
                _buildInfoItem('Largo', poleBarn.largo.toString()),
                _buildInfoItem('Alto', poleBarn.alto.toString()),
                _buildInfoItem('Spacing', poleBarn.spacing.toString()),
                _buildInfoItem('Sheet', poleBarn.sheet.toString()),
                _buildInfoItem('Tamaño', poleBarn.tamano ?? '-'),
              ]
            ),
            
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 15),

            pw.Text('Resumen Financiero', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildFinancialItem('Costo Materiales', currencyFormat.format(totalCost)),
                _buildFinancialItem('Total Venta Materiales', currencyFormat.format(totalPrice)),
                _buildFinancialItem('Mano de Obra', currencyFormat.format(poleBarn.labour)),
                _buildFinancialItem('Precio Sugerido', currencyFormat.format(suggestedPrice), isHighlight: true),
              ]
            ),

            pw.SizedBox(height: 30),

            // Materials Table
            pw.Text('Lista de Materiales', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),

            if (materials.isEmpty)
              pw.Text('No hay materiales detallados.', style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, color: PdfColors.grey500))
            else
              pw.Table(
                border: const pw.TableBorder(
                  bottom: pw.BorderSide(color: PdfColors.grey300),
                  horizontalInside: pw.BorderSide(color: PdfColors.grey200),
                ),
                columnWidths: {
                  0: const pw.FixedColumnWidth(20),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(1.5),
                  5: const pw.FlexColumnWidth(1.2),
                  6: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _tableHeader('#'),
                      _tableHeader('Material'),
                      _tableHeader('Cant.'),
                      _tableHeader('Medida'),
                      _tableHeader('Precio U.'),
                      _tableHeader('Desp. (%)'),
                      _tableHeader('Total', alignRight: true),
                    ]
                  ),
                  ...materials.asMap().entries.map((entry) {
                    final index = entry.key;
                    final m = entry.value;
                    return pw.TableRow(children: [
                      _tableCell('${index + 1}'),
                      _tableCell(m.materialName ?? 'N/A'),
                      _tableCell(m.qty.toString()),
                      _tableCell(m.medida ?? '-'),
                      _tableCell(currencyFormat.format(m.pricePorUnidad)),
                      _tableCell('${m.wastePercent}%'),
                      _tableCell(currencyFormat.format(m.calculatedTotal), alignRight: true, bold: true),
                    ]);
                  }),
                ],
              ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'detalle_producto_${poleBarn.name?.replaceAll(' ', '_') ?? 'nuevo'}.pdf',
    );
  }

  static pw.Widget _buildInfoItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ]
    );
  }

  static pw.Widget _buildFinancialItem(String label, String value, {bool isHighlight = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, color: isHighlight ? PdfColors.orange900 : PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: isHighlight ? PdfColors.orange900 : PdfColors.black)),
      ]
    );
  }

  static pw.Widget _tableHeader(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: pw.Text(text,
          textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _tableCell(String text, {bool alignRight = false, bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(text, 
          textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
          style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }
}
