import 'package:flutter/material.dart';
import '../screen_ui.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LDPage(
      title: 'Analytics',
      subtitle:
          'Operational intelligence across packing and evidence workflows.',
      action: ldButton('Export Report', Icons.download_outlined),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 1000
                  ? 4
                  : c.maxWidth > 650
                  ? 2
                  : 1;
              return GridView.count(
                crossAxisCount: cols,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  LDStat(
                    label: 'Orders Processed',
                    value: '128',
                    icon: Icons.inventory_2_outlined,
                    color: ldBlue,
                  ),
                  LDStat(
                    label: 'Packing Sessions',
                    value: '121',
                    icon: Icons.local_shipping_outlined,
                    color: ldCyan,
                  ),
                  LDStat(
                    label: 'Evidence Verified',
                    value: '117',
                    icon: Icons.verified_outlined,
                    color: ldGreen,
                  ),
                  LDStat(
                    label: 'Exceptions',
                    value: '4',
                    icon: Icons.warning_amber_rounded,
                    color: ldAmber,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: LDCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LDSectionTitle(
                        title: 'Packing Performance',
                        subtitle: 'Last operational cycle',
                      ),
                      const SizedBox(height: 16),
                      ...[
                        ['Orders scanned', .86],
                        ['Valid scans', .94],
                        ['Evidence captured', .91],
                        ['Verified sessions', .88],
                      ].map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item[0] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${((item[1] as double) * 100).round()}%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: ldBlue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 7),
                              LinearProgressIndicator(
                                value: item[1] as double,
                                minHeight: 7,
                                borderRadius: BorderRadius.circular(10),
                                backgroundColor: ldBorder,
                                color: ldBlue,
                              ),
                            ],
                          ),
                        ),
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
                      const LDSectionTitle(
                        title: 'Shipment Status',
                        subtitle: 'Current distribution',
                      ),
                      const SizedBox(height: 10),
                      _status('Packed', '72', ldGreen),
                      _status('Packing', '18', ldAmber),
                      _status('Ready', '29', ldBlue),
                      _status('Exception', '4', ldRed),
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

  Widget _status(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, color: ldNavy),
          ),
        ],
      ),
    );
  }
}
