# Vantia

App móvil para negocios en Perú que registra cobros por **Yape, Plin, transferencias bancarias y efectivo**, cuadra la caja diaria, gestiona colaboradores y productos, y genera reportes.

> Estado: **M0 (Fundaciones) en curso**. Seguimiento en los [issues](https://github.com/Zicada-2002/Vantia-app/issues) (épicos #1–#10). Alcance y roadmap en [`docs/PLAN.md`](docs/PLAN.md). Decisiones técnicas en [`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md).

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

Flutter 3 · Riverpod · go_router · Firebase (Auth, Firestore, Functions, Storage, FCM, Crashlytics) · ML Kit · RevenueCat

## Estructura

```
app/        Proyecto Flutter (ver app/README.md)
functions/  Cloud Functions en TypeScript
firebase/   Reglas, índices y configuración de emuladores
docs/       Plan, arquitectura y convenciones
```

## Requisitos

- Flutter 3.47 o superior (Dart 3.9 o superior); el CI usa 3.47.9
- Node.js 20 y Firebase CLI (`npm i -g firebase-tools`)
- JDK 17 y Android Studio
- Un proyecto de Firebase para cada flavor (`vantia-dev`, `vantia-prod`)

## Puesta en marcha

```bash
git clone https://github.com/Zicada-2002/Vantia-app.git
cd Vantia-app/app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutterfire configure --project=vantia-dev   # genera firebase_options_dev.dart (no se versiona)
flutter run --flavor dev -t lib/main_dev.dart
```

Emuladores locales:

```bash
cd firebase && firebase emulators:start
```

## Contribuir

Lee [`CONTRIBUTING.md`](CONTRIBUTING.md). Resumen:
- Cada feature se trabaja en `feat/F-xx-descripcion`.
- Commits con [Conventional Commits](https://www.conventionalcommits.org/es/).
- PR con CI en verde y la checklist completa.

## Licencia

Propietaria. © 2026 Vantia Perú. Todos los derechos reservados.
