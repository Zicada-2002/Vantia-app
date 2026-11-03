import assert from "node:assert/strict";
import { test } from "node:test";
import { computeCashTotals } from "../cash.js";

test("computeCashTotals: esperado = fondo + recibido − cambios; ignora anulados", () => {
  const t = computeCashTotals(
    [
      { method: "cash", amountCents: 3750, receivedCents: 5000, changeCents: 1250, status: "active" },
      { method: "cash", amountCents: 1000, status: "active" }, // sin desglose
      { method: "yape", amountCents: 1000, status: "active" },
      { method: "cash", amountCents: 9999, receivedCents: 9999, changeCents: 0, status: "voided" },
    ],
    10000,
    16500,
  );
  assert.equal(t.totalCents, 5750);
  assert.equal(t.count, 3);
  assert.deepEqual(t.totalsByMethod, { cash: 4750, yape: 1000 });
  assert.equal(t.cashReceivedCents, 6000);
  assert.equal(t.changeGivenCents, 1250);
  assert.equal(t.expectedCents, 14750);
  assert.equal(t.differenceCents, 1750);
});

test("computeCashTotals sin pagos", () => {
  const t = computeCashTotals([], 5000, 4000);
  assert.equal(t.expectedCents, 5000);
  assert.equal(t.differenceCents, -1000);
});
