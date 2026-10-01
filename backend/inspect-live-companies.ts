import { prisma } from "./src/config/prisma.js";

try {
  const rows = await prisma.$queryRawUnsafe(`
    SELECT
      id,
      name,
      code,
      plan,
      "isActive",
      "createdAt",
      "updatedAt"
    FROM "Company"
    ORDER BY "createdAt" DESC
  `);

  console.table(rows);
  console.log(`Company rows: ${rows.length}`);
} finally {
  await prisma.$disconnect();
}
