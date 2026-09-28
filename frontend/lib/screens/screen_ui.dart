import 'package:flutter/material.dart';

const ldNavy = Color(0xFF0F172A);
const ldBlue = Color(0xFF2563EB);
const ldCyan = Color(0xFF06B6D4);
const ldGreen = Color(0xFF16A34A);
const ldAmber = Color(0xFFF59E0B);
const ldRed = Color(0xFFDC2626);
const ldBg = Color(0xFFF8FAFC);
const ldBorder = Color(0xFFE2E8F0);
const ldMute = Color(0xFF64748B);

class LDPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;
  final Widget child;

  const LDPage({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ldBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 800;

          return SingleChildScrollView(
            padding: EdgeInsets.all(compact ? 16 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: ldNavy,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            subtitle,
                            style: const TextStyle(color: ldMute, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    if (!compact && action != null) action!,
                  ],
                ),
                if (compact && action != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, child: action!),
                ],
                const SizedBox(height: 24),
                child,
              ],
            ),
          );
        },
      ),
    );
  }
}

class LDCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const LDCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class LDStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? caption;

  const LDStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return LDCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: ldMute,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: ldNavy,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (caption != null)
                  Text(
                    caption!,
                    style: const TextStyle(color: ldMute, fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LDStatus extends StatelessWidget {
  final String text;
  final Color color;

  const LDStatus({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class LDSearch extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const LDSearch({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ldBorder),
        ),
      ),
    );
  }
}

class LDSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const LDSectionTitle({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ldNavy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: const TextStyle(color: ldMute, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class LDEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const LDEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return LDCard(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Icon(icon, size: 42, color: ldMute),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: ldNavy,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ldMute),
            ),
          ],
        ),
      ),
    );
  }
}

Widget ldButton(
  String label,
  IconData icon, {
  VoidCallback? onPressed,
  bool primary = true,
}) {
  return ElevatedButton.icon(
    onPressed: onPressed ?? () {},
    icon: Icon(icon, size: 18),
    label: Text(label),
    style: ElevatedButton.styleFrom(
      backgroundColor: primary ? ldBlue : Colors.white,
      foregroundColor: primary ? Colors.white : ldNavy,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: BorderSide(color: primary ? ldBlue : ldBorder),
      ),
    ),
  );
}

