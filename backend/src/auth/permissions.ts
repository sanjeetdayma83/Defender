import type { Role } from "./roles.js";

export const PERMISSIONS = [
  // Platform
  "platform.company.view",
  "platform.company.manage",
  "platform.company.viewas",
  "platform.user.view",
  "platform.plan.view",
  "platform.plan.manage",
  "platform.subscription.view",
  "platform.wallet.adjust",
  "platform.wallet.adjust.approve",
  "platform.coupon.manage",
  "platform.revenue.view",
  "platform.analytics.view",
  "platform.audit.view",
  "platform.settings.manage",
  "platform.team.manage",
  "platform.system.health",
  "platform.webhook.replay",
  "platform.evidence.breakglass",

  // Seller team
  "team.view",
  "team.invite",
  "team.role.change",
  "team.suspend",
  "team.remove",

  // Warehouses / stations
  "warehouse.view",
  "warehouse.manage",
  "station.manage",

  // Products / orders
  "product.view",
  "product.manage",
  "order.view",
  "order.import",

  // Scan / packing
  "scan.lookup",
  "packing.start",
  "packing.complete",
  "packing.cancel",
  "recording.upload",

  // Evidence / claims / returns
  "evidence.view",
  "evidence.download",
  "evidence.export",
  "claim.manage",
  "return.record",

  // Wallet / usage
  "wallet.view_balance",
  "wallet.view_history",
  "usage.view_team",
  "usage.view_own",

  // Billing
  "billing.view",
  "invoice.download",
  "billing.manage",

  // Analytics / audit
  "analytics.view",
  "audit.view",

  // Company settings / common
  "settings.company.manage",
  "notification.view",
  "profile.manage",
] as const;

export type Permission = (typeof PERMISSIONS)[number];

const ALL_PLATFORM: readonly Permission[] = [
  "platform.company.view",
  "platform.company.manage",
  "platform.company.viewas",
  "platform.user.view",
  "platform.plan.view",
  "platform.plan.manage",
  "platform.subscription.view",
  "platform.wallet.adjust",
  "platform.wallet.adjust.approve",
  "platform.coupon.manage",
  "platform.revenue.view",
  "platform.analytics.view",
  "platform.audit.view",
  "platform.settings.manage",
  "platform.team.manage",
  "platform.system.health",
  "platform.webhook.replay",
  "platform.evidence.breakglass",
];

const ALL_COMMON_ADMIN: readonly Permission[] = [
  "notification.view",
  "profile.manage",
];

const ROLE_PERMISSIONS: Record<Role, readonly Permission[]> = {
  SUPER_ADMIN: [
    ...ALL_PLATFORM,
    ...ALL_COMMON_ADMIN,

    "team.view",
    "team.invite",
    "team.role.change",
    "team.suspend",
    "team.remove",
    "warehouse.view",
    "warehouse.manage",
    "station.manage",
    "product.view",
    "product.manage",
    "order.view",
    "order.import",
    "scan.lookup",
    "packing.start",
    "packing.complete",
    "packing.cancel",
    "recording.upload",
    "evidence.view",
    "evidence.download",
    "evidence.export",
    "claim.manage",
    "return.record",
    "wallet.view_balance",
    "wallet.view_history",
    "usage.view_team",
    "usage.view_own",
    "billing.view",
    "invoice.download",
    "billing.manage",
    "analytics.view",
    "audit.view",
    "settings.company.manage",
  ],

  SUPPORT: [
    "platform.company.view",
    "platform.company.viewas",
    "platform.user.view",
    "platform.plan.view",
    "platform.subscription.view",
    "platform.wallet.adjust",
    "platform.analytics.view",
    "platform.audit.view",
    "notification.view",
    "profile.manage",
    "wallet.view_history",
    "usage.view_team",
    "evidence.view",
    "evidence.download",
    "evidence.export",
    "order.view",
    "analytics.view",
  ],

  SALES: [
    "platform.company.view",
    "platform.plan.view",
    "platform.subscription.view",
    "platform.coupon.manage",
    "platform.revenue.view",
    "platform.analytics.view",
    "notification.view",
    "profile.manage",
  ],

  TECH_ADMIN: [
    "platform.company.view",
    "platform.user.view",
    "platform.analytics.view",
    "platform.audit.view",
    "platform.settings.manage",
    "platform.system.health",
    "platform.webhook.replay",
    "notification.view",
    "profile.manage",
  ],

  SELLER_ADMIN: [
    ...ALL_COMMON_ADMIN,

    "team.view",
    "team.invite",
    "team.role.change",
    "team.suspend",
    "team.remove",

    "warehouse.view",
    "warehouse.manage",
    "station.manage",

    "product.view",
    "product.manage",
    "order.view",
    "order.import",

    "scan.lookup",

    "evidence.view",
    "evidence.download",
    "evidence.export",
    "claim.manage",
    "return.record",

    "wallet.view_balance",
    "wallet.view_history",
    "usage.view_team",
    "usage.view_own",

    "billing.view",
    "invoice.download",
    "billing.manage",

    "analytics.view",
    "audit.view",
    "settings.company.manage",
  ],

  WAREHOUSE_MANAGER: [
    ...ALL_COMMON_ADMIN,

    "team.view",
    "warehouse.view",
    "station.manage",

    "product.view",
    "product.manage",
    "order.view",
    "order.import",

    "scan.lookup",
    "packing.start",
    "packing.complete",
    "packing.cancel",
    "recording.upload",

    "evidence.view",
    "evidence.download",
    "evidence.export",
    "return.record",

    "wallet.view_balance",
    "usage.view_team",
    "usage.view_own",

    "analytics.view",
  ],

  CLAIM_EXECUTIVE: [
    ...ALL_COMMON_ADMIN,

    "warehouse.view",
    "product.view",
    "order.view",

    "evidence.view",
    "evidence.download",
    "evidence.export",
    "claim.manage",
    "return.record",

    "usage.view_own",
  ],

  PACKER: [
    ...ALL_COMMON_ADMIN,

    "warehouse.view",
    "product.view",
    "order.view",
    "scan.lookup",

    "packing.start",
    "packing.complete",
    "packing.cancel",
    "recording.upload",

    "evidence.view",
    "usage.view_own",
  ],

  VIEWER: [
    ...ALL_COMMON_ADMIN,

    "warehouse.view",
    "product.view",
    "order.view",
    "evidence.view",
    "usage.view_own",
    "analytics.view",
  ],
};

export function permissionsForRole(role: Role): Permission[] {
  return [...ROLE_PERMISSIONS[role]];
}

export function hasPermission(
  role: Role,
  permission: Permission,
): boolean {
  return ROLE_PERMISSIONS[role].includes(permission);
}
