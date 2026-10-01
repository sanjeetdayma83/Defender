import "dotenv/config";
import { PrismaClient } from "../src/generated/prisma/index.js";

const prisma = new PrismaClient();

async function main() {
  const tables = await prisma.$queryRawUnsafe<any[]>(`
    SELECT
      table_schema,
      table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_type = 'BASE TABLE'
    ORDER BY table_name;
  `);

  console.log("\\n===== LIVE TABLES =====");
  console.table(tables);

  for (const table of tables) {
    const columns = await prisma.$queryRawUnsafe<any[]>(`
      SELECT
        ordinal_position,
        column_name,
        data_type,
        udt_name,
        is_nullable,
        column_default
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = '${table.table_name.replace(/'/g, "''")}'
      ORDER BY ordinal_position;
    `);

    console.log(`\\n===== ${table.table_name} =====`);
    console.table(columns);
  }
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

