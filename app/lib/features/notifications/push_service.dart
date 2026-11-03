import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/session.dart';

/// Registra el token FCM del dispositivo en `users/{uid}/devices` (F-33).
abstract interface class PushService {
  Future<void> register(String uid);
  Future<void> unregister(String uid);
}

class FirebasePushService implements PushService {
  FirebasePushService(this._messaging, this._db);

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _db;
  StreamSubscription<String>? _refresh;
  String? _token;

  static String _docId(String token) =>
      sha1.convert(utf8.encode(token)).toString();

  Future<void> _save(String uid, String token) async {
    _token = token;
    await _db.doc('users/$uid/devices/${_docId(token)}').set({
      'token': token,
      'platform': defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> register(String uid) async {
    try {
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      // API clásica de tokens: es la que acepta sendEachForMulticast del
      // Admin SDK. Migrar a register()/onRegistered (FID) cuando el backend
      // soporte envío directo por FID.
      // ignore: deprecated_member_use
      final token = await _messaging.getToken();
      if (token != null) await _save(uid, token);
      await _refresh?.cancel();
      // Mismo motivo que getToken().
      // ignore: deprecated_member_use
      _refresh = _messaging.onTokenRefresh.listen((t) => _save(uid, t));
    } on Object catch (e) {
      // Sin Play Services, emulador sin FCM, etc.: no es crítico.
      debugPrint('Push no disponible: $e');
    }
  }

  @override
  Future<void> unregister(String uid) async {
    await _refresh?.cancel();
    final token = _token;
    if (token == null) return;
    try {
      await _db.doc('users/$uid/devices/${_docId(token)}').delete();
      // Mismo motivo que getToken().
      // ignore: deprecated_member_use
      await _messaging.deleteToken();
    } on Object catch (e) {
      debugPrint('No se pudo eliminar el token: $e');
    }
  }
}

class NoopPushService implements PushService {
  const NoopPushService();

  @override
  Future<void> register(String uid) async {}

  @override
  Future<void> unregister(String uid) async {}
}

final pushServiceProvider = Provider<PushService>(
  (ref) => FirebasePushService(
    FirebaseMessaging.instance,
    FirebaseFirestore.instance,
  ),
);

/// Escucha la sesión: registra el dispositivo al entrar y lo quita al salir.
final pushRegistrationProvider = Provider<void>((ref) {
  String? registered;
  ref.listen<SessionState>(sessionProvider, (_, next) {
    final push = ref.read(pushServiceProvider);
    if (next is SessionReady && registered != next.uid) {
      registered = next.uid;
      unawaited(push.register(next.uid));
    } else if (next is SignedOut && registered != null) {
      unawaited(push.unregister(registered!));
      registered = null;
    }
  }, fireImmediately: true);
});
