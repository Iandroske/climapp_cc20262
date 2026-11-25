import 'package:flutter/material.dart';

/// Widget dedicado para exibição do código do país acompanhado do emoji da bandeira.
class CountryBadgeWidget extends StatelessWidget {
  final String flagEmoji;
  final String countryCode;

  const CountryBadgeWidget({
    required this.flagEmoji,
    required this.countryCode,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Text(
            flagEmoji.isEmpty ? '🌍' : flagEmoji,
            style: const TextStyle(fontSize: 22),
          ),
          Text(
            countryCode.isEmpty ? 'BR' : countryCode,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
