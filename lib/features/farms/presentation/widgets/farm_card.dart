import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/soft_card.dart';
import '../../domain/entities/farm.dart';

class FarmCard extends StatelessWidget {
  const FarmCard({super.key, required this.farm, required this.onTap});

  final Farm farm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SoftCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.08),
            backgroundImage: farm.avatarUrl != null
                ? CachedNetworkImageProvider(farm.avatarUrl!)
                : null,
            child: farm.avatarUrl == null
                ? Icon(
                    Icons.agriculture_outlined,
                    color: colorScheme.primary,
                    size: 24,
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  farm.name,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (farm.cityName != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 13,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        farm.cityName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.secondarySeed,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      farm.reviewCount == 0
                          ? 'Bez ocjena'
                          : '${farm.avgRating.toStringAsFixed(1)} (${farm.reviewCount})',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
