import { prisma } from "./src/config/prisma.js";
import { billingContextService } from "./src/services/billing/billing-context.service.js";

const companyId = "839ed240-e938-49fb-ae9f-7462084ea7a1";

try {
  const result = await billingContextService.getCompanyBillingContext(companyId);

  console.dir(result, { depth: null });
} finally {
  await prisma.$disconnect();
}
