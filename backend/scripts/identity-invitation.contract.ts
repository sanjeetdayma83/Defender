import assert from "node:assert/strict";
import { normalizeRole, toDatabaseUserRole } from "../src/services/invitation/invitation-role.js";

const cases: Array<[string, "ADMIN" | "MANAGER" | "OPERATOR" | "VIEWER"]> = [
  ["ADMIN", "ADMIN"],
  ["company_admin", "ADMIN"],
  ["MANAGER", "MANAGER"],
  ["warehouse_manager", "MANAGER"],
  ["OPERATOR", "OPERATOR"],
  ["packing_operator", "OPERATOR"],
  ["VIEWER", "VIEWER"],
];

for (const [input, expected] of cases) {
  assert.equal(normalizeRole(input), expected);
  assert.equal(toDatabaseUserRole(input), expected);
}
assert.throws(() => normalizeRole("PLATFORM_ADMIN"), /INVALID_ROLE/);
assert.throws(() => toDatabaseUserRole("OWNER"), /INVALID_ROLE/);
console.log(`Identity/invitation role contract: ${cases.length * 2 + 2} assertions passed.`);