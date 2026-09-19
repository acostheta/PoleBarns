import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/project_models.dart';
import '../../clients/models/client_model.dart';

class ProjectMaterialsPdfGenerator {
  static const String companyName = 'PoleBarns';
  static const String companyAddress = 'Tu dirección aquí';
  static const String companyPhone = 'Tu teléfono aquí';

  static Future<void> generate({
    required ProjectModel project,
    required ClientModel? client,
    required List<Map<String, dynamic>> items,
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

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(70.87), // 2.5cm
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
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(companyAddress,
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(companyPhone,
                        style: const pw.TextStyle(fontSize: 10)),
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
                child: pw.Text("Lista de Materiales y Estructuras",
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold))),

            pw.SizedBox(height: 20),

            // Project & Client Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Información del Cliente:',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.SizedBox(height: 4),
                    pw.Text('Nombre: ${client?.nombre ?? "No Disponible"}',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Teléfono: ${client?.telefono ?? "No Disponible"}',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Email: ${client?.email ?? "No Disponible"}',
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Ubicación del Proyecto:',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.SizedBox(height: 4),
                    pw.Text(project.address ?? 'Sin dirección',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                        'Fecha: ${DateFormat('MM/dd/yyyy').format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Products Loop
            ...items.map((item) {
              final ProjectPoleBarnModel poleBarn = item['project_pole_barn'];
              final List<dynamic> materials = item['materials'];

              // Use Wrap or Column inside MultiPage?
              // MultiPage children are laid out vertically.
              // To ensure the header stays with the table if possible, usually we just return widgets.
              // But 'map' returns an Iterable.
              // We return a Column here to wrap unit of work (Header + Table).
              // Column inside MultiPage is fine, it just won't split *inside* the column if 'wrap: false' (default is true?).
              // Actually pw.Column defaults to mainAxisSize: max.
              // Better to return a Column to keep title + table together, BUT
              // if table is huge, Column might cause issues splitting across pages.
              // Ideally we would return [Title, Table, Spacer] flattened.
              // But for simplicity of logic let's keep the Column structure unless it breaks.
              // pw.Column inside MultiPage CAN split if it's not nested too deep or strictly constrained.
              // However, safe bet is to return a Column.
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 6, horizontal: 8),
                    color: PdfColors.grey200,
                    width: double.infinity,
                    child: pw.Text(poleBarn.poleBarnName ?? 'Estructura',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  ),
                  pw.SizedBox(height: 8),
                  if (materials.isEmpty)
                    pw.Text('No hay materiales detallados.',
                        style: pw.TextStyle(
                            fontSize: 10, fontStyle: pw.FontStyle.italic))
                  else
                    pw.Table(
                      border: const pw.TableBorder(
                        bottom: pw.BorderSide(color: PdfColors.grey300),
                        horizontalInside:
                            pw.BorderSide(color: PdfColors.grey100),
                      ),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(3),
                        1: const pw.FlexColumnWidth(1),
                        2: const pw.FlexColumnWidth(1),
                      },
                      children: [
                        pw.TableRow(children: [
                          _tableHeader('Material'),
                          _tableHeader('Cantidad'),
                          _tableHeader('Medida'),
                        ]),
                        ...materials.map((m) {
                          final name = m['raw_materials']?['name'] ??
                              m['RawMaterials']?['name'] ??
                              'Desconocido';
                          final qty = m['Qty'] ?? m['qty'] ?? 0;
                          final unit = m['Medida'] ?? m['medida'] ?? '-';
                          return pw.TableRow(children: [
                            _tableCell(name),
                            _tableCell(qty.toString()),
                            _tableCell(unit.toString()),
                          ]);
                        }),
                      ],
                    ),
                  pw.SizedBox(height: 20),
                ],
              );
            }),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'materiales_${project.id}.pdf',
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }
}
