$ErrorActionPreference = "Stop"
$root = "D:\Loss Defender\backend"
Set-Location $root

$identity = Join-Path $root "src\services\identity\identity.service.ts"
$context = Join-Path $root "src\services\identity\company-context.service.ts"
$invitation = Join-Path $root "src\services\invitation\invitation.service.ts"
$package = Join-Path $root "package.json"
$invoice = Join-Path $root "prisma\manual-migrations\20261002_invoice_billingpayment\migration.sql"
$roleModule = Join-Path $root "src\services\invitation\invitation-role.ts"
$testFile = Join-Path $root "scripts\identity-invitation.contract.ts"
$required = @($identity, $context, $invitation, $package, $invoice)
foreach ($p in $required) { if (!(Test-Path -LiteralPath $p -PathType Leaf)) { throw "Missing required file: $p" } }

$backup = Join-Path $root (".repair-backups\identity-invitation-invoice-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
New-Item -ItemType Directory -Path $backup -Force | Out-Null
foreach ($p in $required) { Copy-Item -LiteralPath $p -Destination $backup }
Write-Host "Backup: $backup" -ForegroundColor Cyan

$roleSource = @'
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
'@
$testSource = @'
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
'@

$inviteText = Get-Content -LiteralPath $invitation -Raw
$oldRole = @'
export type InvitationRole = "ADMIN" | "MANAGER" | "OPERATOR" | "VIEWER";

function normalizeRole(value: string): InvitationRole {
  const role = String(value ?? "").trim().toUpperCase();
  if (["ADMIN", "MANAGER", "OPERATOR", "VIEWER"].includes(role)) {
    return role as InvitationRole;
  }
  if (role === "COMPANY_ADMIN") return "ADMIN";
  if (role === "WAREHOUSE_MANAGER") return "MANAGER";
  if (role === "PACKING_OPERATOR") return "OPERATOR";
  throw new Error("INVALID_ROLE");
}

function toDatabaseUserRole(
  value: string,
): "company_admin" | "warehouse_manager" | "packing_operator" | "viewer" {
  switch (normalizeRole(value)) {
    case "ADMIN":
      return "company_admin";
    case "MANAGER":
      return "warehouse_manager";
    case "OPERATOR":
      return "packing_operator";
    case "VIEWER":
      return "viewer";
  }
}
'@
if (!$inviteText.Contains($oldRole)) { throw "Invitation role block did not match expected source; no source changes made." }
$inviteText = $inviteText.Replace($oldRole, "")
$importAnchor = 'import crypto from "node:crypto";'
if (!$inviteText.Contains($importAnchor)) { throw "Invitation import anchor missing; no source changes made." }
$inviteText = $inviteText.Replace($importAnchor, $importAnchor + "`r`nimport { normalizeRole, toDatabaseUserRole, type InvitationRole } from `"./invitation-role.js`";")
$joinOld = 'LEFT JOIN public.warehouses w ON w.id = i.warehouse_id'
$joinNew = 'LEFT JOIN public.warehouses w ON w.id = i.warehouse_id AND w."companyId" = i.company_id'
$joinCount = [regex]::Matches($inviteText, [regex]::Escape($joinOld)).Count
if ($joinCount -ne 2) { throw "Expected two invitation warehouse joins; found $joinCount. No source changes made." }
$inviteText = $inviteText.Replace($joinOld, $joinNew)

$contextText = Get-Content -LiteralPath $context -Raw
$oldWarehouse = @'
    const warehouses = await prisma.$queryRawUnsafe<any[]>(
      `SELECT
        w.id,
        w."companyId",
        w.name,
        w.code,
        w.address,
        w.city,
        w.state,
        w.country,
        w."isActive" AS "isActive",
        w."createdAt"
       FROM public.warehouses w
       WHERE w."companyId" = $1
       ORDER BY w.name ASC`,
      row.companyId,
    );

    const normalizedWarehouses = warehouses.map((warehouse: any) => ({
'@
$newWarehouse = @'
    const role = String(row.role ?? "").trim().toUpperCase();
    const isWarehouseScopedRole = [
      "MANAGER",
      "OPERATOR",
      "WAREHOUSE_MANAGER",
      "PACKING_OPERATOR",
    ].includes(role);

    const warehouses = isWarehouseScopedRole
      ? await prisma.$queryRawUnsafe<any[]>(
          `SELECT
            w.id,
            w."companyId",
            w.name,
            w.code,
            w.address,
            w.city,
            w.state,
            w.country,
            w."isActive" AS "isActive",
            w."createdAt"
           FROM public.user_warehouse_assignments uwa
           INNER JOIN public.warehouses w
             ON w.id = uwa."warehouseId"
           WHERE uwa."userId" = $1
             AND w."companyId" = $2
             AND w."isActive" = TRUE
           ORDER BY w."createdAt" ASC, w.name ASC`,
          row.id,
          row.companyId,
        )
      : await prisma.$queryRawUnsafe<any[]>(
          `SELECT
            w.id,
            w."companyId",
            w.name,
            w.code,
            w.address,
            w.city,
            w.state,
            w.country,
            w."isActive" AS "isActive",
            w."createdAt"
           FROM public.warehouses w
           WHERE w."companyId" = $1
           ORDER BY w.name ASC`,
          row.companyId,
        );

    const normalizedWarehouses = warehouses.map((warehouse: any) => ({
'@
if (!$contextText.Contains($oldWarehouse)) { throw "Company-context warehouse query did not match expected source; no source changes made." }
$contextText = $contextText.Replace($oldWarehouse, $newWarehouse)

$identityText = Get-Content -LiteralPath $identity -Raw
$oldIdentityRole = '["MANAGER", "OPERATOR"].includes('
if (!$identityText.Contains($oldIdentityRole)) { throw "Identity role check missing; no source changes made." }
$identityText = $identityText.Replace($oldIdentityRole, '["MANAGER", "OPERATOR", "WAREHOUSE_MANAGER", "PACKING_OPERATOR"].includes(')

$invoiceText = Get-Content -LiteralPath $invoice -Raw
$invoiceText = $invoiceText.Replace('REFERENCES "Company"("id")', 'REFERENCES public.companies(id)')
if (!$invoiceText.Contains('REFERENCES public.companies(id)') -or $invoiceText.Contains('REFERENCES "Company"("id")')) {
  throw "Invoice FK verification failed; no source changes made."
}

$packageText = Get-Content -LiteralPath $package -Raw
$packageObject = $packageText | ConvertFrom-Json

if (!$packageObject.scripts.'test:identity-invitation') {
  $packageObject.scripts | Add-Member -NotePropertyName 'test:identity-invitation' -NotePropertyValue 'tsx scripts/identity-invitation.contract.ts'
  $packageText = $packageObject | ConvertTo-Json -Depth 100
}
# Write the complete, pre-validated patch.
[System.IO.File]::WriteAllText($roleModule, $roleSource, [System.Text.UTF8Encoding]::new($false))
New-Item -ItemType Directory -Path (Split-Path $testFile) -Force | Out-Null
[System.IO.File]::WriteAllText($testFile, $testSource, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($invitation, $inviteText, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($context, $contextText, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($identity, $identityText, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($invoice, $invoiceText, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($package, $packageText, [System.Text.UTF8Encoding]::new($false))

Write-Host "`n===== PATCH APPLIED =====" -ForegroundColor Green
Write-Host "Role mapping, warehouse scoping, cross-company join guard, invoice FK verification updated."

Write-Host "`n===== 1/5 ROLE CONTRACT TEST =====" -ForegroundColor Cyan
npm.cmd run test:identity-invitation
if ($LASTEXITCODE -ne 0) { throw "Role contract test failed." }

Write-Host "`n===== 2/5 TYPECHECK =====" -ForegroundColor Cyan
npm.cmd run typecheck
if ($LASTEXITCODE -ne 0) { throw "Typecheck failed." }

Write-Host "`n===== 3/5 PRISMA VALIDATE =====" -ForegroundColor Cyan
npx.cmd prisma validate
if ($LASTEXITCODE -ne 0) { throw "Prisma validation failed." }

Write-Host "`n===== 4/5 BUILD =====" -ForegroundColor Cyan
npm.cmd run build
if ($LASTEXITCODE -ne 0) { throw "Build failed." }

Write-Host "`n===== 5/5 DIFF CHECK =====" -ForegroundColor Cyan
git diff --check
if ($LASTEXITCODE -ne 0) { throw "git diff --check failed." }

Write-Host "`nALL LOCAL CHECKS PASSED. No database migrations or DB-writing integration tests were run." -ForegroundColor Green




