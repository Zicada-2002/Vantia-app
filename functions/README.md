# functions/ — Cloud Functions (TypeScript)

Node 22, región `southamerica-east1`. Funciones callable:

| Función | Feature | Qué hace |
|---|---|---|
| `createBusiness` | F-16 | Crea el negocio y el miembro dueño, e inicia la prueba de 7 días (`plan.tier = trial`) |
| `generateInvite` | F-30 | Solo el dueño. Genera un código de 6 caracteres, de un solo uso, que vence en 48 h |
| `redeemInvite` | F-17 | En una transacción valida el código (vigente, no usado, no revocado) y crea el miembro colaborador |

Las tres exigen el **correo verificado** (`email_verified`). Los errores devuelven `details.reason` con un código estable que la app traduce: `invite-invalid`, `invite-expired`, `invite-used`, `already-member`, `email-not-verified`, `not-owner` o `invalid-data`.

## Comandos

```bash
npm ci
npm test               # unit tests (validación, generación de códigos)
npm run test:emulator  # integración: Auth + Firestore + Functions + reglas (requiere Java 21)
npm run serve          # levanta los emuladores para usar con la app (UI en http://localhost:4000)
```
