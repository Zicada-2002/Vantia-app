import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore, Timestamp, type WriteBatch } from "firebase-admin/firestore";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions";
import { onCall, onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { requireVerified } from "./auth.js";
import { fail } from "./errors.js";

const DELETED_NAME = "Usuario eliminado";

async function commitInChunks(
  docs: FirebaseFirestore.QueryDocumentSnapshot[],
  apply: (b: WriteBatch, d: FirebaseFirestore.QueryDocumentSnapshot) => void,
): Promise<void> {
  const db = getFirestore();
  for (let i = 0; i < docs.length; i += 400) {
    const batch = db.batch();
    docs.slice(i, i + 400).forEach((d) => apply(batch, d));
    await batch.commit();
  }
}

/**
 * F-82: elimina la cuenta (requisito de Google Play).
 * - Anonimiza el nombre en sus pagos (los montos se conservan para la caja
 *   y los reportes del negocio).
 * - Si es dueño, cierra el negocio: desvincula a todo el equipo.
 * - Borra perfil, dispositivos y el usuario de Auth.
 */
export const deleteAccount = onCall(async (req) => {
  const caller = requireVerified(req);
  const data = (req.data ?? {}) as { confirm?: unknown };
  if (data.confirm !== "ELIMINAR") {
    throw fail("invalid-argument", "invalid-data", "Confirmación requerida");
  }
  const db = getFirestore();
  const userRef = db.doc(`users/${caller.uid}`);
  const user = await userRef.get();
  const bid = user.get("activeBusinessId") as string | undefined;

  if (bid) {
    const payments = await db.collection(`businesses/${bid}/payments`).where("createdBy", "==", caller.uid).get();
    await commitInChunks(payments.docs, (b, d) => b.update(d.ref, { createdByName: DELETED_NAME }));

    if (user.get("role") === "owner") {
      const members = await db.collection(`businesses/${bid}/members`).get();
      await commitInChunks(members.docs, (b, d) => {
        b.update(d.ref, { active: false });
        if (d.id !== caller.uid) {
          b.set(db.doc(`users/${d.id}`), { activeBusinessId: null, role: null }, { merge: true });
        }
      });
      await db.doc(`businesses/${bid}`).update({ status: "deleted", deletedAt: FieldValue.serverTimestamp() });
    } else {
      await db.doc(`businesses/${bid}/members/${caller.uid}`).update({ active: false, displayName: DELETED_NAME });
    }
  }

  const devices = await db.collection(`users/${caller.uid}/devices`).get();
  await commitInChunks(devices.docs, (b, d) => b.delete(d.ref));
  await userRef.delete();
  await getAuth().deleteUser(caller.uid);
  logger.info("cuenta eliminada", { uid: caller.uid, owner: user.get("role") === "owner" });
  return { ok: true };
});

/** F-84: vence las pruebas gratuitas (diario, 00:05 hora de Lima). */
export const expireTrials = onSchedule({ schedule: "5 0 * * *", timeZone: "America/Lima" }, async () => {
  const db = getFirestore();
  const expired = await db
    .collection("businesses")
    .where("plan.tier", "==", "trial")
    .where("plan.trialEndsAt", "<", Timestamp.now())
    .get();
  await commitInChunks(expired.docs, (b, d) => b.update(d.ref, { "plan.tier": "free" }));
  logger.info("pruebas vencidas", { count: expired.size });
});

export const REVENUECAT_WEBHOOK_SECRET = defineSecret("REVENUECAT_WEBHOOK_SECRET");

/** Traduce un evento de RevenueCat al plan del negocio (puro). */
export function planFromRevenueCat(event: {
  type?: string;
  expiration_at_ms?: number | null;
}): { tier: "pro" | "free"; renewsAt: number | null } | null {
  switch (event.type) {
    case "INITIAL_PURCHASE":
    case "RENEWAL":
    case "PRODUCT_CHANGE":
    case "UNCANCELLATION":
    case "NON_RENEWING_PURCHASE":
      return { tier: "pro", renewsAt: event.expiration_at_ms ?? null };
    case "EXPIRATION":
      return { tier: "free", renewsAt: null };
    default:
      return null; // CANCELLATION mantiene Pro hasta EXPIRATION.
  }
}

/**
 * F-85: webhook de RevenueCat. `app_user_id` = id del negocio (la app
 * inicia sesión en RevenueCat con el businessId).
 */
export const revenuecatWebhook = onRequest({ secrets: [REVENUECAT_WEBHOOK_SECRET] }, async (req, res) => {
  if (req.method !== "POST" || req.get("authorization") !== `Bearer ${REVENUECAT_WEBHOOK_SECRET.value()}`) {
    res.status(401).send("unauthorized");
    return;
  }
  const event = (req.body?.event ?? {}) as { type?: string; app_user_id?: string; expiration_at_ms?: number };
  const plan = planFromRevenueCat(event);
  const bid = event.app_user_id;
  if (plan && bid && /^[A-Za-z0-9]{10,40}$/.test(bid)) {
    const ref = getFirestore().doc(`businesses/${bid}`);
    if ((await ref.get()).exists) {
      await ref.update({
        "plan.tier": plan.tier,
        "plan.renewsAt": plan.renewsAt ? Timestamp.fromMillis(plan.renewsAt) : null,
        "plan.updatedAt": FieldValue.serverTimestamp(),
      });
    }
  }
  res.status(200).send("ok");
});
