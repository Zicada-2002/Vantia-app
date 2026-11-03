import { HttpsError, type FunctionsErrorCode } from "firebase-functions/v2/https";

/** Códigos estables que la app traduce (ver mapFunctionsException en Dart). */
export type Reason =
  | "invite-invalid"
  | "invite-expired"
  | "invite-used"
  | "already-member"
  | "email-not-verified"
  | "not-owner"
  | "invalid-data";

export function fail(code: FunctionsErrorCode, reason: Reason, message: string): HttpsError {
  return new HttpsError(code, message, { reason });
}
