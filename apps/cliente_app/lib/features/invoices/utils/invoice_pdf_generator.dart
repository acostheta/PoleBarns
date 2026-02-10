import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/invoice_models.dart';
import 'package:intl/intl.dart';

class InvoicePdfGenerator {
  static const String companyName = 'J&P Pole barns LLC';
  static const String companyAddress = '331 kudzu rd\ncomer, GA 30629';
  static const String companyPhone = '(678) 549-0269';

  static Future<void> generate({
    required InvoiceModel invoice,
    required List<RelatedProductModel> products,
    required List<InvoicePaymentModel> payments,
  }) async {
    final byteData = await getBytes(
      invoice: invoice,
      products: products,
      payments: payments,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => byteData,
      name: 'invoice_${invoice.id}.pdf',
    );
  }

  static Future<Uint8List> getBytes({
    required InvoiceModel invoice,
    required List<RelatedProductModel> products,
    required List<InvoicePaymentModel> payments,
  }) async {
    final pdf = pw.Document();
    final currency = NumberFormat.simpleCurrency();
    final dateFmt = DateFormat('MM/dd/yyyy');

    // Load fonts for Unicode support
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    // Load logo
    pw.ImageProvider? logoImage;
    try {
      final logoData = await rootBundle.load('assets/branding/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      // Fallback if logo is missing
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER SECTION
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
                      height: 80,
                      width: 80,
                      child: pw.Image(logoImage),
                    ),
                ],
              ),
              pw.SizedBox(height: 40),

              // TO AND INVOICE DETAILS SECTION
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Client info
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('To:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(invoice.clientName ?? 'N/A'),
                      pw.Text(invoice.address ?? 'N/A',
                          style: const pw.TextStyle(fontSize: 10)),
                      // Phone placeholder if available
                    ],
                  ),
                  // Invoice details
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _detailRow('Invoice #', invoice.id.toString()),
                      _detailRow('Invoice Date', dateFmt.format(invoice.date)),
                      _detailRow('Payment Term', 'Net 30'),
                      pw.SizedBox(height: 10),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        color: PdfColors.grey200,
                        child: _detailRow(
                            'Amount Due', currency.format(invoice.saldo),
                            isBold: true),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // ITEMS TABLE
              pw.Table(
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: PdfColors.grey300),
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(1),
                  5: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _tableHeader('Item'),
                      _tableHeader('Quantity'),
                      _tableHeader('Price'),
                      _tableHeader('Tax1'),
                      _tableHeader('Tax2'),
                      _tableHeader('Line Total', pw.TextAlign.right),
                    ],
                  ),
                  // Table Rows
                  ...products.map((p) => pw.TableRow(
                        children: [
                          _tableCell(p.poleBarnName ?? 'Item'),
                          _tableCell(p.cantidad.toString()),
                          _tableCell(currency.format(p.precioPorUnidad)),
                          _tableCell(''),
                          _tableCell(''),
                          _tableCell(currency.format(p.totalPrice),
                              pw.TextAlign.right),
                        ],
                      )),
                ],
              ),
              pw.SizedBox(height: 20),

              // SUMMARY SECTION
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _summaryLine(
                          'Subtotal:', currency.format(invoice.totalVenta)),
                      _summaryLine('Tax:', currency.format(0)),
                      _summaryLine('Past Due Amount:', currency.format(0)),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        color: PdfColors.grey200,
                        child: _summaryLine(
                            'Amount Due:', currency.format(invoice.saldo),
                            isBold: true),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // NOTES SECTION
              pw.Text('J&P Pole Barn Notes for Invoice',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _numberedNote(1,
                  'Prices are based on the approximate square footage detailed above. Any variations will be adjusted accordingly during the project\'s development or upon completion.'),
              _numberedNote(2,
                  '50% of the invoice total is due upon delivery of the materials.'),
              _numberedNote(3,
                  'All materials used for this project are the property of J&P Pole Barns LLC. Any remaining or unused materials will remain with the company.'),
              _numberedNote(4,
                  'Any additional work requested by the client during the project will be documented, and corresponding budget adjustments will be provided.'),
              pw.SizedBox(height: 20),
              pw.Text('Notes',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Thank You For Your Business!'),

              pw.Spacer(),

              // FOOTER
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                    'View Online: https://gilbert-crm-app-8392.web.app/invoices/${invoice.id}',
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey600)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Helper methods for styling
  static pw.Widget _detailRow(String label, String value,
      {bool isBold = false}) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text('$label: ', style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(width: 5),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : null)),
      ],
    );
  }

  static pw.Widget _tableHeader(String text,
      [pw.TextAlign align = pw.TextAlign.left]) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text,
          textAlign: align,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _tableCell(String text,
      [pw.TextAlign align = pw.TextAlign.left]) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text,
          textAlign: align, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  static pw.Widget _summaryLine(String label, String value,
      {bool isBold = false}) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : null)),
        pw.SizedBox(width: 40),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : null)),
      ],
    );
  }

  static pw.Widget _numberedNote(int number, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('$number. ', style: const pw.TextStyle(fontSize: 9)),
          pw.Expanded(
              child: pw.Text(text, style: const pw.TextStyle(fontSize: 9))),
        ],
      ),
    );
  }
}
