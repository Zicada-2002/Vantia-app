import { randomInt } from "node:crypto";
import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/v2/https";
import { requireVerified } from "./auth.js";
import { fail } from "./errors.js";
import { generateInviteCode, parseCreateBusiness, parseInviteCode } from "./validation.js";

const DAY_MS = 24 * 60 * 60 * 1000;
export const TRIAL_DAYS = 7;
export const INVITE_TTL_HOURS = 48;

/** F-16: crea el negocio y deja al usuario como dueño con 7 días de prueba. */
export const createBusiness = onCall(async (req) => {
  const caller = requireVerified(req);
  const input = parseCreateBusiness(req.data);
  const db = getFirestore();
  const userRef = db.doc(`users/${caller.uid}`);
  const bizRef = db.collection("businesses").doc();

  await db.runTransaction(async (tx) => {
    const user = await tx.get(userRef);
    if (user.get("activeBusinessId")) {
      throw fail("failed-precondition", "already-member", "El usuario ya tiene un negocio");
    }
    const now = Timestamp.now();
    tx.create(bizRef, {
      ...input,
      ownerUid: caller.uid,
      plan: {
        tier: "trial",
        trialEndsAt: Timestamp.fromMillis(now.toMillis() + TRIAL_DAYS * DAY_MS),
      },
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.create(bizRef.collection("members").doc(caller.uid), {
      role: "owner",
      displayName: caller.name,
      active: true,
      joinedAt: FieldValue.serverTimestamp(),
    });
    tx.set(
      userRef,
      {
        displayName: caller.name,
        email: caller.email,
        activeBusinessId: bizRef.id,
        role: "owner",
        ...(user.exists ? {} : { createdAt: FieldValue.serverTimestamp() }),
      },
      { merge: true },
    );
  });

  return { businessId: bizRef.id };
});

/** F-30 (base, necesaria para probar F-17): el dueño genera un código. */
export const generateInvite = onCall(async (req) => {
  const caller = requireVerified(req);
  const db = getFirestore();
  const user = await db.doc(`users/${caller.uid}`).get();
  const bid = user.get("activeBusinessId") as string | undefined;
  if (!bid || user.get("role") !== "owner") {
    throw fail("permission-denied", "not-owner", "Solo el dueño puede invitar");
  }

  const expiresAt = Timestamp.fromMillis(Date.now() + INVITE_TTL_HOURS * 60 * 60 * 1000);
  for (let attempt = 0; attempt < 5; attempt++) {
    const code = generateInviteCode(randomInt);
    const indexRef = db.doc(`inviteCodes/${code}`);
    try {
      await db.runTransaction(async (tx) => {
        const existing = await tx.get(indexRef);
        if (existing.exists) throw new Error("collision");
        tx.create(indexRef, { businessId: bid });
        tx.create(db.doc(`businesses/${bid}/invites/${code}`), {
          status: "active",
          createdBy: caller.uid,
          createdAt: FieldValue.serverTimestamp(),
          expiresAt,
        });
      });
      return { code, expiresAt: expiresAt.toMillis() };
    } catch (e) {
      if ((e as Error).message !== "collision") throw e;
    }
  }
  throw new Error("No se pudo generar un código único");
});

/** F-17: el colaborador canjea un código y se une al negocio. */
export const redeemInvite = onCall(async (req) => {
  const caller = requireVerified(req);
  const code = parseInviteCode(req.data);
  const db = getFirestore();
  const userRef = db.doc(`users/${caller.uid}`);

  const businessId = await db.runTransaction(async (tx) => {
    const index = await tx.get(db.doc(`inviteCodes/${code}`));
    const bid = index.get("businessId") as string | undefined;
    if (!bid) throw fail("not-found", "invite-invalid", "Código inexistente");

    const inviteRef = db.doc(`businesses/${bid}/invites/${code}`);
    const [invite, user] = await Promise.all([tx.get(inviteRef), tx.get(userRef)]);
    const status = invite.get("status") as string | undefined;
    if (!invite.exists || status === "revoked") {
      throw fail("not-found", "invite-invalid", "Código revocado o inexistente");
    }
    if (status === "used") throw fail("failed-precondition", "invite-used", "Código ya usado");
    const expiresAt = invite.get("expiresAt") as Timestamp;
    if (expiresAt.toMillis() < Date.now()) {
      throw fail("failed-precondition", "invite-expired", "Código vencido");
    }
    if (user.get("activeBusinessId")) {
      throw fail("failed-precondition", "already-member", "El usuario ya tiene un negocio");
    }

    tx.update(inviteRef, {
      status: "used",
      usedBy: caller.uid,
      usedAt: FieldValue.serverTimestamp(),
    });
    tx.create(db.doc(`businesses/${bid}/members/${caller.uid}`), {
      role: "collaborator",
      displayName: caller.name,
      active: true,
      inviteCode: code,
      joinedAt: FieldValue.serverTimestamp(),
    });
    tx.set(
      userRef,
      {
        displayName: caller.name,
        email: caller.email,
        activeBusinessId: bid,
        role: "collaborator",
        ...(user.exists ? {} : { createdAt: FieldValue.serverTimestamp() }),
      },
      { merge: true },
    );
    return bid;
  });

  return { businessId };
});
