/** Reglas de `payments` (M2). Ejecutar con: npm run test:emulator */
import { readFileSync } from "node:fs";
import { after, before, describe, test } from "node:test";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { Timestamp, doc, getDoc, serverTimestamp, setDoc, updateDoc } from "firebase/firestore";

const BID = `biz-pay-${Date.now()}`;
const OWNER = "owner-pay";
const ANA = "ana-pay";
const OUT = "out-pay";
const DAY = "2026-11-02";
const verified = { email_verified: true };

let env: RulesTestEnvironment;

function cashPayment(uid: string, over: Record<string, unknown> = {}) {
  return {
    method: "cash",
    amountCents: 3750,
    receivedCents: 5000,
    changeCents: 1250,
    occurredAt: Timestamp.now(),
    dayKey: DAY,
    createdBy: uid,
    createdByName: "Ana",
    source: "manual",
    verified: false,
    status: "active",
    items: [],
    createdAt: serverTimestamp(),
    ...over,
  };
}

const db = (uid: string) => env.authenticatedContext(uid, verified).firestore();
const payRef = (uid: string, id: string) => doc(db(uid), `businesses/${BID}/payments/${id}`);

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-vantia",
    firestore: { host: "127.0.0.1", port: 8080, rules: readFileSync("../firebase/firestore.rules", "utf8") },
  });
  await env.withSecurityRulesDisabled(async (ctx) => {
    const fs = ctx.firestore();
    await setDoc(doc(fs, `businesses/${BID}`), { name: "B", ownerUid: OWNER });
    await setDoc(doc(fs, `businesses/${BID}/members/${OWNER}`), { role: "owner", active: true });
    await setDoc(doc(fs, `businesses/${BID}/members/${ANA}`), { role: "collaborator", active: true });
    // Pago antiguo de Ana (fuera de la ventana de 15 min).
    await setDoc(doc(fs, `businesses/${BID}/payments/old-ana`), {
      ...cashPayment(ANA),
      createdAt: Timestamp.fromMillis(Date.now() - 60 * 60 * 1000),
    });
    await setDoc(doc(fs, `businesses/${BID}/payments/owner-1`), {
      ...cashPayment(OWNER),
      createdAt: Timestamp.now(),
    });
  });
});

after(() => env.cleanup());

describe("reglas de payments", () => {
  test("crear: válido para miembros; inválido o ajeno se rechaza", async () => {
    await assertSucceeds(setDoc(payRef(ANA, "p1"), cashPayment(ANA)));
    const { receivedCents: _r, changeCents: _c, ...digital } = cashPayment(ANA);
    await assertSucceeds(setDoc(payRef(ANA, "p2"), { ...digital, method: "yape", amountCents: 1000 }));
    await assertFails(setDoc(payRef(ANA, "x0"), { ...digital, method: "yape", amountCents: 1000, changeCents: 10 }));
    await assertFails(setDoc(payRef(OUT, "x1"), cashPayment(OUT)));
    await assertFails(setDoc(payRef(ANA, "x2"), cashPayment(OWNER))); // suplantación
    await assertFails(setDoc(payRef(ANA, "x3"), cashPayment(ANA, { amountCents: 9999 }))); // no cuadra
    await assertFails(setDoc(payRef(ANA, "x4"), cashPayment(ANA, { amountCents: 0, receivedCents: 0, changeCents: 0 })));
    await assertFails(setDoc(payRef(ANA, "x5"), cashPayment(ANA, { method: "bitcoin" })));
    await assertFails(setDoc(payRef(ANA, "x6"), cashPayment(ANA, { status: "voided" })));
    await assertFails(setDoc(payRef(ANA, "x7"), cashPayment(ANA, { hacked: true })));
    await assertFails(
      setDoc(payRef(ANA, "x8"), cashPayment(ANA, { occurredAt: Timestamp.fromMillis(Date.now() + 86400000) })),
    );
  });

  test("leer: el dueño todo; el colaborador solo lo suyo", async () => {
    await assertSucceeds(getDoc(payRef(OWNER, "old-ana")));
    await assertSucceeds(getDoc(payRef(ANA, "old-ana")));
    await assertFails(getDoc(payRef(ANA, "owner-1")));
    await assertFails(getDoc(payRef(OUT, "old-ana")));
  });

  const voidData = (uid: string) => ({
    status: "voided",
    voidReason: "Registrado por error",
    voidedBy: uid,
    voidedAt: serverTimestamp(),
  });

  test("anular: colaborador solo lo suyo dentro de 15 min; dueño siempre", async () => {
    await assertSucceeds(updateDoc(payRef(ANA, "p1"), voidData(ANA)));
    await assertFails(updateDoc(payRef(ANA, "old-ana"), voidData(ANA)));
    await assertFails(updateDoc(payRef(ANA, "owner-1"), voidData(ANA)));
    await assertSucceeds(updateDoc(payRef(OWNER, "old-ana"), voidData(OWNER)));
  });

  test("anular: no se puede re-anular, cambiar el monto ni borrar", async () => {
    await assertFails(updateDoc(payRef(OWNER, "old-ana"), voidData(OWNER))); // ya anulado
    await assertFails(updateDoc(payRef(OWNER, "owner-1"), { ...voidData(OWNER), amountCents: 1 }));
    await assertFails(updateDoc(payRef(OWNER, "owner-1"), { ...voidData(OWNER), voidReason: "x" }));
  });

  test("caja cerrada: no se crean ni anulan pagos de ese día", async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), `businesses/${BID}/cashSessions/${DAY}_${ANA}`), { status: "closed" });
    });
    await assertFails(setDoc(payRef(ANA, "after-close"), cashPayment(ANA)));
    await assertSucceeds(setDoc(payRef(ANA, "other-day"), cashPayment(ANA, { dayKey: "2026-11-03" })));
  });
});
