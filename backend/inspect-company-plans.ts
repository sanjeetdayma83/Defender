import { prisma } from "./src/config/prisma.js";

try {
  const rows = await prisma.company.findMany({
    select: {
      id: true,
      companyName: true,
      plan: true,
      status: true,
    },
  });

  console.table(rows);
  console.log(`Company rows: ${rows.length}`);
} finally {
  await prisma.$disconnect();
}
