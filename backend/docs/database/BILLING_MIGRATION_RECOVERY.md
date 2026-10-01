# Billing Database Migration Recovery

## Verification Date

2026-09-30

## Current Database

The Neon PostgreSQL database was audited during Billing DB recovery.

Prisma version:
- prisma 7.10.0
- @prisma/client 7.10.0

## Verification

The recovered `prisma/schema.prisma` was validated successfully.

A Prisma schema diff against the live datasource returned:

    No difference detected.

Exit code:

    0

Therefore the current Prisma schema matches the live database schema.

## Existing Local Migrations

The repository currently contains these historical migrations:

- 20260926021320_initial_loss_defender_schema
- 20260926093106_add_platform_admin_role
- 20260927013958_add_plans_subscriptions_scan_wallet

## Billing Migrations Recorded in Neon

The following migrations are recorded in the database and completed successfully:

| Migration | Checksum |
|---|---|
| 20260928171029_add_billing_foundation | e1929f0cfe34bb127255bb97593054ac382b829e0dbfd41236218b8198231034 |
| 20260929024718_add_billing_webhook_events | 7d7cd69f74948920e399fb375c3b40af0117ea10c0e51980204c7695c69e91de |
| 20260929041741_add_storage_accounting | 5c9e302044936e551fd826804584aee1abfb2f2033bf4ee569ae00f79802e920 |
| 20260929042155_add_billing_profile | 18fcb1258a41db37574da31f689fa89175acdbe549fef3e38e814d966b167471 |
| 20260929042539_add_invoice_foundation | fbd4bc4b4f532c37235b1a3f7a38d3a4f707d24c3e3bf0ca2b916db3f5191a1c |
| 20260929091936_add_invoice_payment_unique | 8758100fd07313f3f01ae6b113b826ddbd7582f22f9c55b224b677db2d9cc68f |
| 20260929094738_add_invoice_sequence | ccfa552a716620fde1fd2ae7b0402a63798577d136b974ccf834845324c3d66e |

All seven records had:
- finished_at populated
- applied_steps_count = 1
- rolled_back_at = null
- logs = null

## Recovery Finding

The original SQL files for the seven Billing migrations were not recoverable from:
- reachable Git history
- unreachable Git commits
- unreachable Git blobs
- local recovery patches
- local recovery scripts

The historical migration names and checksums above are therefore preserved as database-history evidence, but the original SQL is not recreated or represented as historically authentic files.

## Baseline Decision

The current `prisma/schema.prisma` represents the verified complete database schema.

A new repository baseline may be created from this verified schema. It must not be executed against the existing database because the database already contains the corresponding objects and historical migration records.

## Safety Rule

Do not run:
- `prisma migrate reset`
- `prisma db push`
- historical Billing migrations against the existing database

without an explicit migration/recovery plan.
