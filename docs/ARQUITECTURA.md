# Vantia — Arquitectura

## 1. Stack

| Capa | Elección | Por qué |
|---|---|---|
| App | **Flutter 3.x / Dart 3** | Un solo código para Android e iOS, UI Material 3 igual a la referencia, buen soporte de ML Kit, cámara y TTS |
| Estado | **Riverpod 2** (`riverpod_generator`) | Testeable, sin `BuildContext`, streams de Firestore como `StreamProvider` |
| Navegación | **go_router** | Guards declarativos (auth, verificación, rol) y deep links (enlace de verificación) |
| Modelos | **freezed + json_serializable** | Inmutabilidad, `copyWith`, uniones para estados |
| Backend | **Firebase**: Auth, Firestore, Functions (TypeScript), Storage, FCM, Remote Config, Crashlytics, App Check | Verificación de correo nativa, offline-first, sin servidores que mantener |
| Región | `southamerica-east1` (São Paulo) | La región de GCP más cercana a Lima |
| Pagos in-app | RevenueCat + Google Play Billing | Webhooks, gestión de pruebas, sin lógica de recibos propia |
| Paquetes clave | `fl_chart`, `mobile_scanner`, `google_mlkit_text_recognition`, `flutter_tts`, `excel`, `pdf`, `share_plus`, `in_app_review`, `intl`, `image_picker` | |
| Nativo Android | Kotlin `NotificationListenerService` + MethodChannel/EventChannel | Captura de notificaciones de Yape y Plin |

## 2. Estructura del proyecto (feature-first + capas)

```
app/                        # Proyecto Flutter
  lib/
    main_dev.dart / main_prod.dart
    app/                    # MaterialApp, router, tema, flavors
    core/                   # money, dates (America/Lima), result, errors, widgets compartidos
    features/
      auth/        {data, domain, presentation}
      onboarding/
      business/
      payments/
      cash_register/
      collaborators/
      products/
      reports/
      automation/           # ocr, notification_listener, tts
      settings/
      user/                 # pestaña Usuario → Info
      subscription/
    l10n/                   # app_es.arb
  android/app/src/main/kotlin/.../PaymentNotificationListener.kt
  test/  integration_test/
functions/                  # Cloud Functions (TypeScript)
firebase/                   # firestore.rules, storage.rules, indexes, emulators
docs/
```

Dentro de cada feature hay tres capas:
- `domain`: entidades e interfaces de repositorio, en Dart puro.
- `data`: DTOs e implementación con Firestore.
- `presentation`: pantallas, widgets y controllers de Riverpod.

## 3. Modelo de datos (Firestore)

Los montos van en **céntimos (`int`)** y las fechas en `Timestamp`. El campo `dayKey` (`yyyy-MM-dd` en hora de Lima) permite agrupar sin calcular zonas horarias en las consultas.

```
users/{uid}
  displayName, email, phone, photoUrl, createdAt
  activeBusinessId, role: owner|collaborator
  prefs: { theme, voiceAnnouncements, autoVerify }

businesses/{bid}
  name, ownerUid, phone, department, province, ruc?
  plan: { tier: free|pro, trialEndsAt, renewsAt? }
  createdAt

businesses/{bid}/members/{uid}
  role, displayName, active, joinedAt, inviteCode

businesses/{bid}/invites/{code}
  createdBy, createdAt, expiresAt, status: active|used|revoked, usedBy?, usedAt?

businesses/{bid}/payments/{pid}
  method: yape|plin|bcp|interbank|bbva|scotiabank|cash
  amountCents          # venta neta
  receivedCents?       # efectivo: monto recibido
  changeCents?         # efectivo: cambio entregado
  description?, operationNumber?, payerName?
  occurredAt, dayKey, createdAt, createdBy, createdByName
  source: manual|ocr|notification
  verified: bool
  status: active|voided, voidReason?
  receiptPath?, items?: [{productId, name, qty, unitPriceCents}]
  dedupeKey?           # hash(method, amount, operationNumber|payer+minute)

businesses/{bid}/cashSessions/{dayKey}_{uid}
  dayKey, uid, openingCents, cashReceivedCents, changeGivenCents,
  expectedCents, countedCents, differenceCents,
  totalsByMethod: {yape: 1000, ...}, status: open|closed|reopened,
  closedAt?, reopenedBy?, reopenReason?

businesses/{bid}/products/{id}
  name, barcode?, priceCents, category?, stock?, active, createdAt

businesses/{bid}/dailyStats/{dayKey}           # solo lo escriben las Functions
  totalCents, count, cashCount, digitalCount,
  byMethod: {yape: {cents, count}}, byUser: {uid: {cents, count}}

businesses/{bid}/audit/{id}                     # solo lo escriben las Functions
```

