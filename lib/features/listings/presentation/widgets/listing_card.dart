import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/soft_card.dart';
import '../../domain/entities/listing.dart';
import '../providers/listings_providers.dart';
import 'listing_image_viewer.dart';

class ListingCard extends ConsumerStatefulWidget {
  const ListingCard({super.key, required this.listing, this.cartQuantity = 0});

  final Listing listing;

  /// How much of this listing is already in the user's cart, if any —
  /// shown as a small badge so they don't accidentally order it twice.
  final double cartQuantity;

  @override
  ConsumerState<ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends ConsumerState<ListingCard> {
  bool _isAdding = false;

  Future<void> _addToCart() async {
    setState(() => _isAdding = true);
    final result = await ref
        .read(listingsRepositoryProvider)
        .addToCart(widget.listing.id);
    if (!mounted) return;
    setState(() => _isAdding = false);

    result.fold((failure) => AppToast.show(context, message: failure.message), (
      _,
    ) {
      ref.invalidate(cartItemCountProvider);
      ref.invalidate(cartItemsProvider);
      AppToast.show(
        context,
        type: AppToastType.success,
        message: 'Dodano u korpu.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final colorScheme = Theme.of(context).colorScheme;

    return SoftCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: listing.imageUrls.isEmpty
                ? null
                : () => ListingImageViewer.open(
                    context,
                    imageUrls: listing.imageUrls,
                  ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: listing.imageUrls.isEmpty
                      ? Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.eco_outlined,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: listing.imageUrls.first,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 56,
                            height: 56,
                            color: colorScheme.primary.withValues(alpha: 0.08),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(
                                alpha: 0.08,
                              ),
                            ),
                            child: Icon(
                              Icons.eco_outlined,
                              color: colorScheme.primary,
                              size: 24,
                            ),
                          ),
                        ),
                ),
                if (listing.imageUrls.length > 1)
                  Positioned(
                    right: 3,
                    bottom: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library_outlined,
                            size: 10,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${listing.imageUrls.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        listing.title,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (listing.isOrganic)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.spa_outlined,
                          size: 16,
                          color: AppColors.seed,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${listing.sellerName} · ${listing.categoryName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                if (widget.cartQuantity > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_basket_outlined,
                          size: 12,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'U korpi: ${_formatQuantity(widget.cartQuantity)} ${listing.unit}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${listing.price.toStringAsFixed(2)} KM/${listing.unit}',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(color: colorScheme.primary),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                Icons.place_outlined,
                                size: 13,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                listing.cityName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (listing.pickupAvailable)
                                const _Tag(
                                  icon: Icons.storefront_outlined,
                                  label: 'Preuzimanje',
                                ),
                              if (listing.pickupAvailable &&
                                  listing.deliveryAvailable)
                                const SizedBox(width: 6),
                              if (listing.deliveryAvailable)
                                const _Tag(
                                  icon: Icons.local_shipping_outlined,
                                  label: 'Dostava',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: colorScheme.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _isAdding ? null : _addToCart,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: _isAdding
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : Icon(
                                  Icons.add,
                                  color: colorScheme.onPrimary,
                                  size: 20,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

String _formatQuantity(double quantity) {
  return quantity.truncateToDouble() == quantity
      ? quantity.toStringAsFixed(0)
      : quantity.toStringAsFixed(2);
}
