import 'package:flutter/material.dart';
import '../screen_ui.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String query = '';

  final articles = const [
    [
      'How does Scan & Pack work?',
      'Scan a shipment barcode to identify the order and start packing verification.',
    ],
    [
      'Why did recording not start?',
      'Recording starts only after the scanned barcode resolves to a valid shipment.',
    ],
    [
      'Where is evidence stored?',
      'Completed recordings are uploaded to the configured cloud evidence storage.',
    ],
    [
      'How can I review a shipment?',
      'Open Evidence or Recordings and search using AWB, order ID or SKU.',
    ],
    [
      'What happens after packing?',
      'The packing session can be completed and the shipment/order status is updated.',
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final list = articles
        .where((a) => a.join(' ').toLowerCase().contains(query.toLowerCase()))
        .toList();

    return LDPage(
      title: 'Help & Support',
      subtitle: 'Guides and answers for everyday Loss Defender operations.',
      child: Column(
        children: [
          SizedBox(
            width: 520,
            child: LDSearch(
              hint: 'Search help articles...',
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          const SizedBox(height: 20),
          LDCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LDSectionTitle(
                  title: 'Frequently Asked Questions',
                  subtitle: 'Quick answers for warehouse operators',
                ),
                ...list.map(
                  (a) => ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      a[0],
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: ldNavy,
                      ),
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14, right: 12),
                          child: Text(
                            a[1],
                            style: const TextStyle(color: ldMute, height: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: LDCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.support_agent_rounded,
                        color: ldBlue,
                        size: 30,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Contact Support',
                        style: TextStyle(
                          color: ldNavy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Get help with your warehouse setup.',
                        style: TextStyle(color: ldMute),
                      ),
                      const SizedBox(height: 14),
                      ldButton(
                        'Contact Support',
                        Icons.mail_outline_rounded,
                        primary: false,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LDCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.menu_book_outlined,
                        color: ldCyan,
                        size: 30,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Documentation',
                        style: TextStyle(
                          color: ldNavy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Learn about packing, evidence and operations.',
                        style: TextStyle(color: ldMute),
                      ),
                      const SizedBox(height: 14),
                      ldButton(
                        'Open Docs',
                        Icons.open_in_new_rounded,
                        primary: false,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
