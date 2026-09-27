export interface Product {
  id?: string;
  sku: string;
  name: string;
  variant: string;
  color: string;
  image?: string | null;
}

export interface Order {
  id?: string;
  awb: string;
  orderId: string;
  marketplace: string;
  sku: string;
  quantity: number;
  status: string;
  evidenceExists: boolean;
  product: Product;
  shipmentId?: string;
  shipmentStatus?: string;
  carrier?: string | null;
  createdAt?: string;
  updatedAt?: string;
}

export interface OrderListFilters {
  search?: string;
  status?: string;
  marketplace?: string;
  limit?: number;
  offset?: number;
}
