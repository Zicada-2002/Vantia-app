import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { fail } from "./errors.js";

export interface VerifiedCaller {
  uid: string;
  email: string;
  name: string;
}

/** Exige sesión con correo verificado (F-11 también se aplica en backend). */
export function requireVerified(req: CallableRequest): VerifiedCaller {
  const auth = req.auth;
  if (!auth) throw new HttpsError("unauthenticated", "Inicia sesión");
  if (auth.token.email_verified !== true) {
    throw fail("permission-denied", "email-not-verified", "Correo no verificado");
  }
  return {
    uid: auth.uid,
    email: auth.token.email ?? "",
    name: (auth.token.name as string | undefined) ?? "",
  };
}
