import 'package:flutter/material.dart';
import '../screen_ui.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String query = '';

  final products = const [
    ['97-U1YR-N3GW', 'Demo Product', 'General', '42', 'Active'],
    ['PC-TWISTER-001', 'PC Twister Demo', 'Blue', '18', 'Active'],
    [
      'DG-LT-S',
      'NOVELTY Foldable Height Adjustable White Board',
      'Standard',
      '27',
      'Active',
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final list = products
        .where((p) => p.join(' ').toLowerCase().contains(query.toLowerCase()))
        .toList();

    return LDPage(
      title: 'Products',
      subtitle: 'Manage SKUs, variants, inventory and barcode mappings.',
      action: ldButton('Add Product', Icons.add_rounded),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 380,
                child: LDSearch(
                  hint: 'Search SKU or product...',
                  onChanged: (v) => setState(() => query = v),
                ),
              ),
              ldButton('Import', Icons.upload_file_outlined, primary: false),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: LDStat(
                  label: 'Products',
                  value: '3',
                  icon: Icons.category_outlined,
                  color: ldBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LDStat(
                  label: 'Active SKUs',
                  value: '3',
                  icon: Icons.qr_code_2_rounded,
                  color: ldCyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LDStat(
                  label: 'Low Stock',
                  value: '0',
                  icon: Icons.warning_amber_rounded,
                  color: ldAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (list.isEmpty)
            const LDEmpty(
              icon: Icons.inventory_2_outlined,
              title: 'No products found',
              subtitle: 'No products match your search.',
            )
          else
            LDCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(18),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: LDSectionTitle(
                        title: 'Product Catalogue',
                        subtitle: 'SKU and inventory overview',
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ...list.map(
                    (p) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 6,
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: ldBlue.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: ldBlue,
                        ),
                      ),
                      title: Text(
                        p[1],
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: ldNavy,
                        ),
                      ),
                      subtitle: Text(
                        '${p[0]} • Variant: ${p[2]}',
                        style: const TextStyle(color: ldMute),
                      ),
                      trailing: Wrap(
                        spacing: 16,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${p[3]} units',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          LDStatus(text: p[4], color: ldGreen),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: ldMute,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
