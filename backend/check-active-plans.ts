import { prisma } from "./src/config/prisma.js";

try {
  const plans = await prisma.plan.findMany({
    where: {
      isActive: true,
    },
    select: {
      id: true,
      code: true,
      name: true,
      monthlyPrice: true,
      yearlyPrice: true,
      pricePaise: true,
      gstPercent: true,
      validityMonths: true,
    },
  });

  console.table(plans);
} finally {
  await prisma.$disconnect();
}
