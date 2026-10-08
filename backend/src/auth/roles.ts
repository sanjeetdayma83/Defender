/**
 * Loss Defender Pro - Canonical RBAC roles.
 *
 * IMPORTANT:
 * The database still contains legacy role values.
 * Do not change the Prisma enum in this phase.
 *
 * This layer normalizes every legacy representation into
 * one canonical application role.
 */

export const ROLES = [
  "SUPER_ADMIN",
  "SUPPORT",
  "SALES",
  "TECH_ADMIN",
  "SELLER_ADMIN",
  "WAREHOUSE_MANAGER",
  "CLAIM_EXECUTIVE",
  "PACKER",
  "VIEWER",
] as const;

export type Role = (typeof ROLES)[number];

export const PLATFORM_ROLES = [
  "SUPER_ADMIN",
  "SUPPORT",
  "SALES",
  "TECH_ADMIN",
] as const satisfies readonly Role[];

export const SELLER_ROLES = [
  "SELLER_ADMIN",
  "WAREHOUSE_MANAGER",
  "CLAIM_EXECUTIVE",
  "PACKER",
  "VIEWER",
] as const satisfies readonly Role[];

const LEGACY_ROLE_MAP: Record<string, Role> = {
  // Platform
  super_admin: "SUPER_ADMIN",
  platform_admin: "SUPER_ADMIN",
  SUPER_ADMIN: "SUPER_ADMIN",
  PLATFORM_ADMIN: "SUPER_ADMIN",

  // Seller admin
  company_admin: "SELLER_ADMIN",
  owner: "SELLER_ADMIN",
  admin: "SELLER_ADMIN",
  OWNER: "SELLER_ADMIN",
  ADMIN: "SELLER_ADMIN",

  // Warehouse manager
  warehouse_manager: "WAREHOUSE_MANAGER",
  manager: "WAREHOUSE_MANAGER",
  MANAGER: "WAREHOUSE_MANAGER",

  // Packer
  packing_operator: "PACKER",
  operator: "PACKER",
  OPERATOR: "PACKER",

  // Viewer
  viewer: "VIEWER",
  VIEWER: "VIEWER",

  // Future canonical values
  SUPPORT: "SUPPORT",
  SALES: "SALES",
  TECH_ADMIN: "TECH_ADMIN",
  SELLER_ADMIN: "SELLER_ADMIN",
  WAREHOUSE_MANAGER: "WAREHOUSE_MANAGER",
  CLAIM_EXECUTIVE: "CLAIM_EXECUTIVE",
  PACKER: "PACKER",
};

export class UnknownRoleError extends Error {
  readonly code = "ROLE_UNKNOWN";
  readonly statusCode = 403;

  constructor(rawRole: unknown) {
    super(`Unrecognised Loss Defender role: ${String(rawRole ?? "")}`);
    this.name = "UnknownRoleError";
  }
}

export function toRole(rawRole: unknown): Role {
  const normalized = String(rawRole ?? "")
    .trim()
    .replace(/-/g, "_");

  const direct = LEGACY_ROLE_MAP[normalized];

  if (direct) {
    return direct;
  }

  const lower = normalized.toLowerCase();
  const mapped = LEGACY_ROLE_MAP[lower];

  if (mapped) {
    return mapped;
  }

  throw new UnknownRoleError(rawRole);
}

export function isPlatformRole(role: Role): boolean {
  return (PLATFORM_ROLES as readonly string[]).includes(role);
}

export function isSellerRole(role: Role): boolean {
  return (SELLER_ROLES as readonly string[]).includes(role);
}
