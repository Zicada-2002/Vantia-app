import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { onDocumentCreated } from "firebase-functions/v2/firestore";

interface Item {
  productId?: unknown;
  qty?: unknown;
}

/** Cantidades a descontar por producto (agrupa repetidos, ignora inválidos). */
export function stockDeltas(items: unknown): Map<string, number> {
  const out = new Map<string, number>();
  if (!Array.isArray(items)) return out;
  for (const raw of items as Item[]) {
    if (typeof raw?.productId !== "string" || !raw.productId) continue;
    const qty = typeof raw.qty === "number" && Number.isInteger(raw.qty) && raw.qty > 0 ? raw.qty : 0;
    if (qty === 0) continue;
    out.set(raw.productId, (out.get(raw.productId) ?? 0) + qty);
  }
  return out;
}

/**
 * F-63: descuenta stock al registrar una venta con productos. Se hace en el
 * servidor (no en el cliente) para que funcione aunque el pago se haya
 * registrado offline. Solo afecta productos que llevan control de stock.
 */
export const decrementStockOnSale = onDocumentCreated("businesses/{bid}/payments/{pid}", async (event) => {
  const deltas = stockDeltas(event.data?.data()?.items);
  if (deltas.size === 0) return;
  const db = getFirestore();
  await db.runTransaction(async (tx) => {
    const refs = [...deltas.keys()].map((id) => db.doc(`businesses/${event.params.bid}/products/${id}`));
    const docs = await Promise.all(refs.map((r) => tx.get(r)));
    docs.forEach((d, i) => {
      if (!d.exists || typeof d.get("stock") !== "number") return;
      tx.update(refs[i], {
        stock: FieldValue.increment(-deltas.get(refs[i].id)!),
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
  });
  logger.info("stock actualizado", { payment: event.params.pid, products: deltas.size });
});
