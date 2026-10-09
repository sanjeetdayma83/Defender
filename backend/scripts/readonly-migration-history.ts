import { prisma } from "../src/config/prisma.js";

async function main() {
  const rows = await prisma.$queryRawUnsafe<Array<{
    migration_name: string;
    finished_at: Date | null;
    rolled_back_at: Date | null;
    applied_steps_count: number;
  }>>(`
    SELECT migration_name, finished_at, rolled_back_at, applied_steps_count
    FROM public."_prisma_migrations"
    ORDER BY started_at
  `);

  console.log(JSON.stringify(rows, null, 2));
}

main()
  .catch(error => {
    console.error("Migration history read failed:", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
