import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { logger } from "firebase-functions";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onCall } from "firebase-functions/v2/https";
import { fail } from "./errors.js";
import { requireOwner } from "./owner.js";
import { parseInviteCode } from "./validation.js";

/** F-31: el dueño revoca un código vigente. */
export const revokeInvite = onCall(async (req) => {
  const owner = await requireOwner(req);
  const code = parseInviteCode(req.data);
  const db = getFirestore();
  const ref = db.doc(`businesses/${owner.businessId}/invites/${code}`);
  await db.runTransaction(async (tx) => {
    const invite = await tx.get(ref);
    if (!invite.exists) throw fail("not-found", "invite-invalid", "Código inexistente");
    if (invite.get("status") !== "active") {
      throw fail("failed-precondition", "invite-used", "El código ya no está vigente");
    }
    tx.update(ref, { status: "revoked", revokedAt: FieldValue.serverTimestamp() });
    tx.delete(db.doc(`inviteCodes/${code}`));
  });
  return { ok: true };
});

/**
 * F-32: activa/desactiva a un colaborador. Al desactivar, el usuario pierde
 * el acceso (las reglas exigen `active == true`) y su sesión vuelve al
 * onboarding; el historial de pagos se conserva.
 */
export const setMemberActive = onCall(async (req) => {
  const owner = await requireOwner(req);
  const data = (req.data ?? {}) as { uid?: unknown; active?: unknown };
  if (typeof data.uid !== "string" || typeof data.active !== "boolean") {
    throw fail("invalid-argument", "invalid-data", "uid y active son obligatorios");
  }
  if (data.uid === owner.uid) {
    throw fail("failed-precondition", "invalid-data", "El dueño no puede desactivarse");
  }
  const { uid, active } = data;
  const db = getFirestore();
  const memberRef = db.doc(`businesses/${owner.businessId}/members/${uid}`);
  const userRef = db.doc(`users/${uid}`);
  await db.runTransaction(async (tx) => {
    const [member, user] = await Promise.all([tx.get(memberRef), tx.get(userRef)]);
    if (!member.exists) throw fail("not-found", "invalid-data", "No es miembro del negocio");
    if (active) {
      const current = user.get("activeBusinessId") as string | undefined;
      if (current && current !== owner.businessId) {
        throw fail("failed-precondition", "already-member", "Pertenece a otro negocio");
      }
      tx.set(userRef, { activeBusinessId: owner.businessId, role: "collaborator" }, { merge: true });
    } else if (user.get("activeBusinessId") === owner.businessId) {
      tx.set(userRef, { activeBusinessId: null, role: null }, { merge: true });
    }
    tx.update(memberRef, { active, updatedAt: FieldValue.serverTimestamp() });
  });
  return { ok: true };
});

/** Texto del push: "Ana registró S/ 25.00 por Yape". */
export function paymentPushText(name: string, cents: number, method: string): string {
  const label: Record<string, string> = {
    yape: "Yape", plin: "Plin", bcp: "BCP", interbank: "Interbank",
    bbva: "BBVA", scotiabank: "Scotiabank", cash: "efectivo",
  };
  const amount = (cents / 100).toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  return `${name || "Un colaborador"} registró S/ ${amount} por ${label[method] ?? method}`;
}

/** F-33: avisa al dueño cuando un colaborador registra un cobro. */
export const notifyOwnerOnPayment = onDocumentCreated(
  "businesses/{bid}/payments/{pid}",
  async (event) => {
    const payment = event.data?.data();
    if (!payment) return;
    const db = getFirestore();
    const biz = await db.doc(`businesses/${event.params.bid}`).get();
    const ownerUid = biz.get("ownerUid") as string | undefined;
    if (!ownerUid || ownerUid === payment.createdBy) return;

    const owner = await db.doc(`users/${ownerUid}`).get();
    if (owner.get("prefs.notifyCollaboratorPayments") === false) return;

    const devices = await db.collection(`users/${ownerUid}/devices`).get();
    const tokens = devices.docs.map((d) => d.get("token") as string).filter(Boolean);
    if (tokens.length === 0) return;

    const res = await getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title: biz.get("name") as string,
        body: paymentPushText(payment.createdByName as string, payment.amountCents as number, payment.method as string),
      },
      data: { type: "payment", paymentId: event.params.pid },
      android: { priority: "high" },
    });
    // Limpiar tokens inválidos.
    await Promise.all(
      res.responses.map((r, i) =>
        !r.success && r.error?.code === "messaging/registration-token-not-registered"
          ? devices.docs[i].ref.delete()
          : Promise.resolve(),
      ),
    );
    logger.info("push enviado", { ok: res.successCount, fail: res.failureCount });
  },
);
