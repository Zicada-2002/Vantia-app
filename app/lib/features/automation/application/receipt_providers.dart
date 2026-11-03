import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vantia/features/automation/data/receipt_scanner.dart';

final receiptScannerProvider = Provider<ReceiptScanner>(
  (ref) => MlKitReceiptScanner(),
);

final receiptStorageProvider = Provider<ReceiptStorage>(
  (ref) => FirebaseReceiptStorage(FirebaseStorage.instance),
);
