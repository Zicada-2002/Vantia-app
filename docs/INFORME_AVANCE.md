# Vantia — Informe de avance

**Última actualización:** 3 de noviembre de 2026
**Rama de trabajo:** `ccr-e89000a1-3kvjkg` → PR [#66](https://github.com/Zicada-2002/Vantia-app/pull/66) hacia `main`

---

## 1. Resumen

| Indicador | Estado |
|---|---|
| Plan de features y arquitectura | ✅ Completo |
| Organización en GitHub | ✅ 65 issues (#1–#65), rama `main` creada, PR #66 abierto |
| **M0 — Fundaciones** | 🟡 ~90 %: falta conectar Analytics/Crashlytics, que requiere el proyecto real |
| **M1 — Autenticación y onboarding** | ✅ 8 de 9 features. F-14 (Google, opcional) pendiente |
| Backend (reglas + Cloud Functions) | ✅ Base lista: 3 funciones y reglas de seguridad testeadas |
| M2 a M9 | ⬜ Pendientes |
| Tests | **App:** 50 · **Functions:** 4 unitarios + 12 de integración contra emuladores. Todos en verde |
| Análisis estático | `flutter analyze` y `tsc`: 0 avisos |
| Avance estimado del proyecto | **≈ 18 %** (≈ 10 de 55 días-dev) |

> **Ya se puede usar de punta a punta en local:** crear cuenta → verificar el correo → elegir rol → crear negocio o unirse con código → entrar a la app → cerrar sesión. Funciona contra los emuladores de Firebase sin necesitar un proyecto real. Todavía no se registran pagos (eso es M2).

---

## 2. Avances realizados

### 2.1 Planificación, documentación y GitHub

- `docs/PLAN.md` (alcance, roles, 55 features), `docs/ARQUITECTURA.md` (stack, datos, seguridad, desarrollo local), README, CONTRIBUTING, `.gitignore`, plantillas y CI.
- **Issues:** 10 épicos con 55 features como sub-issues.

| Épico | Issue | Features |
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

- **Rama `main`** creada desde el commit del plan (`7c583e0`). El **PR #66** lleva M0 y M1.
- **CI:** formato, análisis y tests de la app; build y tests de Functions; tests de integración con emuladores (Java 21); APK `dev` en `main`.

### 2.2 M0 — Fundaciones

| ID | Feature | Estado |
|---|---|:-:|
| F-01 | Proyecto Flutter + flavors `dev`/`prod` (`pe.vantia.app`) | ✅ |
| F-02 | Arquitectura por funcionalidad, Riverpod 3, go_router con guards, `Result`/`Failure` | ✅ |
| F-03 | Design system (tema claro/oscuro/sistema, Poppins, componentes) | ✅ |
| F-04 | es-PE, `Money` en céntimos, `LimaTime` | ✅ |
| F-05 | CI/CD | ✅ (falta proteger `main`, ver §4) |
| F-06 | Observabilidad | 🟡 Interfaz y eventos listos. Falta Firebase Analytics/Crashlytics |

### 2.3 M1 — Autenticación y onboarding

| ID | Feature | Estado | Detalle |
|---|---|:-:|---|
| F-10 | Registro con correo | ✅ | Nombre, correo, contraseña (mín. 8 caracteres y 1 número), confirmación y términos obligatorios. Envía el correo de verificación en español |
| F-11 | **Verificación de correo** | ✅ | Pantalla "Revisa tu correo" con el correo enmascarado. Reenvío con cooldown de 60 s. "Ya verifiqué" y revisión automática al volver a la app. **Bloqueada en tres niveles:** router, reglas de Firestore y Cloud Functions |
| F-12 | Login | ✅ | Errores de Firebase traducidos al español, mostrar/ocultar contraseña, sesión persistente |
| F-13 | Recuperar contraseña | ✅ | Mensaje genérico que no revela si la cuenta existe |
| F-14 | Login con Google | ⬜ | Opcional; requiere el proyecto real (SHA-1) |
| F-15 | Selección de rol | ✅ | Tarjetas Dueño/Colaborador. "Continuar" deshabilitado hasta elegir |
| F-16 | Crear negocio | ✅ | Nombre, celular (+51, 9 dígitos), departamento (los 25) y provincia. Function `createBusiness` con **7 días de prueba** |
| F-17 | Unirse con código | ✅ | Código de 6 caracteres sin ambiguos. Function `redeemInvite` transaccional: vigente, un solo uso, no vencido |
| F-18 | Menú lateral y cerrar sesión | ✅ | Datos reales del negocio (iniciales, teléfono, ubicación). "Colaboradores" solo para el dueño. Confirmación al salir |

### 2.4 Backend

| Componente | Contenido |
|---|---|
| `functions/` | `createBusiness`, `generateInvite` (adelanto de F-30) y `redeemInvite`. Exigen el correo verificado y devuelven códigos de error estables que la app traduce |
| `firebase/firestore.rules` | Se deniega todo por defecto. Los datos del negocio exigen el correo verificado y ser miembro activo. Solo el dueño lee invitaciones y edita el negocio. El usuario no puede asignarse rol ni negocio |
| `firebase/firebase.json` | Emuladores Auth, Firestore, Functions y Storage, con la UI en `:4000` |
| Tests de integración (12) | Usuario no verificado rechazado, datos inválidos, prueba de 7 días, un negocio por usuario, invitaciones solo del dueño, código de un solo uso, vencido o inexistente, y 4 grupos de pruebas de reglas |

### 2.5 Correcciones encontradas durante el desarrollo

- La fila "¿No tienes cuenta? Crear cuenta" se desbordaba en pantallas angostas o con letra grande. Se cambió por un `Wrap`.
- El aviso "Tu correo aún no está verificado" seguía visible después de verificar y tapaba el botón de la siguiente pantalla. Ahora se oculta.

---

## 3. Pendiente por realizar

### 3.1 Para cerrar M0/M1

- [ ] **F-06:** Firebase Analytics y Crashlytics (requieren `google-services.json` del proyecto real).
- [ ] **F-14:** login con Google (opcional).
- [ ] Proteger la rama `main`. Se configura en GitHub; no se puede hacer desde esta sesión.
- [ ] Probar en un dispositivo real. Este entorno no tiene SDK de Android, así que el APK se compila en el CI.

### 3.2 Siguientes etapas

| Etapa | Contenido | Estimación | Estado |
|---|---|:-:|:-:|
| **M2** Pagos | Registro en efectivo y digital, Inicio con el resumen del día, lista semanal, anulación, offline | 8 d | ⬜ **Siguiente** |
| M3 Colaboradores | UI de invitaciones (el backend ya existe), gestión, push | 3 d | ⬜ |
| M4 Cuadre de caja | Mi caja, caja física, diferencia, cerrar/reabrir | 5 d | ⬜ |
| M5 Reportes | Agregados, Semana/Mes/Año, KPIs, exportar | 5 d | ⬜ |
| M6 Productos | Código de barras, sin código, venta con productos | 5 d | ⬜ |
| M7 Automatización | OCR, Yape/Plin (Android), voz | 8 d | ⬜ |
| M8 Usuario y suscripción | **Usuario → Info**, perfil, eliminar cuenta, ajustes, plan | 5 d | ⬜ |
| M9 Calidad y lanzamiento | E2E, accesibilidad, Google Play | 5 d | ⬜ |

**Restante:** ≈ 45 días-dev para 1 desarrollador.

---

## 4. Acciones requeridas del dueño del proyecto

| # | Acción | Bloquea |
|:-:|---|---|
| 1 | Revisar y hacer merge del **PR #66** | Base estable en `main` |
| 2 | Proteger `main` en *Settings → Branches*: PR obligatorio, CI en verde, 1 aprobación | Calidad |
| 3 | Probar en tu PC con los emuladores (ver README, "Puesta en marcha") y reportar lo que veas | Validación |
| 4 | Crear los proyectos de Firebase `vantia-dev` y `vantia-prod` (plan Blaze), con Authentication por correo, y llenar `app/env/dev.json` | F-06, F-14, pruebas con correos reales |
| 5 | Confirmar la regla del efectivo: **venta = monto recibido − cambio** | M2, M4 |
| 6 | Crear las etiquetas `area:*` y `priority:*` en GitHub (opcional) | Organización |

---

## 5. Recomendaciones para continuar

1. **Hacer merge del PR #66** y trabajar M2 en ramas `feat/F-xx`, un PR por feature.
2. **M2 es la base del resto.** Caja, reportes, productos y automatización dependen del modelo `payments` y de su agregación diaria. Conviene definir y testear bien las reglas de `payments` desde el inicio.
3. **Hacer F-80 (Usuario → Info) al cerrar M2.** Solo depende de la sesión y del negocio, que ya existen.
4. **Prototipar pronto la lectura de Yape/Plin en un celular real.** Es el mayor riesgo técnico: permisos de Android, ahorro de batería de cada fabricante y revisión de Google Play.
5. **Juntar ejemplos reales anonimizados** de notificaciones y capturas de Yape, Plin y los bancos, para el OCR y sus tests.
6. **Mantener las convenciones:** dinero como `Money`, fechas con `LimaTime`, textos en `app_es.arb`, permisos validados en reglas y Functions, y no solo en la UI.

---

## 6. Cómo probar lo construido

```bash
# Backend local (terminal 1)
cd functions && npm ci && npm run serve          # UI de emuladores: http://localhost:4000

# App (terminal 2), con un emulador de Android abierto
cd app && flutter pub get
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=env/emulator.json
```

**Flujo para probar:**
1. Crear una cuenta.
2. Copiar el enlace de verificación que aparece en la terminal 1 y abrirlo en el navegador.
3. Tocar "Ya verifiqué mi correo".
4. Elegir Dueño y crear el negocio.
5. Entrar a la app.

Para probar el rol de colaborador, genera un código desde la UI de emuladores o con `generateInvite`. La pantalla para el dueño llega en M3.

**Tests:**
```bash
cd app && flutter analyze && flutter test        # 50 tests
cd functions && npm test                          # 4 unit tests
cd functions && npm run test:emulator             # 12 tests de integración + reglas
```
