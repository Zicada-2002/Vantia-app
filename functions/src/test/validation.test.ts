import assert from "node:assert/strict";
import { test } from "node:test";
import {
  INVITE_ALPHABET,
  generateInviteCode,
  parseCreateBusiness,
  parseInviteCode,
} from "../validation.js";

const valid = { name: " Bodega Don Carlos ", phone: "+51 987 654 321", department: "Lima", province: "Lima" };

test("parseCreateBusiness normaliza nombre y teléfono", () => {
  assert.deepEqual(parseCreateBusiness(valid), {
    name: "Bodega Don Carlos",
    phone: "987654321",
    department: "Lima",
    province: "Lima",
  });
});

test("parseCreateBusiness rechaza datos inválidos con reason invalid-data", () => {
  for (const bad of [
    { ...valid, name: "x" },
    { ...valid, phone: "887654321" },
    { ...valid, department: "Narnia" },
    { ...valid, province: "" },
    null,
  ]) {
    assert.throws(() => parseCreateBusiness(bad), (e: { code: string; details: { reason: string } }) =>
      e.code === "invalid-argument" && e.details.reason === "invalid-data");
  }
});

test("parseInviteCode acepta minúsculas y rechaza ambiguos", () => {
  assert.equal(parseInviteCode({ code: " abc234 " }), "ABC234");
  assert.throws(() => parseInviteCode({ code: "ABC10O" }));
  assert.throws(() => parseInviteCode({ code: "ABC23" }));
  assert.throws(() => parseInviteCode({}));
});

test("generateInviteCode usa solo el alfabeto permitido", () => {
  let i = 0;
  const code = generateInviteCode((max) => (i++ * 7) % max);
  assert.equal(code.length, 6);
  for (const ch of code) assert.ok(INVITE_ALPHABET.includes(ch));
  assert.doesNotMatch(INVITE_ALPHABET, /[01OIL]/);
});

import { paymentPushText } from "../collaborators.js";

test("paymentPushText", () => {
  assert.equal(paymentPushText("Ana", 2500, "yape"), "Ana registró S/ 25.00 por Yape");
  assert.equal(paymentPushText("", 123456, "cash"), "Un colaborador registró S/ 1,234.56 por efectivo");
});
