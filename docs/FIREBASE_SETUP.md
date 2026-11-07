# Configurar Firebase paso a paso

Guía para crear el proyecto **dev** (pruebas). Para **prod** repite lo mismo con otro proyecto y la app `pe.vantia.app` (ver §9).
Tiempo estimado: 45–60 minutos. Necesitas una cuenta de Google y una tarjeta para el plan Blaze.

> **Antes de empezar:** ten el repositorio clonado en tu PC y ejecuta `cd functions && npm ci` una vez. Eso instala la herramienta `firebase` del proyecto, que se usa con `npx firebase`.

---

## 1. Crear el proyecto

1. Entra a <https://console.firebase.google.com> → **Crear un proyecto**.
2. Nombre: `vantia-dev`. Firebase te propone un **ID de proyecto**. Si `vantia-dev` ya existe, te dará algo como `vantia-dev-a1b2`. **Anota ese ID**; el script del paso 6 lo configura solo.
3. **Google Analytics:** actívalo y usa la cuenta por defecto. Sirve para la analítica de la app.
4. Espera a que termine y entra al proyecto.

## 2. Activar el plan Blaze (pago por uso)

Las Cloud Functions, la tarea programada diaria y Storage lo requieren.

1. Abajo a la izquierda, en **Spark**, entra a **Actualizar** → **Blaze** y asocia una cuenta de facturación (tarjeta).
2. **Muy recomendado:** crea una **alerta de presupuesto**, por ejemplo de USD 5. Así te avisan si algo se dispara.
   En el uso de pruebas lo normal es pagar **USD 0**, porque todo entra en la capa gratuita.

## 3. Authentication (correo + verificación)

1. Menú **Compilación → Authentication → Comenzar**.
2. En **Método de acceso**, entra a **Correo electrónico/contraseña** → **Habilitar** → Guardar. No actives "vínculo de correo electrónico".
3. En **Plantillas**, cambia el **idioma** de las plantillas a **Español** (ícono de lápiz → idioma).
   Opcional: personaliza el remitente y el asunto de "Verificación de dirección de correo electrónico".

## 4. Firestore (base de datos)

1. **Compilación → Firestore Database → Crear base de datos**.
2. Edición **Standard**.
3. Ubicación: **`southamerica-east1` (São Paulo)**. ⚠️ **No se puede cambiar después.**
4. Modo: **producción**. Las reglas reales se despliegan en el paso 7.

## 5. Storage (comprobantes escaneados)

1. **Compilación → Storage → Comenzar**.
2. Ubicación: **la misma, `southamerica-east1`**.
3. Modo: **producción**.

## 6. Registrar la app Android y generar `env/dev.json`

1. En **Configuración del proyecto** (engranaje) → **General**, ve a **Tus apps** → ícono de **Android**.
2. **Nombre del paquete:** `pe.vantia.app.dev`. Tiene que ser exacto.
3. **Sobrenombre:** `Vantia Dev`.
4. **Certificado SHA-1:** opcional ahora; necesario para el login con Google y App Check. Para obtenerlo en tu PC:
   ```bash
   keytool -list -v -alias androiddebugkey -storepass android -keypass android \
     -keystore ~/.android/debug.keystore | grep SHA1
   ```
   En Windows, la ruta es `%USERPROFILE%\.android\debug.keystore`. Si el archivo no existe, ejecuta la app una vez con `flutter run` y se crea.
5. **Descarga `google-services.json`.** Guárdalo **fuera del repositorio**, por ejemplo en `~/Descargas`. Los siguientes pasos del asistente (agregar el SDK) **sáltalos**: la app ya está configurada.
6. Genera la configuración de la app:
   ```bash
   cd app
   dart run tool/firebase_env.dart ~/Descargas/google-services.json dev
   ```
   Esto crea `app/env/dev.json` (no se sube a git) y apunta el alias `dev` de `firebase/.firebaserc` a tu ID real.

## 7. Desplegar reglas, índices y Functions

```bash
cd functions
npx firebase login                       # abre el navegador; entra con tu cuenta de Google
cd ../firebase

# Reglas de seguridad e índices
npx --prefix ../functions firebase deploy --project dev --only firestore:rules,firestore:indexes,storage

# Secreto del webhook de suscripciones. Escribe cualquier texto largo por ahora;
# luego lo usarás en RevenueCat.
npx --prefix ../functions firebase functions:secrets:set REVENUECAT_WEBHOOK_SECRET --project dev

# Cloud Functions (la primera vez tarda 5–10 minutos)
npx --prefix ../functions firebase deploy --project dev --only functions
```

- Si pregunta por **habilitar APIs** (Cloud Build, Artifact Registry, Secret Manager, Cloud Scheduler), responde **sí**.
- Si pide **política de limpieza de imágenes** de Functions, acepta la propuesta (por ejemplo, 1 día).
- Al terminar debe listar las 13 funciones en `southamerica-east1`.

## 8. Probar la app contra Firebase real

```bash
cd app
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=env/dev.json
```

Comprueba que todo funcione:

- [ ] Crear cuenta → **llega el correo de verificación** (revisa spam) → abrir el enlace → "Ya verifiqué mi correo".
- [ ] Crear negocio → en la consola, **Firestore → `businesses`** aparece tu negocio con `plan.tier = trial`.
- [ ] Registrar un cobro → aparece en `businesses/{id}/payments`. Unos segundos después se crea `dailyStats` (lo hace la Function).
- [ ] Cerrar caja → el documento de `cashSessions` queda con `status: closed`.
- [ ] En Ajustes → Mi cuenta → Eliminar cuenta (con una cuenta de prueba) → el usuario desaparece de **Authentication**.

Si algo falla, el registro está en **Consola → Functions → Registros** o en `npx firebase functions:log --project dev`.

## 9. Proyecto de producción

Repite los pasos 1 a 7 con:

- Proyecto `vantia-prod`.
- App Android **`pe.vantia.app`**, con el SHA-1 de tu **clave de subida** y, más adelante, el de **Play App Signing**.
- Para generar la configuración: `dart run tool/firebase_env.dart <google-services.json> prod`, que crea `env/prod.json`.
- Despliegue con `--project prod`.

Después sigue con `docs/RELEASE.md` (App Check, firma, Play Console).

---

## Problemas comunes

| Síntoma | Causa y solución |
|---|---|
| `El archivo no tiene la app Android "pe.vantia.app.dev"` | Registraste otro nombre de paquete. Agrega la app con el nombre exacto y vuelve a descargar `google-services.json` |
| No llega el correo de verificación | Revisa spam. En Authentication → Usuarios, confirma que la cuenta existe. Los dominios corporativos a veces bloquean `noreply@…firebaseapp.com` |
| `PERMISSION_DENIED` en la app | Faltó desplegar las reglas (paso 7) o el correo aún no está verificado |
| Error al desplegar Functions por facturación | El proyecto no está en Blaze (paso 2) |
| `Error: Failed to get Firebase project` | El alias de `.firebaserc` no coincide con tu ID. Vuelve a ejecutar el script del paso 6 |
| La app sigue usando emuladores | Falta `--dart-define-from-file=env/dev.json` o el archivo tiene `"USE_FIREBASE_EMULATOR": true` |
