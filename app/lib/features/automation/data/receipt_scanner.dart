import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vantia/core/time/lima_time.dart';
import 'package:vantia/features/automation/domain/parsers.dart'
    show ReceiptParser;
import 'package:vantia/features/payments/domain/payment.dart';
import 'package:vantia/features/payments/presentation/payment_form_screen.dart';
import 'package:vantia/l10n/l10n.dart';

/// F-70: cámara/galería → OCR en el dispositivo → datos para prellenar.
abstract interface class ReceiptScanner {
  Future<PaymentPrefill?> scan(BuildContext context);
}

class MlKitReceiptScanner implements ReceiptScanner {
  MlKitReceiptScanner({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PaymentPrefill?> scan(BuildContext context) async {
    final l10n = context.l10n;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.ocrCamera),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.ocrGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return null;
    final image = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (image == null) return null;

    final recognizer = TextRecognizer();
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(image.path),
      );
      final r = ReceiptParser.parse(
        result.text,
        limaYear: LimaTime.toLima(DateTime.now()).year,
      );
      return PaymentPrefill(
        amount: r.amount,
        occurredAt: r.limaDateTime == null
            ? null
            : LimaTime.fromLima(r.limaDateTime!),
        operationNumber: r.operationNumber,
        payerName: r.payerName,
        source: PaymentSource.ocr,
        receiptFilePath: image.path,
        detectedMethod: r.method,
      );
    } finally {
      await recognizer.close();
    }
  }
}

/// Sube la imagen del comprobante; devuelve la ruta o null si falla
/// (el pago se registra igual: la imagen es opcional).
abstract interface class ReceiptStorage {
  Future<String?> upload(String businessId, String localPath);
}

class FirebaseReceiptStorage implements ReceiptStorage {
  FirebaseReceiptStorage(this._storage);

  final FirebaseStorage _storage;

  @override
  Future<String?> upload(String businessId, String localPath) async {
    final name =
        '${DateTime.now().millisecondsSinceEpoch}_${localPath.hashCode.abs()}.jpg';
    final path = 'receipts/$businessId/$name';
    try {
      await _storage
          .ref(path)
          .putFile(File(localPath), SettableMetadata(contentType: 'image/jpeg'))
          .timeout(const Duration(seconds: 20));
      return path;
    } on Object catch (e) {
      debugPrint('No se pudo subir el comprobante: $e');
      return null;
    }
  }
}
