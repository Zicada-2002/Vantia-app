import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/v2/https";
import { requireVerified } from "./auth.js";
import { fail } from "./errors.js";
import { requireOwner } from "./owner.js";

export interface PaymentLike {
  method: string;
  amountCents: number;
  receivedCents?: number;
  changeCents?: number;
  status: string;
}

export interface CashTotals {
  totalCents: number;
  count: number;
  totalsByMethod: Record<string, number>;
  cashReceivedCents: number;
  changeGivenCents: number;
  expectedCents: number;
  differenceCents: number;
}

/** Cálculo del cuadre (F-42): esperado = fondo + recibido − cambios. */
export function computeCashTotals(
  payments: PaymentLike[],
  openingCents: number,
  countedCents: number,
): CashTotals {
  let totalCents = 0;
  let count = 0;
  let received = 0;
  let change = 0;
  const byMethod: Record<string, number> = {};
  for (const p of payments) {
    if (p.status !== "active") continue;
    count++;
    totalCents += p.amountCents;
    byMethod[p.method] = (byMethod[p.method] ?? 0) + p.amountCents;
    if (p.method === "cash") {
      received += p.receivedCents ?? p.amountCents;
      change += p.changeCents ?? 0;
    }
  }
  const expectedCents = openingCents + received - change;
  return {
    totalCents,
    count,
    totalsByMethod: byMethod,
    cashReceivedCents: received,
    changeGivenCents: change,
    expectedCents,
    differenceCents: countedCents - expectedCents,
  };
}

const DAY_KEY = /^\d{4}-\d{2}-\d{2}$/;

function parseCents(v: unknown, field: string): number {
  if (typeof v !== "number" || !Number.isInteger(v) || v < 0 || v > 1_000_000_000) {
    throw fail("invalid-argument", "invalid-data", `${field} inválido`);
  }
  return v;
}

function parseDayKey(v: unknown): string {
  if (typeof v !== "string" || !DAY_KEY.test(v)) {
    throw fail("invalid-argument", "invalid-data", "dayKey inválido");
  }
  return v;
}

/** F-43: cierra la caja del día del usuario con un snapshot inmutable. */
export const closeCashSession = onCall(async (req) => {
  const caller = requireVerified(req);
  const data = (req.data ?? {}) as Record<string, unknown>;
  const dayKey = parseDayKey(data.dayKey);
  const openingCents = parseCents(data.openingCents, "openingCents");
  const countedCents = parseCents(data.countedCents, "countedCents");

  const db = getFirestore();
  const user = await db.doc(`users/${caller.uid}`).get();
  const bid = user.get("activeBusinessId") as string | undefined;
  if (!bid) throw fail("permission-denied", "not-owner", "Sin negocio activo");
  const member = await db.doc(`businesses/${bid}/members/${caller.uid}`).get();
  if (member.get("active") !== true) throw fail("permission-denied", "not-owner", "Miembro inactivo");

  const ref = db.doc(`businesses/${bid}/cashSessions/${dayKey}_${caller.uid}`);
  const totals = await db.runTransaction(async (tx) => {
    const session = await tx.get(ref);
    if (session.get("status") === "closed") {
      throw fail("failed-precondition", "invalid-data", "La caja ya está cerrada");
    }
    const payments = await tx.get(
      db.collection(`businesses/${bid}/payments`)
        .where("dayKey", "==", dayKey)
        .where("createdBy", "==", caller.uid),
    );
    const t = computeCashTotals(
      payments.docs.map((d) => d.data() as PaymentLike),
      openingCents,
      countedCents,
    );
    tx.set(ref, {
      dayKey,
      uid: caller.uid,
      displayName: (user.get("displayName") as string) ?? caller.name,
      openingCents,
      countedCents,
      ...t,
      status: "closed",
      closedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    return t;
  });
  return totals;
});

/** F-45: el dueño reabre una caja cerrada, con motivo. */
export const reopenCashSession = onCall(async (req) => {
  const owner = await requireOwner(req);
  const data = (req.data ?? {}) as Record<string, unknown>;
  const dayKey = parseDayKey(data.dayKey);
  const uid = typeof data.uid === "string" ? data.uid : "";
  const reason = typeof data.reason === "string" ? data.reason.trim() : "";
  if (!uid || reason.length < 3 || reason.length > 200) {
    throw fail("invalid-argument", "invalid-data", "uid y motivo son obligatorios");
  }
  const db = getFirestore();
  const ref = db.doc(`businesses/${owner.businessId}/cashSessions/${dayKey}_${uid}`);
  await db.runTransaction(async (tx) => {
    const s = await tx.get(ref);
    if (s.get("status") !== "closed") {
      throw fail("failed-precondition", "invalid-data", "La caja no está cerrada");
    }
    tx.update(ref, {
      status: "reopened",
      reopenedBy: owner.uid,
      reopenReason: reason,
      reopenedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.create(db.collection(`businesses/${owner.businessId}/audit`).doc(), {
      type: "cash_reopened",
      dayKey,
      uid,
      by: owner.uid,
      reason,
      at: FieldValue.serverTimestamp(),
    });
  });
  return { ok: true };
});
