import { prisma } from "../src/config/prisma.js";

try {
  const rows = await prisma.$queryRaw<Array<{
    migration_name: string;
    started_at: Date | null;
    finished_at: Date | null;
    rolled_back_at: Date | null;
    logs: string | null;
  }>>`
    SELECT migration_name, started_at, finished_at, rolled_back_at, logs
    FROM public._prisma_migrations
    ORDER BY started_at, migration_name
  `;

  for (const row of rows) {
    console.log(JSON.stringify(row));
  }

  console.log(`TOTAL MIGRATION RECORDS: ${rows.length}`);
} finally {
  await prisma.$disconnect();
}
