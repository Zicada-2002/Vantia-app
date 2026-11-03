import { fail } from "./errors.js";

export const INVITE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
export const INVITE_LENGTH = 6;

export const PERU_DEPARTMENTS = [
  "Amazonas", "Áncash", "Apurímac", "Arequipa", "Ayacucho", "Cajamarca",
  "Callao", "Cusco", "Huancavelica", "Huánuco", "Ica", "Junín", "La Libertad",
  "Lambayeque", "Lima", "Loreto", "Madre de Dios", "Moquegua", "Pasco",
  "Piura", "Puno", "San Martín", "Tacna", "Tumbes", "Ucayali",
] as const;

export interface CreateBusinessInput {
  name: string;
  phone: string;
  department: string;
  province: string;
}

function str(data: Record<string, unknown>, key: string): string {
  const v = data[key];
  return typeof v === "string" ? v.trim() : "";
}

/** Valida y normaliza la entrada de createBusiness. Lanza invalid-argument. */
export function parseCreateBusiness(raw: unknown): CreateBusinessInput {
  const data = (raw && typeof raw === "object" ? raw : {}) as Record<string, unknown>;
  const name = str(data, "name");
  const phone = str(data, "phone").replace(/[\s-]/g, "").replace(/^\+?51/, "");
  const department = str(data, "department");
  const province = str(data, "province");

  const errors: string[] = [];
  if (name.length < 2 || name.length > 80) errors.push("name");
  if (!/^9\d{8}$/.test(phone)) errors.push("phone");
  if (!(PERU_DEPARTMENTS as readonly string[]).includes(department)) errors.push("department");
  if (province.length < 2 || province.length > 60) errors.push("province");
  if (errors.length > 0) {
    throw fail("invalid-argument", "invalid-data", `Campos inválidos: ${errors.join(", ")}`);
  }
  return { name, phone, department, province };
}

export function parseInviteCode(raw: unknown): string {
  const code = (raw && typeof raw === "object" ? (raw as Record<string, unknown>).code : undefined);
  const normalized = typeof code === "string" ? code.trim().toUpperCase() : "";
  const re = new RegExp(`^[${INVITE_ALPHABET}]{${INVITE_LENGTH}}$`);
  if (!re.test(normalized)) {
    throw fail("invalid-argument", "invite-invalid", "Código con formato inválido");
  }
  return normalized;
}

/** Genera un código usando una fuente de aleatoriedad inyectable (testeable). */
export function generateInviteCode(randomInt: (max: number) => number): string {
  let code = "";
  for (let i = 0; i < INVITE_LENGTH; i++) {
    code += INVITE_ALPHABET[randomInt(INVITE_ALPHABET.length)];
  }
  return code;
}
