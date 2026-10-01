import { prisma } from "./src/config/prisma.js";

const rows = await prisma.$queryRawUnsafe(`
  SELECT
    table_name
  FROM information_schema.tables
  WHERE table_schema = 'public'
  ORDER BY table_name
`);

console.log(JSON.stringify(rows, null, 2));

await prisma.$disconnect();
