import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/project_models.dart';
import 'package:intl/intl.dart';

class PdfGenerator {
  static Future<void> generateInvoice({
    required ProjectModel project,
    required List<ProjectPoleBarnModel> poleBarns,
    ClientSimpleModel? client,
  }) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
        italic: pw.Font.helveticaOblique(),
        boldItalic: pw.Font.helveticaBoldOblique(),
      ),
    );
    final currency = NumberFormat.simpleCurrency();
    final dateFmt = DateFormat('MM/dd/yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(70.87), // 2.5cm
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('GILBERT CONSTRUCTION',
                          style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.amber800)),
                      pw.Text('Specializing in Pole Barns'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('FACTURA / INVOICE',
                          style: pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                          'ID: ${project.id.substring(0, 8).toUpperCase()}'),
                      pw.Text('Fecha: ${dateFmt.format(DateTime.now())}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 32),
              pw.Divider(thickness: 2, color: PdfColors.grey300),
              pw.SizedBox(height: 16),

              // Info Row
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('FACTURAR A:',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(client?.fullName ?? project.refCliente,
                            style: pw.TextStyle(
                                fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Dirección del Proyecto:',
                            style: pw.TextStyle(
                                fontSize: 10, color: PdfColors.grey600)),
                        pw.Text(project.address ?? 'N/A',
                            style: const pw.TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('DETALLES DEL PROYECTO:',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text('Estado: ${project.estatus ?? "Iniciado"}'),
                        pw.Text('Líder: ${project.responsable ?? "N/A"}'),
                        if (project.fechaInicio != null)
                          pw.Text(
                              'Inicio: ${dateFmt.format(project.fechaInicio!)}'),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 32),

              // Items Table
              pw.Text('RESUMEN DE ESTRUCTURAS',
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.amber800)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: PdfColors.grey200),
                  bottom: pw.BorderSide(color: PdfColors.grey300),
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Descripción',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Precio',
                            textAlign: pw.TextAlign.right,
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  // Table Rows
                  ...poleBarns.map((pb) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                                pb.poleBarnName ?? 'Pole Barn Structure'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(currency.format(pb.salePrice),
                                textAlign: pw.TextAlign.right),
                          ),
                        ],
                      )),
                ],
              ),

              pw.SizedBox(height: 32),

              if (project.comments != null && project.comments!.isNotEmpty) ...[
                pw.Text('COMENTARIOS / NOTAS:',
                    style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700)),
                pw.SizedBox(height: 4),
                pw.Text(project.comments!,
                    style: const pw.TextStyle(fontSize: 11)),
                pw.SizedBox(height: 32),
              ],

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text('SUBTOTAL: ',
                              style: const pw.TextStyle(fontSize: 12)),
                          pw.SizedBox(width: 20),
                          pw.Text(currency.format(project.ventaTotal),
                              style: const pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text('TAX (0%): ',
                              style: const pw.TextStyle(fontSize: 12)),
                          pw.SizedBox(width: 20),
                          pw.Text(currency.format(0),
                              style: const pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                      pw.Divider(color: PdfColors.grey400),
                      pw.Row(
                        children: [
                          pw.Text('TOTAL A PAGAR: ',
                              style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(width: 20),
                          pw.Text(currency.format(project.ventaTotal),
                              style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.amber800)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                    'Gracias por su confianza - J&P Pole Barns LLC',
                    style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey500,
                        fontStyle: pw.FontStyle.italic)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'factura_${project.id.substring(0, 8)}.pdf',
    );
  }
}
