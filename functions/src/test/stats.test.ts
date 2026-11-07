import assert from "node:assert/strict";
import { test } from "node:test";
import { aggregateDay } from "../stats.js";

test("aggregateDay suma por método y usuario, ignora anulados", () => {
  const s = aggregateDay("2026-11-02", [
    { method: "cash", amountCents: 3750, status: "active", createdBy: "a" },
    { method: "yape", amountCents: 1000, status: "active", createdBy: "a" },
    { method: "yape", amountCents: 500, status: "active", createdBy: "b" },
    { method: "bcp", amountCents: 9999, status: "voided", createdBy: "b" },
  ]);
  assert.equal(s.totalCents, 5250);
  assert.equal(s.count, 3);
  assert.equal(s.cashCents, 3750);
  assert.equal(s.cashCount, 1);
  assert.equal(s.digitalCount, 2);
  assert.deepEqual(s.byMethod, { cash: { cents: 3750, count: 1 }, yape: { cents: 1500, count: 2 } });
  assert.deepEqual(s.byUser, { a: { cents: 4750, count: 2 }, b: { cents: 500, count: 1 } });
});

import { stockDeltas } from "../products.js";

test("stockDeltas agrupa por producto e ignora inválidos", () => {
  const d = stockDeltas([
    { productId: "a", qty: 2 },
    { productId: "a", qty: 1 },
    { productId: "b", qty: 0 },
    { productId: "", qty: 3 },
    { qty: 1 },
    { productId: "c", qty: 1.5 },
    { productId: "d", qty: 4 },
  ]);
  assert.deepEqual([...d.entries()], [["a", 3], ["d", 4]]);
  assert.equal(stockDeltas(undefined).size, 0);
});

import { planFromRevenueCat } from "../account.js";

test("planFromRevenueCat", () => {
  assert.deepEqual(planFromRevenueCat({ type: "INITIAL_PURCHASE", expiration_at_ms: 123 }), { tier: "pro", renewsAt: 123 });
  assert.deepEqual(planFromRevenueCat({ type: "EXPIRATION" }), { tier: "free", renewsAt: null });
  assert.equal(planFromRevenueCat({ type: "CANCELLATION" }), null);
  assert.equal(planFromRevenueCat({}), null);
});
