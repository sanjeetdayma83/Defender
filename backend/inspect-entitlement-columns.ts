import { prisma } from "./src/config/prisma.js";

async function main() {
  const tables = ["Company", "Order", "Recording", "Evidence"];

  for (const table of tables) {
    console.log(`\n===== ${table} =====`);

    const rows = await prisma.$queryRawUnsafe<any[]>(
      `
      SELECT
        column_name,
        data_type
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = $1
      ORDER BY ordinal_position
      `,
      table,
    );

    console.table(rows);
  }
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
