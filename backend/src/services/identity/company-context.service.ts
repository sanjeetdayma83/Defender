import { prisma } from "../../config/prisma.js";

export class CompanyContextService {
  async getUser(firebaseUid: string) {
    const user = await prisma.user.findUnique({
      where: {
        firebaseUid,
      },
      include: {
        company: true,
      },
    });

    if (!user) {
      throw new Error("USER_NOT_FOUND");
    }

    if (!user.isActive) {
      throw new Error("USER_INACTIVE");
    }

    if (!user.company.isActive) {
      throw new Error("COMPANY_INACTIVE");
    }

    return user;
  }

  async getCompany(firebaseUid: string) {
    const user = await this.getUser(firebaseUid);

    return {
      user,
      company: user.company,
    };
  }
}

export const companyContextService = new CompanyContextService();
