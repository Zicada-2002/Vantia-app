/** F-50: el trigger mantiene dailyStats. Requiere el emulador de Functions con triggers. */
import assert from "node:assert/strict";
import { after, before, test } from "node:test";
import { deleteApp, initializeApp, type App } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:8080";
let admin: App;
const BID = `biz-stats-${Date.now()}`;
const DAY = "2026-11-02";

before(() => {
  admin = initializeApp({ projectId: "demo-vantia" }, "stats-admin");
});
after(() => deleteApp(admin));

async function waitFor<T>(read: () => Promise<T>, ok: (v: T) => boolean, ms = 15000): Promise<T> {
  const end = Date.now() + ms;
  let v = await read();
  while (!ok(v) && Date.now() < end) {
    await new Promise((r) => setTimeout(r, 300));
    v = await read();
  }
  return v;
}

test("crear y anular pagos actualiza dailyStats", { skip: process.env.VANTIA_SKIP_TRIGGERS === "1" }, async () => {
  const db = getFirestore(admin);
  const base = { dayKey: DAY, createdBy: "u1", status: "active", occurredAt: Timestamp.now() };
  await db.doc(`businesses/${BID}/payments/a`).set({ ...base, method: "yape", amountCents: 1000 });
  await db.doc(`businesses/${BID}/payments/b`).set({ ...base, method: "cash", amountCents: 2500 });
  const statsRef = db.doc(`businesses/${BID}/dailyStats/${DAY}`);
  let stats = await waitFor(() => statsRef.get(), (s) => s.get("totalCents") === 3500);
  assert.equal(stats.get("count"), 2);

  await db.doc(`businesses/${BID}/payments/b`).update({ status: "voided" });
  stats = await waitFor(() => statsRef.get(), (s) => s.get("totalCents") === 1000);
  assert.equal(stats.get("cashCount"), 0);
});

test("una venta con productos descuenta stock", { skip: process.env.VANTIA_SKIP_TRIGGERS === "1" }, async () => {
  const db = getFirestore(admin);
  await db.doc(`businesses/${BID}/products/p1`).set({ name: "Gaseosa", priceCents: 250, stock: 10, active: true });
  await db.doc(`businesses/${BID}/products/p2`).set({ name: "Pan", priceCents: 50, active: true }); // sin stock
  await db.doc(`businesses/${BID}/payments/sale`).set({
    dayKey: DAY, createdBy: "u1", status: "active", occurredAt: Timestamp.now(),
    method: "cash", amountCents: 800,
    items: [{ productId: "p1", qty: 3, name: "Gaseosa", unitPriceCents: 250 }, { productId: "p2", qty: 1, name: "Pan", unitPriceCents: 50 }],
  });
  const p1 = await waitFor(() => db.doc(`businesses/${BID}/products/p1`).get(), (s) => s.get("stock") === 7);
  assert.equal(p1.get("stock"), 7);
  assert.equal((await db.doc(`businesses/${BID}/products/p2`).get()).get("stock"), undefined);
});
