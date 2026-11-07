# Vantia — Guía de entrega para el cliente

Este paquete contiene el **código fuente completo** de Vantia: la app móvil (Flutter, Android/iOS) para registrar cobros (Yape, Plin, bancos y efectivo), cuadrar la caja, gestionar colaboradores y productos, y ver reportes. También incluye su backend en Firebase.

---

## 1. Contenido del paquete

```
app/          App Flutter (Android e iOS) + código nativo Kotlin (lectura de notificaciones)
functions/    Cloud Functions en TypeScript (lógica del servidor) + tests
firebase/     Reglas de seguridad de Firestore y Storage, índices, configuración de emuladores
docs/         Plan funcional, arquitectura, guía de publicación (RELEASE.md) y esta guía
.github/      CI con GitHub Actions (tests, análisis, build del APK)
THIRD_PARTY_NOTICES.md   Licencias de los componentes de código abierto
```

| Documento | Para qué sirve |
|---|---|
| `README.md` | Requisitos y puesta en marcha |
| `docs/PLAN.md` | Funcionalidades (55 features) y criterios de aceptación |
| `docs/ARQUITECTURA.md` | Diseño técnico, modelo de datos y seguridad |
| `docs/RELEASE.md` | Pasos para publicar en Google Play |
| `docs/INFORME_AVANCE.md` | Estado del proyecto y pendientes |

## 2. Lo que NO incluye (debe crearlo cada cliente)

Por seguridad, el paquete **no trae claves ni cuentas**. Cada cliente usa las suyas:

- Proyecto de **Firebase** propio (plan Blaze): `app/env/prod.json`, que se crea a partir de `app/env/dev.json.example`.
- **Clave de firma** de Android (`.jks`) y `app/android/key.properties`.
- Cuenta de **Google Play Console** y, para suscripciones, de **RevenueCat**.
- Dependencias descargables: `flutter pub get` y `npm ci` las instalan.

## 3. Requisitos

- Flutter 3.47 o superior (Dart 3.9)
- Node.js 22
- JDK 21
- Android Studio con un emulador o un celular Android
- Firebase CLI. Se instala con `npm ci` dentro de `functions/`.

## 4. Probar en 10 minutos (sin cuentas, con emuladores)

```bash
# Terminal 1: backend local (UI en http://localhost:4000)
cd functions && npm ci && npm run serve

# Terminal 2: la app
cd app && flutter pub get
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=env/emulator.json
```

El emulador no envía correos. El enlace de verificación aparece en la terminal 1.

**Verificar la calidad del código:**
```bash
cd app && flutter analyze && flutter test
cd functions && npm test && npm run test:emulator
```

## 5. Personalizar la marca (white-label)

| Qué | Dónde |
|---|---|
| Nombre visible de la app | `app/android/app/build.gradle.kts` (`resValue … app_name`) y `app/lib/app/flavor.dart` (`appTitle`) |
| Textos de la interfaz | `app/lib/l10n/app_es.arb`; luego ejecutar `flutter gen-l10n` |
| Identificador del paquete (`pe.vantia.app`) | `applicationId` y `namespace` en `app/android/app/build.gradle.kts`, la carpeta `app/android/app/src/main/kotlin/pe/vantia/app/` (y la línea `package` de sus archivos), `PRODUCT_BUNDLE_IDENTIFIER` en `app/ios/Runner.xcodeproj/project.pbxproj` y `iosBundleId` en `app/lib/app/firebase/firebase_env.dart` |
| Colores | `app/lib/app/theme/tokens.dart` |
| Tipografía | `app/assets/fonts/` y `app/pubspec.yaml` |
| Ícono | `app/android/app/src/main/res/drawable/ic_launcher_foreground.xml`, el color de fondo en `res/values/ic_launcher_background.xml` y los `mipmap-*` |
| Términos y privacidad | `app/assets/legal/` (son borradores: los debe revisar un abogado) |
| WhatsApp de soporte | `--dart-define=SUPPORT_WHATSAPP=51XXXXXXXXX` al compilar |
| Suscripción | `--dart-define=REVENUECAT_ANDROID_KEY=…` y los productos en Play Console (ver `docs/RELEASE.md` §4) |

## 6. Publicar

Sigue `docs/RELEASE.md`:

1. Crear Firebase.
2. Desplegar reglas y Functions.
3. Firmar la app.
4. Compilar el `.aab`.
5. Configurar Play Console (pruebas internas y cerradas, Data Safety y el permiso de acceso a notificaciones).

## 7. Avisos importantes

- **Marcas de terceros:** Yape, Plin, BCP, Interbank, BBVA y Scotiabank se mencionan solo para identificar el medio de pago. El paquete **no incluye sus logos**: los íconos son distintivos genéricos con iniciales. Si se agregan logos oficiales, hay que revisar las pautas de marca de cada entidad.
- **Lectura automática de Yape/Plin:** funciona interpretando el texto de las notificaciones. Esos textos pueden cambiar con las actualizaciones de cada app. Los ejemplos de prueba (`app/test/fixtures/`) son de muestra; antes de producción hay que validar con notificaciones reales.
- **Licencias de código abierto:** todas son permisivas y permiten el uso comercial (detalle en `THIRD_PARTY_NOTICES.md`). Hay que conservar esos avisos al redistribuir.
- **Pendientes conocidos:** ver `docs/INFORME_AVANCE.md` §4 (pruebas en dispositivos reales, revisión legal, ícono final, login con Google opcional).
