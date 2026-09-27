import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/evidence/evidence_api_service.dart';
import '../../services/orders/order_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/evidence_video_player.dart';

class EvidenceDetailScreen extends StatefulWidget {
  final String awb;

  const EvidenceDetailScreen({super.key, required this.awb});

  @override
  State<EvidenceDetailScreen> createState() => _EvidenceDetailScreenState();
}

class _EvidenceDetailScreenState extends State<EvidenceDetailScreen> {
  final EvidenceApiService _evidenceApi = const EvidenceApiService();

  final OrderService _orderService = OrderService();

  EvidenceData? _evidence;
  Order? _order;

  bool _loading = true;

  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        _evidenceApi.getEvidence(widget.awb),
        _orderService.findByBarcode(widget.awb),
      ]);

      final evidence = results[0] as EvidenceData;

      final order = results[1] as Order?;

      if (!mounted) {
        return;
      }

      setState(() {
        _evidence = evidence;
        _order = order;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LDColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: LDColors.text),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Row(
          children: [
            const Text(
              'Evidence Viewer',
              style: TextStyle(
                color: LDColors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 12),
            _verifiedBadge(),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                widget.awb,
                style: const TextStyle(
                  color: LDColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Unable to load evidence',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: LDColors.muted),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final evidence = _evidence;

    if (evidence == null) {
      return const Center(child: Text('Evidence data unavailable.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1050;

        final videoSection = _buildVideos(evidence);

        final rightColumn = Column(
          children: [
            _buildOrderDetails(),
            const SizedBox(height: 18),
            _buildPhotos(evidence),
          ],
        );

        if (desktop) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: videoSection),
                const SizedBox(width: 20),
                Expanded(flex: 5, child: rightColumn),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [videoSection, const SizedBox(height: 18), rightColumn],
          ),
        );
      },
    );
  }

  Widget _buildVideos(EvidenceData evidence) {
    final videos = evidence.recordings.where((media) => media.isVideo).toList();

    return _sectionCard(
      title: 'Packing Video',
      icon: Icons.videocam_rounded,
      count: '${videos.length} videos',
      child: videos.isEmpty
          ? _emptyMedia(
              icon: Icons.videocam_off_outlined,
              text: 'No packing video stored',
            )
          : Column(
              children: [
                for (var index = 0; index < videos.length; index++) ...[
                  _videoCard(videos[index], index + 1),
                  if (index != videos.length - 1) const SizedBox(height: 14),
                ],
              ],
            ),
    );
  }

  Widget _videoCard(EvidenceMedia media, int index) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF050B16),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: EvidenceVideoPlayer(
              key: ValueKey(media.signedUrl),
              url: media.signedUrl,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: LDColors.blue.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    media.filename,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  media.formattedSize,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .65),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    final order = _order;

    return _sectionCard(
      title: 'Order Details',
      icon: Icons.description_rounded,
      count: 'VERIFIED',
      child: order == null
          ? const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Order details are not available.',
                style: TextStyle(color: LDColors.muted),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 650 ? 3 : 2;

                final items = [
                  _info('AWB', order.awb),
                  _info('Order ID', order.orderId),
                  _info('Marketplace', order.marketplace),
                  _info('SKU', order.product.sku),
                  _info('Product', order.product.name, maxLines: 3),
                  _info('Quantity', order.quantity.toString()),
                  _info('Variant', order.product.variant),
                  _info('Color', order.product.color),
                  _info(
                    'Status',
                    order.status,
                    valueColor: Colors.green,
                    leadingDot: true,
                  ),
                ];

                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 22,
                  mainAxisSpacing: 20,
                  childAspectRatio: 3.2,
                  children: items,
                );
              },
            ),
    );
  }

  Widget _buildPhotos(EvidenceData evidence) {
    final photos = evidence.photos.where((media) => media.isPhoto).toList();

    return _sectionCard(
      title: 'Packing Photos',
      icon: Icons.image_rounded,
      count: '${photos.length} photos',
      child: photos.isEmpty
          ? _emptyMedia(
              icon: Icons.image_not_supported_outlined,
              text: 'No packing photos stored',
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return _photoTile(photos[index]);
              },
            ),
    );
  }

  Widget _photoTile(EvidenceMedia media) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (_) {
            return Dialog(
              child: InteractiveViewer(
                minScale: .5,
                maxScale: 4,
                child: Image.network(
                  media.signedUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Text('Unable to load photo.'),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          media.signedUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: LDColors.background,
              alignment: Alignment.center,
              child: const Icon(
                Icons.broken_image_outlined,
                color: LDColors.muted,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required String count,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LDColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: LDColors.blue.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: LDColors.blue, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: LDColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                count,
                style: const TextStyle(
                  color: LDColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _emptyMedia({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: LDColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LDColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: LDColors.muted),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              color: LDColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(
    String label,
    String value, {
    Color? valueColor,
    bool leadingDot = false,
    int maxLines = 2,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: LDColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leadingDot)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 6, top: 5),
                decoration: BoxDecoration(
                  color: valueColor ?? Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            Expanded(
              child: Text(
                value,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: valueColor ?? LDColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _verifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: Colors.green, size: 16),
          SizedBox(width: 5),
          Text(
            'VERIFIED',
            style: TextStyle(
              color: Colors.green,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
