import 'dart:convert';

import '../../models/models.dart';
import '../api/api_client.dart';
import '../api/api_config.dart';

class OrderService {
  final ApiClient _apiClient;

  OrderService({ApiClient? apiClient})
    : _apiClient = apiClient ?? const ApiClient();

  Future<Order?> findByBarcode(String barcode) async {
    final value = barcode.trim();

    if (value.isEmpty) return null;

    final response = await _apiClient.post(
      Uri.parse('${ApiConfig.baseUrl}/scan/lookup'),
      body: jsonEncode(<String, dynamic>{'barcode': value}),
    );

    Map<String, dynamic> decoded = <String, dynamic>{};
    try {
      final raw = jsonDecode(response.body);
      if (raw is Map<String, dynamic>) {
        decoded = raw;
      }
    } catch (_) {}

    if (response.statusCode == 404 || response.statusCode == 400) {
      return null;
    }

    if (response.statusCode == 409) {
      throw Exception(
        decoded['message']?.toString() ??
            'This SKU matches multiple pending orders. Scan the AWB.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        decoded['message']?.toString() ??
            'Scan lookup failed (${response.statusCode}).',
      );
    }

    if (decoded['success'] != true) {
      throw Exception(decoded['message']?.toString() ?? 'Scan lookup failed.');
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      return null;
    }

    // Backend returns HTTP 200 even when not found
    if (data['found'] == false) {
      final msg = data['message']?.toString();
      if (msg != null && msg.isNotEmpty) {
        throw Exception(msg);
      }
      return null;
    }

    final orderJson = data['order'];
    final shipmentJson = data['shipment'];
    final itemsJson = data['items'];

    if (orderJson is! Map || shipmentJson is! Map) {
      return null;
    }

    final order = Map<String, dynamic>.from(orderJson);
    final shipment = Map<String, dynamic>.from(shipmentJson);

    final items = itemsJson is List
        ? itemsJson
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];

    if (items.isEmpty) {
      throw Exception('Shipment was found, but no order item is attached.');
    }

    final first = items.first;
    final productJson = first['product'] is Map
        ? Map<String, dynamic>.from(first['product'] as Map)
        : <String, dynamic>{};
    final variantJson = first['variant'] is Map
        ? Map<String, dynamic>.from(first['variant'] as Map)
        : <String, dynamic>{};

    final sku =
        first['sku']?.toString() ??
        variantJson['sku']?.toString() ??
        productJson['sku']?.toString() ??
        '';

    final product = Product(
      sku: sku,
      name:
          first['productName']?.toString() ??
          productJson['name']?.toString() ??
          'Unknown Product',
      image: productJson['imageUrl']?.toString() ?? '',
      variant:
          variantJson['name']?.toString() ??
          variantJson['variantName']?.toString() ??
          'Standard',
      color: variantJson['color']?.toString() ?? 'Default',
    );

    return Order(
      awb: shipment['awb']?.toString() ?? value,
      orderId:
          order['externalOrderId']?.toString() ??
          order['marketplaceOrderId']?.toString() ??
          order['id']?.toString() ??
          value,
      marketplace: order['marketplace']?.toString() ?? 'OTHER',
      product: product,
      quantity: (first['quantity'] as num?)?.toInt() ?? 1,
      status: order['status']?.toString() ?? 'PENDING',
      evidenceExists: false,
    );
  }

  Future<List<Order>> getOrders({String? search, String? status}) async {
    final query = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (status != null && status.trim().isNotEmpty) {
      query['status'] = status.trim();
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/orders',
    ).replace(queryParameters: query.isEmpty ? null : query);

    final response = await _apiClient.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to load orders (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return const <Order>[];

    final rawData = decoded['data'];
    final rawOrders = rawData is List
        ? rawData
        : rawData is Map && rawData['orders'] is List
        ? rawData['orders']
        : const [];

    return (rawOrders as List)
        .whereType<Map>()
        .map(_mapOrder)
        .whereType<Order>()
        .toList();
  }

  Order? _mapOrder(Map raw) {
    final order = Map<String, dynamic>.from(raw);
    final shipments = order['shipments'];
    final items = order['items'];

    final shipment = shipments is List && shipments.isNotEmpty
        ? Map<String, dynamic>.from(shipments.first as Map)
        : <String, dynamic>{};

    final item = items is List && items.isNotEmpty
        ? Map<String, dynamic>.from(items.first as Map)
        : <String, dynamic>{};

    final product = item['product'] is Map
        ? Map<String, dynamic>.from(item['product'] as Map)
        : <String, dynamic>{};
    final variant = item['variant'] is Map
        ? Map<String, dynamic>.from(item['variant'] as Map)
        : <String, dynamic>{};

    final sku =
        variant['sku']?.toString() ??
        product['sku']?.toString() ??
        item['sku']?.toString() ??
        '';

    return Order(
      awb: shipment['awb']?.toString() ?? '',
      orderId:
          order['externalOrderId']?.toString() ?? order['id']?.toString() ?? '',
      marketplace: order['marketplace']?.toString() ?? 'OTHER',
      product: Product(
        sku: sku,
        name: product['name']?.toString() ?? 'Unknown Product',
        image: product['imageUrl']?.toString() ?? '',
        variant: variant['name']?.toString() ?? 'Standard',
        color: variant['color']?.toString() ?? 'Default',
      ),
      quantity: (item['quantity'] as num?)?.toInt() ?? 1,
      status: order['status']?.toString() ?? 'PENDING',
      evidenceExists: false,
    );
  }
}

