import { prisma } from "./src/config/prisma.js";

const rows = await prisma.$queryRawUnsafe(`
  SELECT
    migration_name,
    started_at,
    finished_at,
    rolled_back_at,
    applied_steps_count
  FROM "_prisma_migrations"
  ORDER BY started_at
`);

console.log(JSON.stringify(rows, null, 2));

await prisma.$disconnect();
