# Vantia — Informe de avance

**Fecha:** 3 de noviembre de 2026
**Rama de trabajo:** `ccr-e89000a1-3kvjkg`
**Commits:** `7c583e0` (plan y base del repo) · `623153b` (M0 en código) · `b004f87` (README)

---

## 1. Resumen

| Indicador | Estado |
|---|---|
| Plan de features y arquitectura | ✅ Completo |
| Organización en GitHub (épicos y features) | ✅ 65 issues (#1–#65) |
| Base del repositorio (README, .gitignore, plantillas, CI) | ✅ Completo |
| **M0 — Fundaciones** | 🟡 ~90 % (5 de 6 features completas, F-06 parcial) |
| M1 a M9 | ⬜ Pendientes |
| Calidad del código | `flutter analyze`: 0 avisos · `flutter test`: **36/36 tests en verde** |
| Avance estimado del proyecto | **≈ 7 %** (≈ 4 de 55 días-dev estimados) |

> La app compila y pasa los tests, pero **todavía no tiene funciones de negocio reales**: no hay login, no se registran pagos y no hay conexión a una base de datos. Lo construido es la base sobre la que se desarrollan todas las demás funcionalidades.

---

## 2. Avances realizados

### 2.1 Planificación y documentación

| Archivo | Contenido |
|---|---|
| `docs/PLAN.md` | Alcance, funciones de cada pantalla de la referencia, roles y permisos (Dueño/Colaborador), roadmap M0–M9 con 55 features y sus criterios de aceptación, navegación, eventos de analítica y riesgos |
| `docs/ARQUITECTURA.md` | Stack (Flutter + Firebase), estructura de carpetas, modelo de datos de Firestore, Cloud Functions, reglas de seguridad, flujo de verificación de correo y captura de Yape/Plin |
| `README.md`, `app/README.md` | Descripción, requisitos, cómo ejecutar el proyecto, estructura |
| `CONTRIBUTING.md` | Ramas, Conventional Commits, PRs y Definition of Done |

### 2.2 Repositorio y GitHub

- `.gitignore` en la raíz, en `app/` y en `functions/`. Excluyen claves de firma, archivos de configuración de Firebase (`google-services.json`, `firebase_options*.dart`), compilados y secretos.
- `.gitattributes`, `.editorconfig` y `.env.example`.
- Plantillas de issue (Feature y Bug) y de Pull Request.
- **CI (GitHub Actions):** formato, análisis y tests en cada PR, con Flutter 3.47.9 fijado. Compila el APK `dev` en `main` y lo deja como artifact. Tiene un job para Cloud Functions que se activa cuando exista `functions/package.json`.
- **Issues:** 10 épicos (uno por etapa) y 55 features como sub-issues, con el tipo `Feature` y sus criterios de aceptación.

| Épico | Issue | Features (sub-issues) |
|---|---|---|
| M0 Fundaciones | #1 | #11–#16 |
| M1 Autenticación y onboarding | #2 | #17–#25 |
| M2 Pagos | #3 | #26–#33 |
| M3 Colaboradores | #4 | #34–#37 |
| M4 Cuadre de caja | #5 | #38–#43 |
| M5 Reportes y exportación | #6 | #44–#48 |
| M6 Productos | #7 | #49–#52 |
| M7 Automatización | #8 | #53–#56 |
| M8 Usuario, ajustes y suscripción | #9 | #57–#62 |
| M9 Calidad y lanzamiento | #10 | #63–#65 |

### 2.3 M0 — Fundaciones (código en `app/`)

| ID | Feature | Estado | Detalle |
|---|---|:-:|---|
| F-01 | Proyecto Flutter + flavors | ✅ | Package `pe.vantia.app`. Flavors `dev` (`pe.vantia.app.dev`, "Vantia Dev") y `prod`. Entrypoints `main_dev.dart` y `main_prod.dart` |
| F-02 | Arquitectura base | ✅ | Estructura por funcionalidad, Riverpod 3 y go_router. Guards de acceso en una función pura testeada: sesión → correo verificado → negocio → rol. Shell con 4 pestañas, FAB central y menú lateral. Tipos `Result`/`Failure` |
| F-03 | Design system | ✅ | Tokens de la referencia, tema claro/oscuro/sistema guardado en el dispositivo, fuente Poppins incluida en la app (licencia OFL). Componentes `VCard`, `VButton`, `VTextField`, `MoneyText`, `EmptyState`, `PaymentMethodIcon` y `PaymentMethodTile` |
| F-04 | i18n, dinero y zona horaria | ✅ | Textos en `app_es.arb`. `Money` en céntimos, con formato `S/ 1,234.50` y parseo de lo que escribe el usuario (`10,50`, `1.234,50`…). `LimaTime`: `dayKey`, inicio de día, semana (lunes) y mes, y formatos "2 nov. 2026" |
| F-05 | CI/CD | ✅ | Ver §2.2. Falta proteger la rama `main` (ver §4) |
| F-06 | Observabilidad | 🟡 | Catálogo de eventos y una interfaz `Analytics` (por ahora solo escribe en la consola de depuración). Se capturan los errores globales. **Falta** conectar Firebase Analytics y Crashlytics |

**Pantallas disponibles hoy:**
- Navegación entre las 4 pestañas.
- Menú lateral (con datos de ejemplo).
- Selector "¿Cómo pagó el cliente?" (solo la interfaz).
- Productos con su estado vacío.
- Ajustes con el selector de tema, que ya funciona.

El resto muestra "Disponible pronto (F-xx)".

**Correcciones respecto a la app de referencia que ya están aplicadas:**
- Todo el idioma en es-PE (sin "Home", "Products" ni "By me").
- El teléfono del menú lleva el ícono correcto.
- Hay un margen inferior reservado para que el FAB no tape contenido.

**Tests (36):** dinero (formato, parseo, aritmética), fechas de Lima (cambios de día, semana y mes), guards del router (los 5 estados de sesión y los permisos por rol), y pruebas de widget del shell (pestañas, FAB, menú y persistencia del tema).

---

## 3. Pendiente por realizar

### 3.1 Para cerrar M0

- [ ] **F-06:** integrar Firebase Analytics y Crashlytics. Requiere el proyecto de Firebase.
- [ ] **F-05:** proteger la rama `main`: PR obligatorio, CI en verde y 1 aprobación.
- [ ] Validar la compilación del APK en el CI y probarlo en un dispositivo real. Este entorno no tiene SDK de Android.

### 3.2 Etapas siguientes

| Etapa | Contenido principal | Estimación | Depende de |
|---|---|:-:|---|
| **M1** Autenticación y onboarding | Registro, **verificación de correo**, login, recuperar contraseña, rol, crear negocio / unirse con código, cerrar sesión | 6 d | Firebase |
| **M2** Pagos | Registro en efectivo y digital, Inicio con el resumen del día, lista semanal, anulación, modo offline | 8 d | M1 |
| **M3** Colaboradores | Códigos de invitación, gestión de colaboradores, push al dueño | 4 d | M2 |
| **M4** Cuadre de caja | Mi caja, caja física, diferencia, cerrar/reabrir, resumen general | 5 d | M2 |
| **M5** Reportes | Agregados diarios, Semana/Mes/Año, KPIs, exportar a Excel o PDF | 5 d | M2 |
| **M6** Productos | Código de barras, producto sin código, venta con productos | 5 d | M2 |
| **M7** Automatización | OCR de comprobantes, captura de Yape/Plin (Android), anuncio por voz | 8 d | M2 |
| **M8** Usuario y suscripción | **Pestaña Usuario → Info**, perfil, eliminar cuenta, ajustes, plan y pagos in-app | 5 d | M1 |
| **M9** Calidad y lanzamiento | Tests E2E, accesibilidad, publicación en Google Play | 5 d | Todas |

**Restante:** ≈ 51 días-dev para 1 desarrollador, o ≈ 6 semanas con 2 desarrolladores en paralelo. Con 2 personas, una toma M3/M4 y la otra M5/M6 después de M2.

### 3.3 Componentes aún no creados

- `functions/`: Cloud Functions en TypeScript (`createBusiness`, `redeemInvite`, `onPaymentWrite`, `closeCashSession`, etc.).
- `firebase/`: `firestore.rules`, `storage.rules`, índices y configuración de emuladores.
- Código nativo de Android (Kotlin) para leer las notificaciones de Yape y Plin.
- Logos oficiales de los medios de pago. Hoy se usan distintivos con iniciales y colores.

---

## 4. Acciones requeridas del dueño del proyecto

| # | Acción | Por qué | Bloquea |
|:-:|---|---|---|
| 1 | **Crear la rama `main`** desde el commit `7c583e0`, o autorizar que la cree yo | Sin `main` no se puede abrir el PR de M0 ni proteger la rama, y los enlaces a `docs/` en los issues no funcionan | PR de M0 |
| 2 | **Crear los proyectos de Firebase** `vantia-dev` y `vantia-prod` (plan Blaze para las Functions), con Authentication por correo/contraseña activado | Login, verificación de correo, base de datos | M1 en adelante |
| 3 | Ejecutar `flutterfire configure --project=vantia-dev` dentro de `app/` | Genera la configuración de Firebase, que no se sube al repo por seguridad | M1 |
| 4 | Revisar y aprobar el PR de M0 | Para hacer merge a `main` | — |
| 5 | Definir los precios del plan Pro y crear la cuenta de Google Play Console | Suscripción y publicación | M8, M9 |
| 6 | Revisar el uso permitido de los logos de Yape, Plin y los bancos | Son marcas registradas | M2 (íconos finales) |
| 7 | Confirmar la regla del pago en efectivo: **venta = monto recibido − cambio** | Afecta el cuadre de caja | M2, M4 |

---

## 5. Recomendaciones para continuar

1. **Cerrar M0 con un PR a `main`** antes de empezar M1. Así el CI corre sobre una base estable y se activa la protección de la rama.
2. **Empezar M1 con el emulador de Firebase** (Auth y Firestore) mientras se crea el proyecto real. El código es el mismo, solo cambia la configuración. Las reglas de seguridad se escriben y testean desde el primer día con `@firebase/rules-unit-testing`.
3. **Un PR por feature** (`feat/F-10-registro`, `feat/F-11-verificacion-correo`, …), con `Closes #n` para que los issues se cierren solos.
4. **Prioridad sugerida dentro de M1:**
   1. F-10 Registro
   2. F-11 Verificación de correo
   3. F-12 Login
   4. F-13 Recuperar contraseña
   5. F-15 Selección de rol, F-16 Crear negocio y F-17 Unirse con código
   6. F-18 Cerrar sesión

   F-14 (Google) es opcional y se puede dejar para el final.
5. **Adelantar F-80 (Usuario → Info)** justo después de M1. Solo depende de la sesión y del negocio, y es una de las funciones pedidas.
6. **Probar la captura de Yape/Plin (M7) cuanto antes** con un prototipo en un dispositivo real. Es la función de mayor riesgo técnico: depende de los permisos de Android, de la optimización de batería de cada fabricante y de la revisión de Google Play. Conviene validarla durante M2, no al final.
7. **Recolectar ejemplos reales anonimizados** de notificaciones y capturas de comprobantes de Yape, Plin y cada banco. Son necesarios para los parsers de OCR y de notificaciones, y para sus tests.
8. **Mantener las reglas del proyecto:** montos siempre en céntimos (`Money`), fechas agrupadas en hora de Lima (`LimaTime`), textos en `app_es.arb` y ningún acceso a Firestore desde los widgets.
9. **Crear las etiquetas `area:*` y `priority:*`** desde la configuración del repo. Así se pueden filtrar los issues por área; no se pudieron crear desde esta sesión.

---

## 6. Cómo verificar lo construido

```bash
cd app
flutter pub get
flutter analyze                                   # 0 avisos
flutter test                                      # 36 tests en verde
flutter run --flavor dev -t lib/main_dev.dart     # requiere emulador o dispositivo Android
```
