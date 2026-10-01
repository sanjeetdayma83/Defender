import { prisma } from "./src/config/prisma.js";

try {
  const rows = await prisma.$queryRawUnsafe(`
    SELECT *
    FROM "Company"
    ORDER BY "createdAt" DESC
    LIMIT 20
  `);

  console.dir(rows, { depth: null });
} finally {
  await prisma.$disconnect();
}
