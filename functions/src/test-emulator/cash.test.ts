/** Cuadre de caja (M4): Functions + reglas. Ejecutar con: npm run test:emulator */
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { after, before, describe, test } from "node:test";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { deleteApp, initializeApp, type App } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { doc, getDoc, setDoc, updateDoc } from "firebase/firestore";

const PROJECT = "demo-vantia";
const FUNCTIONS = `http://127.0.0.1:5001/${PROJECT}/southamerica-east1`;
const AUTH = "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1";
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= "127.0.0.1:9099";
process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:8080";

let admin: App;
let env: RulesTestEnvironment;
const run = Date.now();
const BID = `biz-cash-${run}`;
const DAY = "2026-11-02";

async function account(email: string): Promise<{ uid: string; token: string }> {
  const post = async (path: string, body: object) =>
    (await (await fetch(`${AUTH}/${path}?key=fake`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(body),
    })).json()) as Record<string, string>;
  const c = await post("accounts:signUp", { email, password: "clave1234", returnSecureToken: true });
  await getAuth(admin).updateUser(c.localId, { emailVerified: true, displayName: email.split("@")[0] });
  const s = await post("accounts:signInWithPassword", { email, password: "clave1234", returnSecureToken: true });
  return { uid: s.localId, token: s.idToken };
}

async function call(name: string, token: string, data: object) {
  const res = await fetch(`${FUNCTIONS}/${name}`, {
    method: "POST",
    headers: { "content-type": "application/json", authorization: `Bearer ${token}` },
    body: JSON.stringify({ data }),
  });
  return (await res.json()) as { result?: Record<string, number>; error?: { details?: { reason?: string } } };
}

describe("cuadre de caja", () => {
  let owner: { uid: string; token: string };
  let ana: { uid: string; token: string };

  before(async () => {
    admin = initializeApp({ projectId: PROJECT }, "cash-admin");
    env = await initializeTestEnvironment({
      projectId: PROJECT,
      firestore: { host: "127.0.0.1", port: 8080, rules: readFileSync("../firebase/firestore.rules", "utf8") },
    });
    owner = await account(`cash-owner-${run}@vantia.pe`);
    ana = await account(`cash-ana-${run}@vantia.pe`);
    const db = getFirestore(admin);
    await db.doc(`businesses/${BID}`).set({ name: "B", ownerUid: owner.uid });
    await db.doc(`businesses/${BID}/members/${owner.uid}`).set({ role: "owner", active: true });
    await db.doc(`businesses/${BID}/members/${ana.uid}`).set({ role: "collaborator", active: true });
    await db.doc(`users/${owner.uid}`).set({ activeBusinessId: BID, role: "owner" });
    await db.doc(`users/${ana.uid}`).set({ activeBusinessId: BID, role: "collaborator", displayName: "Ana" });
    const pay = (id: string, d: object) =>
      db.doc(`businesses/${BID}/payments/${id}`).set({
        dayKey: DAY,
        createdBy: ana.uid,
        status: "active",
        occurredAt: Timestamp.now(),
        ...d,
      });
    await pay("c1", { method: "cash", amountCents: 3750, receivedCents: 5000, changeCents: 1250 });
    await pay("y1", { method: "yape", amountCents: 1000 });
    await pay("v1", { method: "cash", amountCents: 999, receivedCents: 999, changeCents: 0, status: "voided" });
    await pay("o1", { method: "cash", amountCents: 7000, receivedCents: 7000, changeCents: 0, createdBy: owner.uid });
  });

  after(async () => {
    await env.cleanup();
    await deleteApp(admin);
  });

  test("borrador: el colaborador guarda su fondo; no el de otros", async () => {
    const anaDb = env.authenticatedContext(ana.uid, { email_verified: true }).firestore();
    const mine = doc(anaDb, `businesses/${BID}/cashSessions/${DAY}_${ana.uid}`);
    await assertSucceeds(getDoc(mine)); // aunque aún no exista
    await assertSucceeds(setDoc(mine, { dayKey: DAY, uid: ana.uid, status: "open", openingCents: 10000 }));
    await assertSucceeds(updateDoc(mine, { countedCents: 12000 }));
    await assertFails(updateDoc(mine, { status: "closed" }));
    await assertFails(setDoc(doc(anaDb, `businesses/${BID}/cashSessions/${DAY}_${owner.uid}`), {
      dayKey: DAY, uid: owner.uid, status: "open",
    }));
    await assertFails(getDoc(doc(anaDb, `businesses/${BID}/cashSessions/${DAY}_${owner.uid}`)));
  });

  test("cerrar: el servidor recalcula y congela la caja", async () => {
    const res = await call("closeCashSession", ana.token, { dayKey: DAY, openingCents: 10000, countedCents: 13500 });
    assert.ok(res.result, JSON.stringify(res.error));
    assert.equal(res.result.totalCents, 4750); // solo lo de Ana y activo
    assert.equal(res.result.expectedCents, 13750); // 100 + 50 − 12.50
    assert.equal(res.result.differenceCents, -250);

    const s = await getFirestore(admin).doc(`businesses/${BID}/cashSessions/${DAY}_${ana.uid}`).get();
    assert.equal(s.get("status"), "closed");

    const anaDb = env.authenticatedContext(ana.uid, { email_verified: true }).firestore();
    await assertFails(updateDoc(doc(anaDb, `businesses/${BID}/cashSessions/${DAY}_${ana.uid}`), { countedCents: 1 }));
    assert.equal(
      (await call("closeCashSession", ana.token, { dayKey: DAY, openingCents: 0, countedCents: 0 })).error?.details?.reason,
      "invalid-data",
    );
  });

  test("reabrir: solo el dueño, con motivo y auditoría", async () => {
    assert.equal(
      (await call("reopenCashSession", ana.token, { dayKey: DAY, uid: ana.uid, reason: "Error de conteo" })).error?.details?.reason,
      "not-owner",
    );
    assert.equal(
      (await call("reopenCashSession", owner.token, { dayKey: DAY, uid: ana.uid, reason: "" })).error?.details?.reason,
      "invalid-data",
    );
    assert.ok((await call("reopenCashSession", owner.token, { dayKey: DAY, uid: ana.uid, reason: "Error de conteo" })).result);
    const db = getFirestore(admin);
    assert.equal((await db.doc(`businesses/${BID}/cashSessions/${DAY}_${ana.uid}`).get()).get("status"), "reopened");
    assert.equal((await db.collection(`businesses/${BID}/audit`).get()).size, 1);

    const anaDb = env.authenticatedContext(ana.uid, { email_verified: true }).firestore();
    await assertSucceeds(updateDoc(doc(anaDb, `businesses/${BID}/cashSessions/${DAY}_${ana.uid}`), { countedCents: 13750 }));
    await assertFails(getDoc(doc(anaDb, `businesses/${BID}/audit/x`)));
  });
});
