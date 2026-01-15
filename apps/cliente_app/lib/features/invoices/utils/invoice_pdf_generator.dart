import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/invoice_models.dart';
import 'package:intl/intl.dart';

class InvoicePdfGenerator {
  static Future<void> generate({
    required InvoiceModel invoice,
    required List<RelatedProductModel> products,
    required List<InvoicePaymentModel> payments,
  }) async {
    final pdf = pw.Document();
    final currency = NumberFormat.simpleCurrency();
    final dateFmt = DateFormat('MM/dd/yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
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
                      pw.Text('ID: ${invoice.id}'),
                      pw.Text('Fecha: ${dateFmt.format(invoice.date)}'),
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
                        pw.Text(invoice.clientName ?? 'N/A',
                            style: pw.TextStyle(
                                fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Dirección del Proyecto:',
                            style: pw.TextStyle(
                                fontSize: 10, color: PdfColors.grey600)),
                        pw.Text(invoice.address ?? 'N/A',
                            style: const pw.TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('NOTAS:',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(invoice.comentario ?? 'Ninguna',
                            textAlign: pw.TextAlign.right),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 32),

              // Items Table
              pw.Text('DETALLE DE ESTRUCTURAS',
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
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _cell('Descripción', true),
                      _cell('Cant', true),
                      _cell('Precio', true),
                      _cell('Total', true, pw.TextAlign.right),
                    ],
                  ),
                  ...products.map((p) => pw.TableRow(
                        children: [
                          _cell(p.poleBarnName ?? 'Pole Barn'),
                          _cell(p.cantidad.toString()),
                          _cell(currency.format(p.precioPorUnidad)),
                          _cell(currency.format(p.totalPrice), false,
                              pw.TextAlign.right),
                        ],
                      )),
                ],
              ),

              pw.SizedBox(height: 32),

              // Financial Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _summaryRow(
                          'Total Venta:', currency.format(invoice.totalVenta)),
                      _summaryRow('Total Pagado:',
                          currency.format(invoice.totalPagado)),
                      _summaryRow(
                          'Reembolsado:', currency.format(invoice.reembolsado)),
                      pw.Divider(color: PdfColors.grey400),
                      _summaryRow(
                          'SALDO PENDIENTE:', currency.format(invoice.saldo),
                          isBold: true, fontSize: 14),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),
              pw.Center(
                  child: pw.Text(
                      'Gracias por su confianza - Gilbert Construction')),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'invoice_${invoice.id}.pdf',
    );
  }

  static Future<List<int>> getBytes({
    required InvoiceModel invoice,
    required List<RelatedProductModel> products,
    required List<InvoicePaymentModel> payments,
  }) async {
    final pdf = pw.Document();
    final currency = NumberFormat.simpleCurrency();
    final dateFmt = DateFormat('MM/dd/yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
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
                      pw.Text('ID: ${invoice.id}'),
                      pw.Text('Fecha: ${dateFmt.format(invoice.date)}'),
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
                        pw.Text(invoice.clientName ?? 'N/A',
                            style: pw.TextStyle(
                                fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Dirección del Proyecto:',
                            style: pw.TextStyle(
                                fontSize: 10, color: PdfColors.grey600)),
                        pw.Text(invoice.address ?? 'N/A',
                            style: const pw.TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('NOTAS:',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(invoice.comentario ?? 'Ninguna',
                            textAlign: pw.TextAlign.right),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 32),

              // Items Table
              pw.Text('DETALLE DE ESTRUCTURAS',
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
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _cell('Descripción', true),
                      _cell('Cant', true),
                      _cell('Precio', true),
                      _cell('Total', true, pw.TextAlign.right),
                    ],
                  ),
                  ...products.map((p) => pw.TableRow(
                        children: [
                          _cell(p.poleBarnName ?? 'Pole Barn'),
                          _cell(p.cantidad.toString()),
                          _cell(currency.format(p.precioPorUnidad)),
                          _cell(currency.format(p.totalPrice), false,
                              pw.TextAlign.right),
                        ],
                      )),
                ],
              ),

              pw.SizedBox(height: 32),

              // Financial Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _summaryRow(
                          'Total Venta:', currency.format(invoice.totalVenta)),
                      _summaryRow('Total Pagado:',
                          currency.format(invoice.totalPagado)),
                      _summaryRow(
                          'Reembolsado:', currency.format(invoice.reembolsado)),
                      pw.Divider(color: PdfColors.grey400),
                      _summaryRow(
                          'SALDO PENDIENTE:', currency.format(invoice.saldo),
                          isBold: true, fontSize: 14),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),
              pw.Center(
                  child: pw.Text(
                      'Gracias por su confianza - Gilbert Construction')),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _cell(String text,
      [bool isBold = false, pw.TextAlign align = pw.TextAlign.left]) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text,
          textAlign: align,
          style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : null)),
    );
  }

  static pw.Widget _summaryRow(String label, String value,
      {bool isBold = false, double fontSize = 11}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: fontSize,
                  fontWeight: isBold ? pw.FontWeight.bold : null)),
          pw.SizedBox(width: 20),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: fontSize,
                  fontWeight: isBold ? pw.FontWeight.bold : null)),
        ],
      ),
    );
  }
}
