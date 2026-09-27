class Product {
  final String sku;
  final String name;
  final String image;
  final String variant;
  final String color;

  const Product({
    required this.sku,
    required this.name,
    required this.image,
    required this.variant,
    required this.color,
  });
}

class Order {
  final String awb;
  final String orderId;
  final String marketplace;
  final Product product;
  final int quantity;
  final String status;
  final bool evidenceExists;

  const Order({
    required this.awb,
    required this.orderId,
    required this.marketplace,
    required this.product,
    required this.quantity,
    required this.status,
    required this.evidenceExists,
  });
}

class EvidenceRecord {
  final String id;
  final String awb;
  final String sku;
  final DateTime createdAt;
  final Duration duration;
  final String status;

  const EvidenceRecord({
    required this.id,
    required this.awb,
    required this.sku,
    required this.createdAt,
    required this.duration,
    required this.status,
  });
}
