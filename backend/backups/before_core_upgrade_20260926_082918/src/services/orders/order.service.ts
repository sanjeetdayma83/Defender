import { MockOrderProvider } from "./mock-order.provider.js";

const provider = new MockOrderProvider();

export class OrderService {
  async find(identifier: string) {
    return provider.findByIdentifier(identifier);
  }

  async list() {
    return provider.list();
  }
}
