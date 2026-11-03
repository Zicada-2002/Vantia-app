/**
 * Pruebas de integración contra los emuladores (Auth + Firestore + Functions).
 * Ejecutar con: npm run test:emulator
 */
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
import { getFirestore } from "firebase-admin/firestore";

const PROJECT = "demo-vantia";
const AUTH = "http://127.0.0.1:9099";
const FUNCTIONS = `http://127.0.0.1:5001/${PROJECT}/southamerica-east1`;

process.env.FIREBASE_AUTH_EMULATOR_HOST ??= "127.0.0.1:9099";
process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:8080";

let admin: App;
let rules: RulesTestEnvironment;

interface Account {
  uid: string;
  token: string;
}

async function authPost(path: string, body: object): Promise<Record<string, string>> {
  const res = await fetch(`${AUTH}/identitytoolkit.googleapis.com/v1/${path}?key=fake`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
  const json = (await res.json()) as Record<string, string>;
  assert.ok(res.ok, JSON.stringify(json));
  return json;
}

async function createAccount(email: string, name: string, verified: boolean): Promise<Account> {
  const password = "clave1234";
  const created = await authPost("accounts:signUp", { email, password, returnSecureToken: true });
  await authPost("accounts:update", { idToken: created.idToken, displayName: name });
  if (verified) await getAuth(admin).updateUser(created.localId, { emailVerified: true });
  const signed = await authPost("accounts:signInWithPassword", { email, password, returnSecureToken: true });
  return { uid: signed.localId, token: signed.idToken };
}

interface CallResult {
  result?: Record<string, unknown>;
  error?: { status: string; message: string; details?: { reason?: string } };
}

async function call(name: string, who: Account, data: object): Promise<CallResult> {
  const res = await fetch(`${FUNCTIONS}/${name}`, {
    method: "POST",
    headers: { "content-type": "application/json", authorization: `Bearer ${who.token}` },
    body: JSON.stringify({ data }),
  });
  return (await res.json()) as CallResult;
}

const businessInput = { name: "Bodega Don Carlos", phone: "987654321", department: "Lima", province: "Lima" };

before(async () => {
  admin = initializeApp({ projectId: PROJECT }, "test-admin");
  rules = await initializeTestEnvironment({
    projectId: PROJECT,
    firestore: {
      host: "127.0.0.1",
      port: 8080,
      rules: readFileSync("../firebase/firestore.rules", "utf8"),
    },
  });
});

after(async () => {
  await rules.cleanup();
  await deleteApp(admin);
});

describe("onboarding con Cloud Functions", () => {
  let owner: Account;
  let ana: Account;
  let luis: Account;
  let businessId: string;
  let code: string;

  before(async () => {
    const run = Date.now();
    owner = await createAccount(`owner-${run}@vantia.pe`, "Carlos", true);
    ana = await createAccount(`ana-${run}@vantia.pe`, "Ana", true);
    luis = await createAccount(`luis-${run}@vantia.pe`, "Luis", true);
  });

  test("sin verificar el correo no puede crear un negocio", async () => {
    const unverified = await createAccount(`nov-${Date.now()}@vantia.pe`, "Nov", false);
    const res = await call("createBusiness", unverified, businessInput);
    assert.equal(res.error?.details?.reason, "email-not-verified");
  });

  test("datos inválidos → invalid-data", async () => {
    const res = await call("createBusiness", owner, { ...businessInput, phone: "123" });
    assert.equal(res.error?.details?.reason, "invalid-data");
  });

  test("crea el negocio con prueba de 7 días y deja al usuario como dueño", async () => {
    const res = await call("createBusiness", owner, businessInput);
    assert.ok(res.result, JSON.stringify(res.error));
    businessId = res.result.businessId as string;

    const db = getFirestore(admin);
    const [user, biz, member] = await Promise.all([
      db.doc(`users/${owner.uid}`).get(),
      db.doc(`businesses/${businessId}`).get(),
      db.doc(`businesses/${businessId}/members/${owner.uid}`).get(),
    ]);
    assert.equal(user.get("role"), "owner");
    assert.equal(user.get("activeBusinessId"), businessId);
    assert.equal(biz.get("plan.tier"), "trial");
    const days = (biz.get("plan.trialEndsAt").toMillis() - Date.now()) / 86_400_000;
    assert.ok(days > 6.9 && days <= 7, `trial de ${days} días`);
    assert.equal(member.get("role"), "owner");
  });

  test("no puede crear un segundo negocio", async () => {
    const res = await call("createBusiness", owner, businessInput);
    assert.equal(res.error?.details?.reason, "already-member");
  });

  test("solo el dueño genera invitaciones", async () => {
    const denied = await call("generateInvite", ana, {});
    assert.equal(denied.error?.details?.reason, "not-owner");

    const res = await call("generateInvite", owner, {});
    assert.ok(res.result, JSON.stringify(res.error));
    code = res.result.code as string;
    assert.match(code, /^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{6}$/);
  });

  test("colaborador canjea el código (en minúsculas) y se une", async () => {
    const res = await call("redeemInvite", ana, { code: code.toLowerCase() });
    assert.equal(res.result?.businessId, businessId, JSON.stringify(res.error));
    const member = await getFirestore(admin).doc(`businesses/${businessId}/members/${ana.uid}`).get();
    assert.equal(member.get("role"), "collaborator");
  });

  test("el código es de un solo uso; inexistente da invite-invalid", async () => {
    assert.equal((await call("redeemInvite", luis, { code })).error?.details?.reason, "invite-used");
    assert.equal((await call("redeemInvite", luis, { code: "ZZZ999" })).error?.details?.reason, "invite-invalid");
  });

  test("código vencido → invite-expired", async () => {
    const res = await call("generateInvite", owner, {});
    const expiredCode = res.result!.code as string;
    await getFirestore(admin)
      .doc(`businesses/${businessId}/invites/${expiredCode}`)
      .update({ expiresAt: new Date(Date.now() - 1000) });
    assert.equal((await call("redeemInvite", luis, { code: expiredCode })).error?.details?.reason, "invite-expired");
  });

  test("revocar invitación: el código deja de servir", async () => {
    const gen = await call("generateInvite", owner, {});
    const revoked = gen.result!.code as string;
    assert.equal((await call("revokeInvite", ana, { code: revoked })).error?.details?.reason, "not-owner");
    assert.ok((await call("revokeInvite", owner, { code: revoked })).result);
    assert.equal((await call("redeemInvite", luis, { code: revoked })).error?.details?.reason, "invite-invalid");
    const inv = await getFirestore(admin).doc(`businesses/${businessId}/invites/${revoked}`).get();
    assert.equal(inv.get("status"), "revoked");
  });

  test("desactivar y reactivar colaborador", async () => {
    const db = getFirestore(admin);
    assert.ok((await call("setMemberActive", owner, { uid: ana.uid, active: false })).result);
    assert.equal((await db.doc(`users/${ana.uid}`).get()).get("activeBusinessId"), null);
    assert.equal((await db.doc(`businesses/${businessId}/members/${ana.uid}`).get()).get("active"), false);
    const anaDb = rules.authenticatedContext(ana.uid, { email_verified: true }).firestore();
    await assertFails(anaDb.doc(`businesses/${businessId}`).get());

    assert.ok((await call("setMemberActive", owner, { uid: ana.uid, active: true })).result);
    assert.equal((await db.doc(`users/${ana.uid}`).get()).get("activeBusinessId"), businessId);
    await assertSucceeds(anaDb.doc(`businesses/${businessId}`).get());

    assert.equal(
      (await call("setMemberActive", owner, { uid: owner.uid, active: false })).error?.details?.reason,
      "invalid-data",
    );
    assert.equal((await call("setMemberActive", ana, { uid: owner.uid, active: false })).error?.details?.reason, "not-owner");
  });

  describe("reglas de Firestore", () => {
    const verified = { email_verified: true };

    test("miembros leen el negocio; extraños y no verificados no", async () => {
      const ownerDb = rules.authenticatedContext(owner.uid, verified).firestore();
      const anaDb = rules.authenticatedContext(ana.uid, verified).firestore();
      const luisDb = rules.authenticatedContext(luis.uid, verified).firestore();
      const anaUnverified = rules.authenticatedContext(ana.uid, { email_verified: false }).firestore();

      await assertSucceeds(ownerDb.doc(`businesses/${businessId}`).get());
      await assertSucceeds(anaDb.doc(`businesses/${businessId}`).get());
      await assertFails(luisDb.doc(`businesses/${businessId}`).get());
      await assertFails(anaUnverified.doc(`businesses/${businessId}`).get());
      await assertFails(rules.unauthenticatedContext().firestore().doc(`businesses/${businessId}`).get());
    });

    test("invitaciones: solo el dueño las lee; nadie las escribe", async () => {
      const ownerDb = rules.authenticatedContext(owner.uid, verified).firestore();
      const anaDb = rules.authenticatedContext(ana.uid, verified).firestore();
      await assertSucceeds(ownerDb.doc(`businesses/${businessId}/invites/${code}`).get());
      await assertFails(anaDb.doc(`businesses/${businessId}/invites/${code}`).get());
      await assertFails(ownerDb.doc(`businesses/${businessId}/invites/NUEVO2`).set({ status: "active" }));
      await assertFails(ownerDb.doc(`inviteCodes/${code}`).get());
    });

    test("perfil: se edita el nombre, pero no el negocio ni el rol", async () => {
      const anaDb = rules.authenticatedContext(ana.uid, verified).firestore();
      await assertSucceeds(anaDb.doc(`users/${ana.uid}`).update({ displayName: "Ana M." }));
      await assertFails(anaDb.doc(`users/${ana.uid}`).update({ role: "owner" }));
      await assertFails(anaDb.doc(`users/${ana.uid}`).update({ activeBusinessId: "otro" }));
      await assertFails(anaDb.doc(`users/${owner.uid}`).get());
    });

    test("negocio: solo el dueño edita datos permitidos; nadie se auto-asigna miembro", async () => {
      const ownerDb = rules.authenticatedContext(owner.uid, verified).firestore();
      const anaDb = rules.authenticatedContext(ana.uid, verified).firestore();
      const luisDb = rules.authenticatedContext(luis.uid, verified).firestore();
      await assertSucceeds(ownerDb.doc(`businesses/${businessId}`).update({ name: "Bodega Carlos" }));
      await assertFails(ownerDb.doc(`businesses/${businessId}`).update({ plan: { tier: "pro" } }));
      await assertFails(anaDb.doc(`businesses/${businessId}`).update({ name: "Mío" }));
      await assertFails(
        luisDb.doc(`businesses/${businessId}/members/${luis.uid}`).set({ role: "owner", active: true }),
      );
    });
  });
});

describe("eliminar cuenta (F-82)", () => {
  test("colaborador: anonimiza sus pagos, sale del negocio y se borra", async () => {
    const run = Date.now();
    const owner = await createAccount(`del-owner-${run}@vantia.pe`, "Dueño", true);
    const col = await createAccount(`del-col-${run}@vantia.pe`, "Col", true);
    const biz = await call("createBusiness", owner, businessInput);
    const bid = biz.result!.businessId as string;
    const code = (await call("generateInvite", owner, {})).result!.code as string;
    await call("redeemInvite", col, { code });
    const db = getFirestore(admin);
    await db.doc(`businesses/${bid}/payments/p1`).set({ createdBy: col.uid, createdByName: "Col", amountCents: 100, status: "active", dayKey: "2026-11-02" });

    assert.equal((await call("deleteAccount", col, {})).error?.details?.reason, "invalid-data");
    assert.ok((await call("deleteAccount", col, { confirm: "ELIMINAR" })).result);
    assert.equal((await db.doc(`businesses/${bid}/payments/p1`).get()).get("createdByName"), "Usuario eliminado");
    assert.equal((await db.doc(`businesses/${bid}/members/${col.uid}`).get()).get("active"), false);
    assert.equal((await db.doc(`users/${col.uid}`).get()).exists, false);
    await assert.rejects(getAuth(admin).getUser(col.uid));
  });
});