Índices: `payments(dayKey, createdBy)`, `payments(occurredAt desc)`, `payments(createdBy, occurredAt desc)`, `products(barcode)`.

## 4. Cloud Functions

| Función | Trigger | Responsabilidad |
|---|---|---|
| `createBusiness` | callable | Crea el negocio y el miembro dueño, inicia la prueba y fija los custom claims `{bid, role}` |
| `generateInvite` / `revokeInvite` | callable | Solo el dueño. Código único con reintentos |
| `redeemInvite` | callable | Transacción: valida el código y crea el miembro. Fija los claims |
| `onPaymentWrite` | Firestore | Actualiza `dailyStats` (idempotente por `eventId`), envía FCM al dueño y escribe la auditoría |
| `closeCashSession` / `reopenCashSession` | callable | Calcula los totales en el servidor (no confía en el cliente) y congela el snapshot |
| `exportPayments` | callable | Genera el XLSX o PDF en Storage y devuelve una URL firmada |
| `revenuecatWebhook` | HTTPS | Actualiza `business.plan` |
| `deleteAccount` | callable | Borra o anonimiza los datos del usuario |
| `expireTrials` | scheduler diario | Pasa a `free` los negocios con la prueba vencida |

## 5. Seguridad

- **Toda** lectura y escritura exige `request.auth != null && request.auth.token.email_verified == true`.
- La pertenencia al negocio se valida con custom claims (`bid`, `role`) y un fallback a `members/{uid}`.
- `payments`:
  - Crear: solo si `createdBy == auth.uid` y el negocio coincide.
  - Leer: el dueño lee todo; el colaborador solo `createdBy == auth.uid`.
  - Actualizar: solo `status/voidReason`, aplicando las reglas de [PLAN §2](PLAN.md#2-roles-y-permisos).
  - Borrar: prohibido.
- `dailyStats`, `audit`, `invites`, `cashSessions.status = closed`: solo los escribe el Admin SDK.
- Storage: `receipts/{bid}/{pid}.jpg`, máximo 5 MB, solo `image/*`, acceso solo para miembros.
- App Check (Play Integrity) obligatorio en Functions y Firestore en `prod`.

## 6. Flujo de verificación de correo

```
Registro ─► createUserWithEmailAndPassword ─► sendEmailVerification(actionCodeSettings)
        ─► /auth/verify-email  (Reenviar con cooldown de 60 s · "Ya verifiqué" ─► user.reload())
        ─► emailVerified == true ─► getIdToken(true) (refresca el claim) ─► /onboarding/role
```
- El enlace abre la app por App Links (`vantia.page.link` o un dominio propio). Si la app no está instalada, cae en una web de confirmación.
- La app también revisa la verificación al volver a primer plano (`AppLifecycleState.resumed`).

## 7. Verificación automática Yape/Plin (Android)

```
NotificationListenerService (Kotlin)
  └─ filtra los paquetes com.bcp.innovacxion.yapeapp / pe.plin.app (lista en Remote Config)
  └─ envía el texto por EventChannel ─► Dart: NotificationParser (regex versionadas)
       └─ PaymentDraft ─► dedupe ─► PaymentRepository.create(source: notification, verified: true)
       └─ TTS: "Yape: recibiste S/ 10.00 de Juan P."
```
Los parsers se testean con fixtures reales anonimizados (`test/fixtures/notifications/*.txt`).

## 8. Testing

- **Unit:** money, fechas en Lima, parsers, cálculos de caja, controllers.
- **Widget:** formularios de pago, verify-email, cuadre de caja.
- **Reglas:** `@firebase/rules-unit-testing` contra el emulador, en CI.
- **Integración:** `integration_test` del flujo registro → verificar (emulador de Auth) → crear negocio → registrar pago → cerrar caja.
