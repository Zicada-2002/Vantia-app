# Vantia

App móvil para negocios en Perú que registra cobros por **Yape, Plin, transferencias bancarias y efectivo**, cuadra la caja diaria, gestiona colaboradores y productos, y genera reportes.

> Estado: **plan M0–M9 implementado** (ver [`docs/INFORME_AVANCE.md`](docs/INFORME_AVANCE.md)); pendiente la configuración de cuentas reales y la publicación ([`docs/RELEASE.md`](docs/RELEASE.md)). Seguimiento en los [issues](https://github.com/Zicada-2002/Vantia-app/issues) (épicos #1–#10). Alcance y roadmap en [`docs/PLAN.md`](docs/PLAN.md). Decisiones técnicas en [`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md).

## Funcionalidades

- 🔐 Registro e inicio de sesión con **verificación de correo**
- 👥 Roles **Dueño** y **Colaborador**, con invitaciones por código
- 💸 Registro de pagos: Yape, Plin, BCP, Interbank, BBVA, Scotiabank y efectivo (con cambio)
- 📷 Lectura de comprobantes por OCR
- 🔔 Verificación automática de Yape y Plin, y anuncio de cada cobro por voz (Android)
- 🧾 Cuadre de caja: fondo inicial, efectivo, cambios, diferencia y cierre
- 📦 Productos con código de barras o sin código, y venta con productos
- 📊 Reportes por semana, mes y año, y exportación a Excel o PDF
- 👤 Pestaña Usuario con información de la cuenta y del negocio
- 🌗 Tema claro, oscuro o del sistema

## Stack

Flutter 3 · Riverpod 3 · go_router · Firebase (Auth, Firestore, Functions, Storage, FCM, Analytics, Crashlytics, App Check) · ML Kit · mobile_scanner · fl_chart · RevenueCat · Kotlin (NotificationListenerService)

## Estructura

```
app/        Proyecto Flutter (ver app/README.md)
functions/  Cloud Functions en TypeScript
firebase/   Reglas, índices y configuración de emuladores
docs/       Plan, arquitectura y convenciones
```

## Probar sin instalar nada (APK demo)

El CI genera en cada PR el artifact **`vantia-demo-apk`** (*Actions → CI → Artifacts*): una versión que funciona sin Firebase, con datos de ejemplo que se reinician al cerrar la app. En el login, toca **"Entrar a la demo"** (`demo@vantia.pe` / `demo1234`).

Compilarlo localmente: `cd app && flutter build apk --flavor demo -t lib/main_demo.dart --release`.

## Requisitos

- Flutter 3.47 o superior (Dart 3.9 o superior); el CI usa 3.47.9
- Node.js 22
- JDK 21 (lo necesitan los emuladores de Firebase) y Android Studio con un emulador Android
- Para producción: proyectos de Firebase `vantia-dev` y `vantia-prod`. **Para desarrollar no hace falta ninguno:** se usan los emuladores locales

## Puesta en marcha (local, con emuladores)

```bash
git clone https://github.com/Zicada-2002/Vantia-app.git
cd Vantia-app

# 1) Backend local: Auth + Firestore + Functions (UI en http://localhost:4000)
cd functions && npm ci && npm run serve

# 2) En otra terminal: la app contra los emuladores
cd app && flutter pub get
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=env/emulator.json
```

- En el **emulador de Android** la app usa `10.0.2.2` para llegar a la PC.
- En un **celular físico** cambia `FIREBASE_EMULATOR_HOST` en `app/env/emulator.json` por la IP local de tu PC (p. ej. `192.168.1.20`). La PC y el celular deben estar en la misma red Wi-Fi.
- El emulador de Auth **no envía correos**. El enlace de verificación aparece en la terminal de los emuladores; ábrelo y luego toca "Ya verifiqué mi correo".

### Con un proyecto real de Firebase

Guía completa paso a paso: [`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md). Resumen:

Copia `app/env/dev.json.example` a `app/env/dev.json` (no se versiona) y completa los valores de la consola de Firebase. Luego ejecuta:

```bash
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=env/dev.json
cd firebase && firebase deploy --project dev --only firestore:rules,functions
```

## Tests

```bash
cd app && flutter analyze && flutter test        # app (unitarios, widget, accesibilidad)
cd app && flutter test integration_test --flavor dev   # E2E en dispositivo/emulador
cd functions && npm test                          # unit tests de Functions
cd functions && npm run test:emulator             # integración + reglas de seguridad
```

## Entrega a clientes

- Guía para el comprador: [`docs/ENTREGA.md`](docs/ENTREGA.md)
- Licencias de terceros: [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md)
- Generar el `.zip` de entrega: `scripts/empaquetar.sh` (solo archivos versionados, sin claves)

## Contribuir

Lee [`CONTRIBUTING.md`](CONTRIBUTING.md). Resumen:
- Cada feature se trabaja en `feat/F-xx-descripcion`.
- Commits con [Conventional Commits](https://www.conventionalcommits.org/es/).
- PR con CI en verde y la checklist completa.

## Licencia

Propietaria. © 2026 Vantia Perú. Todos los derechos reservados.
