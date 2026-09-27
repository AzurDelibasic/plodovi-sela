import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../../core/widgets/soft_card.dart';
import '../../../listings/presentation/providers/listings_providers.dart';
import '../../../listings/presentation/widgets/listing_card.dart';
import '../../domain/entities/seller_review.dart';
import '../providers/farms_providers.dart';

class FarmDetailScreen extends ConsumerWidget {
  const FarmDetailScreen({super.key, required this.sellerId});

  final String sellerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmAsync = ref.watch(farmProvider(sellerId));

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: 'Farma',
              leading: HeaderIconButton(
                icon: Icons.arrow_back,
                tooltip: 'Nazad',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: farmAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    const Center(child: Text('Farma nije pronađena.')),
                data: (farm) {
                  final colorScheme = Theme.of(context).colorScheme;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: colorScheme.primary.withValues(
                              alpha: 0.08,
                            ),
                            backgroundImage: farm.avatarUrl != null
                                ? NetworkImage(farm.avatarUrl!)
                                : null,
                            child: farm.avatarUrl == null
                                ? Icon(
                                    Icons.agriculture_outlined,
                                    color: colorScheme.primary,
                                    size: 34,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  farm.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                if (farm.cityName != null)
                                  Text(
                                    farm.cityName!,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 18,
                                      color: AppColors.secondarySeed,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      farm.reviewCount == 0
                                          ? 'Bez ocjena'
                                          : '${farm.avgRating.toStringAsFixed(1)} (${farm.reviewCount} ocjena)',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (farm.bio != null && farm.bio!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(farm.bio!),
                      ],
                      const SizedBox(height: 28),
                      Text(
                        'Aktivni oglasi',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _FarmListings(sellerId: sellerId),
                      const SizedBox(height: 28),
                      Text(
                        'Recenzije',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _FarmReviews(sellerId: sellerId),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmListings extends ConsumerWidget {
  const _FarmListings({required this.sellerId});

  final String sellerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(farmListingsProvider(sellerId));
    final cartQuantities = <String, double>{
      for (final item in ref.watch(cartItemsProvider).asData?.value ?? [])
        item.listingId: item.quantity,
    };

    return listingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const Text('Nije uspjelo učitavanje oglasa.'),
      data: (listings) {
        if (listings.isEmpty) {
          return const Text(
            'Ova farma trenutno nema aktivnih oglasa.',
            style: TextStyle(color: AppColors.textMuted),
          );
        }
        return Column(
          children: [
            for (final listing in listings)
              ListingCard(
                listing: listing,
                cartQuantity: cartQuantities[listing.id] ?? 0,
              ),
          ],
        );
      },
    );
  }
}

class _FarmReviews extends ConsumerWidget {
  const _FarmReviews({required this.sellerId});

  final String sellerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(farmReviewsProvider(sellerId));

    return reviewsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const Text('Nije uspjelo učitavanje recenzija.'),
      data: (reviews) {
        if (reviews.isEmpty) {
          return const Text(
            'Još nema recenzija za ovu farmu.',
            style: TextStyle(color: AppColors.textMuted),
          );
        }
        return Column(
          children: [for (final review in reviews) _ReviewTile(review: review)],
        );
      },
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final SellerReview review;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 16,
                    color: AppColors.secondarySeed,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(review.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.comment!),
          ],
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(date.day)}.${twoDigits(date.month)}.${date.year}';
}
