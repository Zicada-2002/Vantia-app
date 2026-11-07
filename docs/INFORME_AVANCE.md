# Vantia — Informe de avance

**Última actualización:** 3 de noviembre de 2026
**Rama:** `ccr-e89000a1-3kvjkg` → PR [#66](https://github.com/Zicada-2002/Vantia-app/pull/66) hacia `main`

---

## 1. Resumen

| Indicador | Estado |
|---|---|
| Plan de features (M0–M9, 55 features) | ✅ **Implementado en código**, salvo F-14 (opcional) |
| Tests de la app (Flutter) | **107** en verde (unitarios, widget, accesibilidad), más 1 de integración para dispositivo |
| Tests de Functions | **10** unitarios + **27** de integración con emuladores (Functions, triggers y reglas de seguridad) |
| Cobertura | 77 % total; módulos críticos ≥ 90 % (parsers 91 %, caja, reportes, fechas, validadores y guards al 100 %), con control automático en CI |
| CI (GitHub Actions) | Formato, análisis, tests, cobertura, Functions, emuladores y **build del APK** en cada PR |
| Análisis estático | `flutter analyze` y `tsc`: 0 avisos |
| Listo para producción | 🟡 Falta lo que depende de cuentas reales y validación en dispositivos (§4) |

> El código cubre todo el plan y se puede probar de punta a punta en local con los emuladores de Firebase. Lo que falta para publicar no es programación: configurar los proyectos reales (Firebase, Play Console, RevenueCat), probar en celulares físicos, conseguir fixtures reales de Yape/Plin y hacer la revisión legal.

---

## 2. Qué se construyó

### M0 — Fundaciones ✅
- Flavors `dev`/`prod`, arquitectura por funcionalidad, Riverpod 3 y go_router con guards (sesión → correo verificado → negocio → rol).
- Design system claro/oscuro, `Money` en céntimos y `LimaTime`.
- CI completo.
- Analytics y Crashlytics (se activan con un proyecto real) y App Check.

### M1 — Autenticación y onboarding ✅
- Registro, **verificación de correo** (bloqueada en router, reglas y Functions), login, recuperar contraseña.
- Selección de rol, crear negocio (7 días de prueba), unirse con código y menú lateral.
- F-14 (Google) pendiente: es opcional y requiere el proyecto real.

### M2 — Pagos ✅
- Selector de medio. Efectivo con cambio (**venta = recibido − cambio**, regla confirmada por el dueño). Digital con nº de operación y aviso de duplicado.
- Inicio con el resumen del día y los últimos pagos, lista semanal, detalle y anulación con motivo.
- Offline-first.
- Reglas que validan el esquema y los montos.

### M3 — Colaboradores ✅
- Códigos de invitación (un solo uso, vencen en 48 h), revocar, equipo con ventas del día, desactivar o reactivar.
- Push al dueño cuando el equipo cobra.

### M4 — Cuadre de caja ✅
- Mi caja y caja física (fondo + efectivo − cambios = esperado; diferencia).
- Cierre recalculado en el servidor, con los pagos del día bloqueados.
- Resumen general y reapertura con auditoría.

### M5 — Reportes ✅
- `dailyStats` mantenido por un trigger.
- Semana/Mes/Año con gráfico y variación, KPIs y métodos de pago.
- **Exportación a Excel o PDF**.

### M6 — Productos ✅
- Catálogo con búsqueda y escáner de código de barras.
- Venta con productos (carrito y control de stock); el stock se descuenta en el servidor.

### M7 — Automatización ✅ (requiere validación en dispositivo)
- **OCR** de comprobantes con ML Kit, imagen guardada en Storage.
- **Lectura de notificaciones de Yape y Plin** (Kotlin `NotificationListenerService`): cola persistente y pagos con id determinista, sin duplicados.
- **Anuncio por voz** nativo, que funciona con la app cerrada.
- Pantalla guiada de permisos y batería.

### M8 — Usuario, ajustes y suscripción ✅
- **Usuario → Info**: datos personales, negocio, cuenta, soporte y versión.
- Editar perfil, cambiar contraseña y correo, **eliminar cuenta** (Function).
- Ajustes como la referencia.
- Plan Free / Prueba / Pro con bloqueo de funciones, paywall con RevenueCat y webhook.

### M9 — Calidad y lanzamiento ✅ (código) · 🧑 (cuentas)
- Accesibilidad verificada con las guías de Flutter (tamaño táctil, etiquetas, contraste en ambos temas) y letra al 130 % sin desbordes.
- Test de integración de punta a punta para dispositivo y control de cobertura.
- Firma de release por `key.properties` e ícono adaptativo provisional.
- Guía de publicación: [`docs/RELEASE.md`](RELEASE.md).

---

## 3. Decisiones técnicas que conviene conocer

| Tema | Decisión | Motivo |
|---|---|---|
| Pertenencia y rol | Las reglas leen `members/{uid}`, no custom claims | Evita tokens desactualizados al cambiar de rol |
| Cálculos críticos | Cierre de caja, agregados diarios y stock en Functions | El cliente no es confiable y puede estar offline |
| Duplicados de Yape/Plin | Id del pago = hash de la notificación; las reglas impiden reescribirlo | Idempotente aunque llegue dos veces |
| Servicio en primer plano (F-73) | No se usa: el `NotificationListenerService` lo mantiene el sistema; hay guía de batería por fabricante | Menos fricción y sin permisos restringidos de Play |
| Exportación | En el dispositivo, hasta 1 año | Suficiente para el volumen de un negocio pequeño; evita costos de Functions |
| Fecha y hora | Todo agrupado en America/Lima (UTC−5 fijo) | Perú no tiene horario de verano |

---

## 4. Pendiente para publicar 🧑

| # | Acción | Responsable |
|:-:|---|---|
| 1 | Revisar y hacer merge del **PR #66**; proteger `main` | Dueño del repo |
| 2 | Crear Firebase `vantia-dev`/`vantia-prod`, llenar `env/*.json` y desplegar reglas, índices y Functions (ver RELEASE §1) | Dueño |
| 3 | Probar en celulares reales, sobre todo la verificación automática en Xiaomi, Samsung, Huawei y Oppo | Dueño / QA |
| 4 | Juntar **notificaciones y comprobantes reales anonimizados** y agregarlos como fixtures | Dueño → dev |
| 5 | Revisión legal de términos y privacidad; publicar la política y el enlace web para eliminar cuenta | Dueño / abogado |
| 6 | Play Console (pruebas internas y cerradas), RevenueCat (productos y webhook), ícono y capturas finales | Dueño |

---

## 5. Cómo probar

```bash
# Backend local (terminal 1)
cd functions && npm ci && npm run serve        # UI de emuladores: http://localhost:4000

# App (terminal 2), con un emulador Android abierto
cd app && flutter pub get
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=env/emulator.json

# Tests
cd app && flutter analyze && flutter test --coverage && dart run tool/coverage_gate.dart
cd app && flutter test integration_test --flavor dev     # requiere dispositivo o emulador
cd functions && npm test && npm run test:emulator
```

En el emulador no se envían correos: el enlace de verificación aparece en la terminal de los emuladores.
