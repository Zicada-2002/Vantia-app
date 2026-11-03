import { getFirestore } from "firebase-admin/firestore";
import type { CallableRequest } from "firebase-functions/v2/https";
import { requireVerified, type VerifiedCaller } from "./auth.js";
import { fail } from "./errors.js";

/** Exige que quien llama sea dueño de su negocio activo. */
export async function requireOwner(req: CallableRequest): Promise<VerifiedCaller & { businessId: string }> {
  const caller = requireVerified(req);
  const user = await getFirestore().doc(`users/${caller.uid}`).get();
  const businessId = user.get("activeBusinessId") as string | undefined;
  if (!businessId || user.get("role") !== "owner") {
    throw fail("permission-denied", "not-owner", "Solo el dueño puede hacer esto");
  }
  return { ...caller, businessId };
}
