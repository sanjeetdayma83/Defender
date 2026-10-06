import 'package:flutter/material.dart';

import '../../models/models.dart';

class PackCompleteSummaryScreen extends StatelessWidget {
  final Order? order;
  final String evidenceStatus;
  final Duration duration;

  const PackCompleteSummaryScreen({
    super.key,
    this.order,
    this.evidenceStatus = 'READY',
    this.duration = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final o = order;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(context),
              const SizedBox(height: 8),
              const Text(
                'Pack Complete Summary',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF071A46),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Review the verified packing record and evidence status.',
                style: TextStyle(color: Color(0xFF53698F), fontSize: 15),
              ),
              const SizedBox(height: 20),
              _success(),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 950;
                  final left = _details(o);
                  final right = _progress(o);

                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: left),
                        const SizedBox(width: 16),
                        Expanded(child: right),
                      ],
                    );
                  }

                  return Column(
                    children: [left, const SizedBox(height: 16), right],
                  );
                },
              ),
              const SizedBox(height: 16),
              _items(o),
              const SizedBox(height: 16),
              _evidence(context),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Go to Next Order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Scan & Pack'),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: () => _message(
            context,
            'Print summary requires the print integration.',
          ),
          icon: const Icon(Icons.print_outlined),
          label: const Text('Print Summary'),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: () =>
              _message(context, 'Report export will use the reports API.'),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Download Report'),
        ),
      ],
    );
  }

  Widget _success() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: Color(0xFF16A34A),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Packing Completed',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF166534),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'The summary is generated from the selected packing order. No demo values are inserted.',
                  style: TextStyle(color: Color(0xFF166534)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _details(Order? o) {
    return _panel(
      'Order Details',
      o == null
          ? const Text(
              'No order context was supplied. Open this screen after completing a packing session.',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          : Column(
              children: [
                _line('Order ID', o.orderId),
                _line('Marketplace', o.marketplace),
                _line('AWB', o.awb),
                _line('SKU', o.product.sku),
                _line('Product', o.product.name),
                _line('Duration', _fmt(duration)),
              ],
            ),
    );
  }

  Widget _progress(Order? o) {
    return _panel(
      'Packing Progress',
      Column(
        children: [
          SizedBox(
            width: 170,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(170, 170),
                  painter: _ProgressPainter(
                    o == null ? 0 : 1,
                    o?.quantity ?? 0,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      o == null ? '—' : '100%',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF071A46),
                      ),
                    ),
                    Text(
                      o == null ? 'No order' : '${o.quantity} expected',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _kpi(
                'Expected',
                o?.quantity.toString() ?? '—',
                const Color(0xFF0061FC),
              ),
              _kpi('Scanned', '1', const Color(0xFF16A34A)),
              _kpi('Evidence', evidenceStatus, const Color(0xFF7C3AED)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _items(Order? o) {
    return _panel(
      'Packed Items',
      o == null
          ? const LDEmptyLocal()
          : Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFF0061FC),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.product.sku,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF071A46),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        o.product.name,
                        style: const TextStyle(color: Color(0xFF53698F)),
                      ),
                      Text(
                        'Expected quantity: ${o.quantity}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Chip(label: Text('Matched')),
              ],
            ),
    );
  }

  Widget _evidence(BuildContext context) {
    return _panel(
      'Packing Evidence',
      Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.video_library_outlined,
              color: Color(0xFF0061FC),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Evidence status',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF071A46),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  evidenceStatus,
                  style: const TextStyle(color: Color(0xFF53698F)),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => _message(
              context,
              'Evidence detail opens from the evidence API.',
            ),
            child: const Text('View Evidence'),
          ),
        ],
      ),
    );
  }

  Widget _panel(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFDCE6F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF071A46),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF071A46),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpi(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
        ),
      ],
    );
  }

  String _fmt(Duration value) {
    if (value == Duration.zero) {
      return '—';
    }

    return '${value.inMinutes.toString().padLeft(2, '0')}:'
        '${(value.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class LDEmptyLocal extends StatelessWidget {
  const LDEmptyLocal({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'No packed item context is available.',
      style: TextStyle(color: Color(0xFF64748B)),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final int scanned;
  final int expected;

  _ProgressPainter(this.scanned, this.expected);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;

    final radius = (size.shortestSide - 20) / 2;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(center, radius, paint..color = const Color(0xFFE2E8F0));

    if (expected > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -1.5708,
        6.28318 * (scanned / expected).clamp(0, 1),
        false,
        paint..color = const Color(0xFF16A34A),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter oldDelegate) {
    return oldDelegate.scanned != scanned || oldDelegate.expected != expected;
  }
}
