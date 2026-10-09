export type InvitationRole = "ADMIN" | "MANAGER" | "OPERATOR" | "VIEWER";

export function normalizeRole(value: string): InvitationRole {
  const role = String(value ?? "").trim().toUpperCase();
  if (["ADMIN", "MANAGER", "OPERATOR", "VIEWER"].includes(role)) return role as InvitationRole;
  if (role === "COMPANY_ADMIN") return "ADMIN";
  if (role === "WAREHOUSE_MANAGER") return "MANAGER";
  if (role === "PACKING_OPERATOR") return "OPERATOR";
  throw new Error("INVALID_ROLE");
}

/** Values match the deployed legacy PostgreSQL UserRole enum labels. */
export function toDatabaseUserRole(value: string): InvitationRole {
  return normalizeRole(value);
}