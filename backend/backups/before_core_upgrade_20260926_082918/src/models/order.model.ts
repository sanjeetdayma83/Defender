export interface Product {
  sku: string;
  name: string;
  variant: string;
  color: string;
}

export interface Order {
  awb: string;
  orderId: string;
  marketplace: string;
  sku: string;
  quantity: number;
  status: string;
  evidenceExists: boolean;
}
