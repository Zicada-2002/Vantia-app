# Vantia — Guía de lanzamiento (F-92)

Pasos para publicar en Google Play. Lo marcado con 🧑 requiere acceso a cuentas del dueño del proyecto (Google Cloud/Firebase, Play Console, RevenueCat): no se puede hacer desde el repositorio.

## 1. Firebase de producción 🧑

> Paso a paso: [`FIREBASE_SETUP.md`](FIREBASE_SETUP.md).

1. Crear `vantia-prod` (y `vantia-dev`) en la consola de Firebase, con plan **Blaze** (lo requieren Functions y Scheduler).
2. **Authentication** → Correo/contraseña. Plantillas de correo en español: verificación y restablecimiento.
3. **Firestore** en `southamerica-east1` y **Storage** en la misma región.
4. Registrar la app Android con el package `pe.vantia.app` (prod) y `pe.vantia.app.dev` (dev). Copiar los valores a `app/env/prod.json` y `app/env/dev.json`, siguiendo la plantilla `env/dev.json.example`. Estos archivos no se versionan.
5. Desplegar reglas, índices y Functions:
   ```bash
   cd firebase
   firebase deploy --project prod --only firestore:rules,firestore:indexes,storage
   firebase functions:secrets:set REVENUECAT_WEBHOOK_SECRET --project prod
   firebase deploy --project prod --only functions
   ```
6. **App Check** → Play Integrity. Registrar el SHA-256 de la clave de firma de Play y activar el *enforcement* en Firestore, Storage y Functions cuando la app ya esté en pruebas internas.
7. **Crashlytics/Analytics**: se activan solos cuando la app no usa emuladores (`USE_FIREBASE_EMULATOR=false`).

## 2. Firma 🧑

```bash
keytool -genkey -v -keystore ~/vantia-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Crear `app/android/key.properties`. Este archivo no se versiona:

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=/ruta/absoluta/vantia-upload.jks
```

Sin este archivo, el build de release se firma con la clave debug. Sirve para CI, pero no para Play.

## 3. Build

```bash
cd app
flutter build appbundle --flavor prod -t lib/main_prod.dart \
  --dart-define-from-file=env/prod.json \
  --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx \
  --dart-define=SUPPORT_WHATSAPP=519XXXXXXXX
```

La versión sale de `pubspec.yaml` (`version: x.y.z+build`). Hay que subir el `+build` en cada envío.

## 4. Suscripciones (RevenueCat) 🧑

1. En Play Console, crear los productos de suscripción: `vantia_pro_mensual` y `vantia_pro_anual`.
2. En RevenueCat:
   - Crear el proyecto, el *entitlement* `pro` y una *offering* "default" con los dos paquetes.
   - Webhook hacia `https://southamerica-east1-vantia-prod.cloudfunctions.net/revenuecatWebhook`, con la cabecera `Authorization: Bearer <REVENUECAT_WEBHOOK_SECRET>`.
3. La app inicia sesión en RevenueCat con el **id del negocio**, así que el plan es del negocio y no de la persona.

## 5. Play Console 🧑

- **Pruebas internas** primero, luego pruebas cerradas (requisito para cuentas nuevas: 12 testers durante 14 días).
- **Ficha**: nombre "Vantia", descripción en es-PE, capturas (claro y oscuro), ícono de 512 px. El ícono actual es provisional (`res/drawable/ic_launcher_foreground.xml`).
- **Política de privacidad**: publicar `assets/legal/privacidad.txt`, después de la revisión legal, en una URL pública.
- **Eliminación de cuenta**: ya existe dentro de la app (Mi cuenta → Eliminar cuenta). Play además exige un **enlace web** donde pedir la eliminación.
- **Data Safety** (borrador):

  | Dato | Se recopila | Finalidad | Se comparte |
  |---|---|---|---|
  | Nombre, correo, teléfono | Sí | Cuenta, funcionalidad | No |
  | Información financiera (registros de cobro) | Sí | Funcionalidad | No |
  | Fotos (comprobantes, opcional) | Sí | Funcionalidad | No |
  | Identificadores del dispositivo (token FCM) | Sí | Notificaciones | No |
  | Registros de fallos y diagnóstico | Sí | Analítica | No |

  Cifrado en tránsito: sí. El usuario puede pedir la eliminación: sí.

- **Permisos sensibles**:
  - Cámara: escanear códigos y comprobantes.
  - **Acceso a notificaciones** (`NotificationListenerService`): solo lee Yape y apps bancarias con Plin para registrar cobros. La app muestra una explicación previa en "Verificación automática" y la función es opcional. En la revisión, adjuntar un video del flujo.

## 6. Pendientes antes de producción

- [ ] **Fixtures reales anonimizados** de notificaciones y comprobantes de cada app y versión. Los actuales son ejemplos construidos; ver `app/test/fixtures/*/README.md`.
- [ ] Revisión legal de términos y privacidad (Ley N.º 29733).
- [ ] Ícono y capturas definitivas.
- [ ] Probar en dispositivos Xiaomi, Samsung, Huawei y Oppo la persistencia del listener con la batería restringida.
- [ ] iOS: APNs para push y App Attest. La verificación automática no está disponible en iOS.
- [ ] F-14 Login con Google (opcional): requiere el SHA-1 del proyecto real.
- [ ] Ejecutar `flutter test integration_test --flavor dev` en un emulador o dispositivo.
