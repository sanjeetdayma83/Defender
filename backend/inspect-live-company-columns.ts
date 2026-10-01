import { prisma } from "./src/config/prisma.js";

try {
  const rows = await prisma.$queryRawUnsafe(`
    SELECT
      column_name,
      data_type,
      is_nullable,
      column_default
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'Company'
    ORDER BY ordinal_position
  `);

  console.table(rows);
} finally {
  await prisma.$disconnect();
}
