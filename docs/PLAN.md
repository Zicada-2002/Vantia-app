# Vantia — Plan de features

> App móvil para negocios en Perú: registro de cobros (Yape, Plin, bancos y efectivo), cuadre de caja, colaboradores, productos y reportes.
> Este documento es la fuente de verdad del alcance. Cada feature tiene un ID (`F-xx`) que se usa en issues, ramas y commits.
>
> **Estado (3 nov 2026):** M0–M9 implementados en código, salvo F-14 (login con Google, opcional). Lo pendiente para publicar está en [`RELEASE.md`](RELEASE.md) e [`INFORME_AVANCE.md`](INFORME_AVANCE.md).

---

## 1. Alcance

### 1.1 Funcionalidades identificadas en las capturas

| Pantalla | Qué hace |
|---|---|
| Onboarding de rol | Elegir **Dueño de negocio** o **Colaborador** antes de continuar |
| Menú lateral | Cabecera con negocio, teléfono y ubicación. Inicio, Colaboradores, Cuadre de caja, Configuración, Cerrar sesión |
| Inicio | Resumen del día: ingresos, nº de pagos, efectivo vs. digital. Últimos pagos con quién los registró |
| Colaboradores | Generar código de invitación y listar los códigos |
| Cuadre de caja | Selector de fecha. "Mi caja" / "Resumen general". Total del turno por método. Caja física: fondo inicial + efectivo recibido − cambios dados, total contado, diferencia, **Cerrar caja** |
| Ajustes | Tarjeta de perfil, plan (Free / prueba de 7 días / Mejorar ahora), tema claro/sistema/oscuro, anunciar cobros por voz, verificación automática Yape/Plin, términos, privacidad, valorar app, versión |
| Pagos | Navegación por semana, ingreso semanal, pagos agrupados por día, exportar por rango de fechas |
| Productos | Lista con estado vacío. Alta por **código de barras** o **producto sin código** |
| Reportes | Semana / Mes / Año, total, gráfico de barras de ingresos, nº en efectivo, nº digitales, mejor día, desglose por método |
| Registrar pago (FAB +) | "¿Cómo pagó el cliente?": Yape, Plin, BCP, Interbank, BBVA, Scotiabank, Efectivo. Opción "Registrar productos vendidos". Escaneo del comprobante (digital) o formulario manual |
| Confirmar pago | Fecha, hora, monto, cambio, descripción, **Registrar pago** |

### 1.2 Funcionalidades nuevas pedidas

- **Login con verificación de correo**: registro, inicio de sesión, verificación por enlace, recuperar contraseña y bloqueo de la app hasta verificar.
- **Pestaña Usuario → Info**: datos personales, datos del negocio, rol, plan, miembro desde, soporte, FAQ y versión.

### 1.3 Mejoras sobre la referencia (lo que corrijo como senior)

- Idioma consistente en **es-PE**. La referencia mezcla inglés y español ("Home", "Products", "By me"), y su menú dice "Configuración" mientras la pantalla dice "Ajustes".
- En la cabecera del menú, el teléfono aparece con un ícono de correo.
- En Reportes, el contenido final queda tapado por el FAB y la barra inferior: hace falta padding inferior seguro.
- Montos guardados en **céntimos (enteros)**, nunca `double`.
- Zona horaria fija **America/Lima** para todo lo que agrupa por día o semana (cierres, reportes).
- Modo offline: se puede registrar un cobro sin conexión y se sincroniza después.

### 1.4 Fuera de alcance del MVP

- Facturación electrónica SUNAT (boletas y facturas). Va en la fase 2, con un proveedor OSE/PSE.
- App iOS con verificación automática Yape/Plin: iOS no permite leer notificaciones de otras apps. iOS tendrá todo lo demás.
- Panel web para el dueño.

---

## 2. Roles y permisos

| Acción | Dueño | Colaborador |
|---|:-:|:-:|
| Registrar pago | ✅ | ✅ |
| Ver pagos propios | ✅ | ✅ |
| Ver pagos de todo el negocio | ✅ | ❌ |
| Editar o anular un pago | ✅ (cualquiera) | Solo los propios, dentro de 15 min |
| Cuadre "Mi caja" | ✅ | ✅ |
| Cuadre "Resumen general" | ✅ | ❌ |
| Reabrir una caja cerrada | ✅ | ❌ |
| Gestionar colaboradores e invitaciones | ✅ | ❌ |
| Crear o editar productos | ✅ | Solo lectura (configurable) |
| Reportes y exportación | ✅ | ❌ |
| Plan y suscripción | ✅ | ❌ |

