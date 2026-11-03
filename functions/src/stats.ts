import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import type { PaymentLike } from "./cash.js";

export interface DailyStats {
  dayKey: string;
  totalCents: number;
  count: number;
  cashCents: number;
  cashCount: number;
  digitalCount: number;
  byMethod: Record<string, { cents: number; count: number }>;
  byUser: Record<string, { cents: number; count: number }>;
}

/** Agrega los pagos activos de un día (F-50). Pura y testeable. */
export function aggregateDay(dayKey: string, payments: (PaymentLike & { createdBy: string })[]): DailyStats {
  const s: DailyStats = {
    dayKey, totalCents: 0, count: 0, cashCents: 0, cashCount: 0, digitalCount: 0, byMethod: {}, byUser: {},
  };
  for (const p of payments) {
    if (p.status !== "active") continue;
    s.totalCents += p.amountCents;
    s.count++;
    if (p.method === "cash") {
      s.cashCents += p.amountCents;
      s.cashCount++;
    } else {
      s.digitalCount++;
    }
    const m = (s.byMethod[p.method] ??= { cents: 0, count: 0 });
    m.cents += p.amountCents;
    m.count++;
    const u = (s.byUser[p.createdBy] ??= { cents: 0, count: 0 });
    u.cents += p.amountCents;
    u.count++;
  }
  return s;
}

/**
 * Recalcula `dailyStats/{dayKey}` desde los pagos del día. Recalcular (en vez
 * de sumar con increment) lo hace idempotente ante reintentos del trigger.
 */
export async function recomputeDay(bid: string, dayKey: string): Promise<DailyStats> {
  const db = getFirestore();
  const snap = await db.collection(`businesses/${bid}/payments`).where("dayKey", "==", dayKey).get();
  const stats = aggregateDay(dayKey, snap.docs.map((d) => d.data() as PaymentLike & { createdBy: string }));
  await db.doc(`businesses/${bid}/dailyStats/${dayKey}`).set({ ...stats, updatedAt: FieldValue.serverTimestamp() });
  return stats;
}

export const onPaymentWrite = onDocumentWritten("businesses/{bid}/payments/{pid}", async (event) => {
  const before = event.data?.before.data()?.dayKey as string | undefined;
  const after = event.data?.after.data()?.dayKey as string | undefined;
  const days = new Set([before, after].filter((d): d is string => Boolean(d)));
  await Promise.all([...days].map((d) => recomputeDay(event.params.bid, d)));
});
