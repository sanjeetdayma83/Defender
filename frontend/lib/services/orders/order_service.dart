import '../../models/models.dart';

class OrderService {
  static final List<Product> _products = <Product>[
    Product(
      sku: '97-U1YR-N3GW',
      name: 'Warehouse Product',
      image: '',
      variant: 'Standard',
      color: 'Default',
    ),
    Product(
      sku: 'PC-TWISTER-001',
      name: 'Twister Product',
      image: '',
      variant: 'Standard',
      color: 'Blue',
    ),
    Product(
      sku: 'DG-LT-S',
      name: 'NOVELTY Foldable Height Adjustable White Board',
      image: '',
      variant: 'Standard',
      color: 'White',
    ),
  ];

  static final List<Order> _orders = <Order>[
    Order(
      awb: '368275770371',
      orderId: '406-3151945-3281902',
      marketplace: 'Amazon',
      product: _products[0],
      quantity: 1,
      status: 'Ready to Pack',
      evidenceExists: false,
    ),
    Order(
      awb: '1490841263428112',
      orderId: '331724360573683072_1',
      marketplace: 'Delhivery',
      product: _products[1],
      quantity: 1,
      status: 'Ready to Pack',
      evidenceExists: false,
    ),
    Order(
      awb: 'FMPP3767030215',
      orderId: 'FLIPKART-DEMO-001',
      marketplace: 'Flipkart',
      product: _products[2],
      quantity: 1,
      status: 'Ready to Pack',
      evidenceExists: false,
    ),
  ];

  /// Public read-only access for UI screens.
  static List<Order> get orders => List<Order>.unmodifiable(_orders);

  Future<Order?> findByBarcode(String barcode) async {
    final String value = barcode.trim();

    if (value.isEmpty) {
      return null;
    }

    for (final Order order in _orders) {
      if (order.awb.toLowerCase() == value.toLowerCase() ||
          order.orderId.toLowerCase() == value.toLowerCase()) {
        return order;
      }
    }

    for (final Product product in _products) {
      if (product.sku.toLowerCase() == value.toLowerCase()) {
        for (final Order order in _orders) {
          if (order.product.sku.toLowerCase() == product.sku.toLowerCase()) {
            return order;
          }
        }
      }
    }

    return null;
  }

  Future<List<Order>> getOrders() async {
    return List<Order>.unmodifiable(_orders);
  }

  Future<List<Product>> getProducts() async {
    return List<Product>.unmodifiable(_products);
  }
}