Los permisos se validan en **Firestore Security Rules y Cloud Functions**, no solo en la UI.

---

## 3. Roadmap por milestones

Cada milestone es un **Milestone de GitHub**. Cada `F-xx` es un **issue** con criterios de aceptación. Las estimaciones están en días de un desarrollador.

### M0 — Fundaciones (≈4 d)

| ID | Feature | Criterios de aceptación |
|---|---|---|
| F-01 | Proyecto Flutter + flavors `dev`/`prod` | `flutter run --flavor dev` levanta contra Firebase dev. Package `pe.vantia.app` |
| F-02 | Arquitectura base | Estructura feature-first ([ARQUITECTURA.md](ARQUITECTURA.md)), Riverpod, go_router con guards, `Result`/`Failure` |
| F-03 | Design system | Tokens de color de la referencia (azul `#A8C7FA`, fondo `#0E111A`), tipografía Poppins, tema claro y oscuro, componentes: `VCard`, `VButton`, `VTextField`, `MoneyText`, `EmptyState`, `PaymentMethodIcon` |
| F-04 | i18n y formato | `intl` es-PE, `S/ 1,234.50`, fechas "2 nov. 2026", zona horaria America/Lima |
| F-05 | CI/CD | GitHub Actions: `format`, `analyze`, `test` en cada PR. Build de APK `dev` como artifact |
| F-06 | Observabilidad | Crashlytics, Analytics con eventos nombrados ([§5](#5-eventos-de-analytics)) |

### M1 — Autenticación y onboarding (≈6 d)

| ID | Feature | Criterios de aceptación |
|---|---|---|
| F-10 | Registro con correo | Nombre, correo, contraseña (mín. 8, 1 número), aceptar términos. Envía correo de verificación |
| F-11 | Verificación de correo | Pantalla "Revisa tu correo" con **Reenviar** (cooldown de 60 s) y **Ya verifiqué** (`reload()`). El router bloquea toda ruta privada si `emailVerified == false`. Las reglas exigen `request.auth.token.email_verified` |
| F-12 | Login | Correo y contraseña, errores mapeados a español, "Mostrar contraseña", sesión persistente |
| F-13 | Recuperar contraseña | Enlace por correo. El mensaje no revela si el correo existe |
| F-14 | Login con Google (opcional) | Se considera verificado automáticamente |
| F-15 | Selección de rol | Pantalla "¿Cómo usarás la aplicación?" con dos tarjetas. **Continuar** deshabilitado hasta elegir |
| F-16 | Crear negocio (Dueño) | Nombre del negocio, teléfono (+51, 9 dígitos), departamento y provincia. Crea `business` y `member(owner)` e inicia la prueba de 7 días |
| F-17 | Unirse con código (Colaborador) | Ingresar el código de 6 caracteres. La Cloud Function `redeemInvite` lo valida (vigente, no usado) y crea el `member(collaborator)` |
| F-18 | Cerrar sesión | Confirmación, limpia caché local y cancela listeners |

### M2 — Pagos (núcleo) (≈8 d)

| ID | Feature | Criterios de aceptación |
|---|---|---|
| F-20 | Selector de método de pago | Grilla de 7 métodos. Toggle "Registrar productos vendidos" (lleva a F-63) |
| F-21 | Confirmar pago en efectivo | Fecha y hora por defecto "ahora" (editables), **monto recibido**, **cambio entregado** (≤ monto), descripción opcional. Venta = monto − cambio. Botón deshabilitado hasta que el monto sea mayor a 0 |
| F-22 | Pago digital manual | Mismo formulario sin "cambio" y con nº de operación opcional (sirve para detectar duplicados) |
| F-23 | Inicio: resumen del día | Ingresos de hoy, nº de pagos, efectivo y digital, en tiempo real. El dueño ve el negocio, el colaborador ve lo suyo |
| F-24 | Últimos pagos | Últimos 10 con ícono del método, fecha y la etiqueta **"Tú"** o el nombre del colaborador |
| F-25 | Lista de pagos semanal | Semana lunes a domingo con flechas, ingreso semanal, grupos por día ("HOY, 2 NOV") con subtotal, paginación |
| F-26 | Detalle, edición y anulación | Anulación lógica (`status: voided`, motivo) con auditoría. Nunca se borra un pago |
| F-27 | Offline | Persistencia de Firestore activa. Badge "pendiente de sincronizar" |

### M3 — Colaboradores (≈4 d)

| ID | Feature | Criterios de aceptación |
|---|---|---|
| F-30 | Generar código de invitación | Código de 6 caracteres sin ambiguos (sin 0/O/1/I), vence en 48 h, un solo uso. Compartir por WhatsApp con `share_plus` |
| F-31 | Listado de códigos | Estados: vigente, usado (por quién), vencido, revocado. Acción **Revocar** |
| F-32 | Listado de colaboradores | Nombre, fecha de ingreso, ventas de hoy. Acción **Desactivar** (revoca el acceso; el historial se conserva) |
| F-33 | Notificación al dueño | Push FCM cuando un colaborador registra un cobro (configurable) |

### M4 — Cuadre de caja (≈5 d)

| ID | Feature | Criterios de aceptación |
|---|---|---|
| F-40 | Selector de fecha | Muestra "Viendo: 2 nov. 2026". No se pueden elegir días futuros |
| F-41 | Mi caja | Total del turno con desglose por método |
| F-42 | Caja física | Fondo inicial + efectivo recibido − cambios dados = **esperado**. Total contado (input). **Diferencia** = contado − esperado, en verde, rojo o neutro |
| F-43 | Cerrar caja | Confirmación. Guarda un snapshot inmutable de los totales. Después del cierre, la caja de ese día es de solo lectura; los pagos posteriores van al día siguiente o a una caja reabierta |
| F-44 | Resumen general (Dueño) | Suma de todas las cajas del día, estado de cada colaborador (abierta o cerrada) y diferencias |
| F-45 | Reabrir caja (Dueño) | Con motivo, auditado |

### M5 — Reportes y exportación (≈5 d)

| ID | Feature | Criterios de aceptación |
|---|---|---|
| F-50 | Agregados diarios | La Cloud Function `onPaymentWrite` mantiene `dailyStats/{yyyy-MM-dd}` (por método y por usuario) de forma idempotente |
| F-51 | Reportes Semana / Mes / Año | Tarjeta de total, gráfico de barras con `fl_chart` (días, semanas o meses), con variación respecto al periodo anterior |
| F-52 | KPIs | Nº en efectivo, nº digitales, mejor día, ticket promedio |
| F-53 | Métodos de pago | Barra apilada con los colores de cada marca y una lista con monto y % |
| F-54 | Exportar | Rango de fechas, luego **Excel (.xlsx)** o **PDF**, compartido con `share_plus`. Decisión: se genera en el dispositivo, con rango máximo de 1 año |

### M6 — Productos (≈5 d)

| ID | Feature | Criterios de aceptación |
|---|---|---|
| F-60 | Lista de productos | Búsqueda, estado vacío "Aún no has registrado productos" con contador |
| F-61 | Alta con código de barras | Escáner con `mobile_scanner` (EAN-13, EAN-8, UPC). Si el código ya existe, abre ese producto |
| F-62 | Producto sin código | Nombre, precio, categoría y stock opcional |
| F-63 | Venta con productos | Carrito: buscar o escanear, cantidades, total sugerido para el monto del pago. Si hay stock, se descuenta en una transacción |

### M7 — Automatización (≈8 d)

| ID | Feature | Criterios de aceptación |
|---|---|---|
| F-70 | Escaneo de comprobante (OCR) | Cámara o galería, `google_mlkit_text_recognition` en el dispositivo, parsers por banco (monto, fecha, nº de operación, nombre). Prellena el formulario y el usuario confirma. La imagen se guarda en Storage |
| F-71 | Verificación automática Yape/Plin (Android) | `NotificationListenerService` nativo (Kotlin) con un MethodChannel. Lee las notificaciones de Yape y Plin, las parsea y registra el pago con `source: notification` y `verified: true`. Se deduplica por hash. Pantalla de permisos guiada |
| F-72 | Anuncio por voz | `flutter_tts` es-PE: "Yape: recibiste diez soles de Juan P." Se activa con el toggle de Ajustes |
| F-73 | Persistencia del listener | ~~Servicio en primer plano~~ → decisión: el sistema mantiene vinculado el `NotificationListenerService`; guía para excluir la app de la optimización de batería (Xiaomi, Huawei, etc.) |

### M8 — Usuario, ajustes y suscripción (≈5 d)

| ID | Feature | Criterios de aceptación |
|---|---|---|
| F-80 | **Pestaña Usuario → Info** | Avatar con iniciales o foto. **Info personal** (nombre, correo con check de verificado, teléfono), **Info del negocio** (nombre, ubicación, RUC opcional, rol), **Cuenta** (plan, miembro desde), **Soporte** (WhatsApp, FAQ, reportar problema), versión y build |
| F-81 | Editar perfil | Nombre y teléfono. Cambiar correo con re-autenticación y nueva verificación. Cambiar contraseña |
| F-82 | Eliminar cuenta | Obligatorio para Google Play: re-autenticación y una Cloud Function que borra o anonimiza los datos |
| F-83 | Ajustes | Tema (claro, sistema, oscuro) persistido, toggles de notificaciones y verificación, términos y privacidad (WebView), valorar app (`in_app_review`), versión |
| F-84 | Plan y prueba | Banner "Tu prueba gratis termina en N días". Gating de funciones Pro: verificación automática, voz, OCR y colaboradores ilimitados |
| F-85 | Suscripción | Google Play Billing con RevenueCat. Webhook a una Function que actualiza `business.plan`. Pantalla de "Mejorar ahora" |

### M9 — Calidad y lanzamiento (≈5 d)

| ID | Feature | Criterios de aceptación |
|---|---|---|
| F-90 | Tests | Unit tests (parsers de OCR y notificaciones, cálculos de caja ≥ 90 %), widget tests de los flujos críticos, tests de reglas con el Firebase Emulator |
| F-91 | Accesibilidad | Contraste AA, semántica de lectores de pantalla, escala de fuente al 130 % sin overflow |
| F-92 | Release | Íconos, splash, firma, App Check, Play Console (prueba interna y cerrada), ficha de la tienda y declaración de permisos (`BIND_NOTIFICATION_LISTENER_SERVICE`) |

**Total estimado:** ≈ 55 días de desarrollo para 1 dev, o 6–7 semanas para 2 devs en paralelo (M3, M5 y M6 son independientes después de M2).

```
M0 ─► M1 ─► M2 ─┬─► M3 ─► M4
                ├─► M5
                ├─► M6
                └─► M7
M1 ─► M8 (F-80..F-83 pueden empezar tras M1)
todo ─► M9
```

---

## 4. Navegación

```
/splash
/auth/login · /auth/register · /auth/verify-email · /auth/forgot
/onboarding/role · /onboarding/business · /onboarding/join
/ (shell con barra inferior + FAB)
  ├─ /home
  ├─ /payments            → /payments/:id
  ├─ /products            → /products/new?barcode= · /products/:id
  └─ /reports
/payment/new              → /payment/new/cash · /payment/new/digital/:method · /payment/new/scan
/collaborators
/cash-register
/settings
/user                     (pestaña Usuario: Info)
```

Guards de go_router, en orden:
1. Sin sesión → `/auth/login`.
2. Correo sin verificar → `/auth/verify-email`.
3. Sin negocio → `/onboarding/role`.
4. Ruta solo para el dueño y el usuario es colaborador → `/home`.

---

## 5. Eventos de Analytics

`sign_up`, `email_verified`, `business_created`, `invite_generated`, `invite_redeemed`, `payment_registered{method,source}`, `payment_voided`, `cash_closed{difference_sign}`, `report_viewed{period}`, `export_generated{format}`, `product_created{has_barcode}`, `ocr_scan{success}`, `notification_payment_captured{app}`, `paywall_viewed`, `subscription_started`.

---

## 6. Flujo de trabajo en GitHub

- **Ramas:** `main` (protegida, siempre lista para release) y ramas `feat/F-21-pago-efectivo`, `fix/...`, `chore/...`.
- **Commits:** Conventional Commits con el ID: `feat(payments): F-21 formulario de pago en efectivo`.
- **PRs:** 1 PR por feature, plantilla con checklist, CI en verde y 1 aprobación. Squash merge.
- **Issues:** una por `F-xx`, con labels `area:*`, `type:*` y `priority:*`, asignada a su milestone.
- **Definition of Done:** criterios de aceptación cumplidos, tests, sin warnings de `analyze`, textos en es-PE, probado en modo oscuro y claro, funciona offline (si aplica) y reglas actualizadas.

## 7. Riesgos

| Riesgo | Mitigación |
|---|---|
| Yape o Plin cambian el texto de sus notificaciones | Parsers versionados con tests de fixtures. Patrones en Remote Config para corregir sin publicar una nueva versión |
| Google Play rechaza el permiso de NotificationListener | Declaración de uso clara, onboarding explícito y que la función sea opcional |
| Fabricantes que matan servicios en segundo plano | Foreground service y guía por fabricante |
| Logos de bancos y billeteras (marcas registradas) | Usarlos solo como identificadores de método de pago y revisar los lineamientos de marca de cada entidad |
| Datos financieros sensibles | Reglas estrictas, App Check, sin PII en logs, Ley N.º 29733 de Protección de Datos Personales |
