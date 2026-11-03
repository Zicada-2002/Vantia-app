import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:vantia/core/money/money.dart';
import 'package:vantia/core/time/lima_time.dart';
import 'package:vantia/features/payments/domain/payment.dart';

enum ExportFormat { xlsx, pdf }

/// Genera los archivos de exportación de pagos (F-54). Puro: recibe los
/// pagos y devuelve bytes, para poder testearlo sin plataforma.
abstract final class PaymentExport {
  static const headers = [
    'Fecha',
    'Hora',
    'Medio',
    'Monto (S/)',
    'Recibido (S/)',
    'Cambio (S/)',
    'Nº operación',
    'Cliente',
    'Descripción',
    'Registrado por',
    'Estado',
  ];

  static List<String> row(Payment p) => [
    LimaTime.dayKey(p.occurredAt),
    LimaTime.formatTime(p.occurredAt),
    p.method.label,
    p.amount.format(withSymbol: false),
    p.received?.format(withSymbol: false) ?? '',
    p.change?.format(withSymbol: false) ?? '',
    p.operationNumber ?? '',
    p.payerName ?? '',
    p.description ?? '',
    p.createdByName,
    statusLabel(p),
  ];

  static String statusLabel(Payment p) => p.isActive ? 'Activo' : 'Anulado';

  static Uint8List xlsx(List<Payment> payments, {required String title}) {
    final book = Excel.createExcel();
    final defaultSheet = book.getDefaultSheet()!;
    book.rename(defaultSheet, 'Pagos');
    final sheet = book['Pagos']
      ..appendRow([TextCellValue(title)])
      ..appendRow([for (final h in headers) TextCellValue(h)]);
    for (final p in payments) {
      sheet.appendRow([
        TextCellValue(LimaTime.dayKey(p.occurredAt)),
        TextCellValue(LimaTime.formatTime(p.occurredAt)),
        TextCellValue(p.method.label),
        DoubleCellValue(p.amount.cents / 100),
        if (p.received != null)
          DoubleCellValue(p.received!.cents / 100)
        else
          TextCellValue(''),
        if (p.change != null)
          DoubleCellValue(p.change!.cents / 100)
        else
          TextCellValue(''),
        TextCellValue(p.operationNumber ?? ''),
        TextCellValue(p.payerName ?? ''),
        TextCellValue(p.description ?? ''),
        TextCellValue(p.createdByName),
        TextCellValue(statusLabel(p)),
      ]);
    }
    final summary = PaymentSummary.of(payments);
    sheet
      ..appendRow([])
      ..appendRow([
        TextCellValue('Total (activos)'),
        TextCellValue(''),
        TextCellValue(''),
        DoubleCellValue(summary.total.cents / 100),
      ]);
    return Uint8List.fromList(book.encode()!);
  }

  static Future<Uint8List> pdf(
    List<Payment> payments, {
    required String title,
    required String businessName,
    pw.Font? font,
    pw.Font? boldFont,
  }) async {
    final summary = PaymentSummary.of(payments);
    final theme = font == null
        ? null
        : pw.ThemeData.withFont(base: font, bold: boldFont ?? font);
    final doc = pw.Document(theme: theme)
      ..addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (_) => [
            pw.Text(
              businessName,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(title),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: [for (final p in payments) row(p)],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignments: {3: pw.Alignment.centerRight},
            ),
            pw.SizedBox(height: 12),
            pw.Text('Pagos activos: ${summary.count}'),
            pw.Text('Efectivo: ${summary.cash.format()}'),
            pw.Text('Digital: ${summary.digital.format()}'),
            pw.Text(
              'Total: ${summary.total.format()}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      );
    return await doc.save();
  }

  /// Total en céntimos de los pagos activos (útil para verificar archivos).
  static Money total(List<Payment> payments) =>
      PaymentSummary.of(payments).total;
}
