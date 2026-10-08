import type { Permission } from "./permissions.js";
import type { Role } from "./roles.js";

export interface AppUser {
  id: string;
  firebaseUid: string;
  email: string;
  name: string | null;
  phone: string | null;

  role: Role;
  permissions: Permission[];

  companyId: string | null;
  warehouseIds: string[];

  isActive: boolean;
  companyIsActive: boolean;
}

export function isWarehouseScopedUser(user: AppUser): boolean {
  return (
    user.role === "WAREHOUSE_MANAGER" ||
    user.role === "PACKER"
  );
}
