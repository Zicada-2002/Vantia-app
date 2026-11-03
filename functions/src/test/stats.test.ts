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
