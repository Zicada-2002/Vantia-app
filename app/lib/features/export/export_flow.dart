import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/core/observability/analytics.dart';
import 'package:vantia/core/time/clock.dart';
import 'package:vantia/core/time/lima_time.dart';
import 'package:vantia/core/widgets/error_messages.dart';
import 'package:vantia/features/export/payment_export.dart';
import 'package:vantia/features/payments/application/payment_providers.dart';
import 'package:vantia/l10n/l10n.dart';

/// Comparte un archivo generado. Inyectable para tests.
typedef FileSharer =
    Future<void> Function(
      Uint8List bytes,
      String fileName,
      String mime,
      String subject,
    );

final fileSharerProvider = Provider<FileSharer>(
  (ref) => (bytes, name, mime, subject) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mime)],
        subject: subject,
      ),
    );
  },
);

/// Selector de rango (inyectable para tests).
typedef RangePicker =
    Future<DateTimeRange?> Function(BuildContext context, DateTime limaToday);

final rangePickerProvider = Provider<RangePicker>(
  (ref) =>
      (context, today) => showDateRangePicker(
        context: context,
        firstDate: DateTime(today.year - 2),
        lastDate: DateTime(today.year, today.month, today.day),
        helpText: context.l10n.exportTitle,
        saveText: context.l10n.exportButton,
      ),
);

/// F-54: rango de fechas → formato → archivo → compartir.
Future<void> runExportFlow(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final today = LimaTime.toLima(ref.read(clockProvider)());
  final range = await ref.read(rangePickerProvider)(context, today);
  if (range == null || !context.mounted) return;
  if (range.duration.inDays > 366) {
    showSnack(context, l10n.exportTooLong);
    return;
  }
  final format = await showModalBottomSheet<ExportFormat>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: Text(l10n.exportFormat)),
          ListTile(
            leading: const Icon(Icons.table_view_rounded),
            title: Text(l10n.exportExcel),
            onTap: () => Navigator.pop(ctx, ExportFormat.xlsx),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_rounded),
            title: Text(l10n.exportPdf),
            onTap: () => Navigator.pop(ctx, ExportFormat.pdf),
          ),
        ],
      ),
    ),
  );
  if (format == null || !context.mounted) return;

  final scope = ref.read(paymentScopeProvider);
  if (scope == null) return;
  final from = LimaTime.fromLima(
    DateTime.utc(range.start.year, range.start.month, range.start.day),
  );
  final to = LimaTime.fromLima(
    DateTime.utc(range.end.year, range.end.month, range.end.day + 1),
  );
  final payments =
      (await ref
              .read(paymentRepositoryProvider)
              .watchRange(scope, from: from, to: to)
              .first)
          .reversed
          .toList();
  if (!context.mounted) return;
  if (payments.isEmpty) {
    showSnack(context, l10n.exportEmpty);
    return;
  }

  final label =
      '${LimaTime.dayKey(from)}_a_${LimaTime.dayKey(to.subtract(const Duration(days: 1)))}';
  final title = l10n.exportSubject(label.replaceAll('_', ' '));
  final business = ref.read(currentBusinessProvider).value?.name ?? 'Vantia';
  final sharer = ref.read(fileSharerProvider);
  switch (format) {
    case ExportFormat.xlsx:
      await sharer(
        PaymentExport.xlsx(payments, title: title),
        'vantia_pagos_$label.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        title,
      );
    case ExportFormat.pdf:
      pw.Font? font;
      pw.Font? bold;
      try {
        font = pw.Font.ttf(
          await rootBundle.load('assets/fonts/Poppins-Regular.ttf'),
        );
        bold = pw.Font.ttf(
          await rootBundle.load('assets/fonts/Poppins-Bold.ttf'),
        );
      } on Object {
        // Sin fuente embebida se usa Helvetica.
      }
      await sharer(
        await PaymentExport.pdf(
          payments,
          title: title,
          businessName: business,
          font: font,
          boldFont: bold,
        ),
        'vantia_pagos_$label.pdf',
        'application/pdf',
        title,
      );
  }
  ref.read(analyticsProvider).log(AnalyticsEvent.exportGenerated, {
    'format': format.name,
  }).ignore();
}
