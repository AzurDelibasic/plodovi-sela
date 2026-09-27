import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_toast.dart';
import '../../domain/entities/listing.dart';
import '../providers/listings_providers.dart';

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

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.eco_outlined,
              color: colorScheme.primary,
              size: 28,
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
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
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
                          color: Color(0xFF2E6B3E),
                        ),
                      ),
                  ],
                ),
                if (widget.cartQuantity > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
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
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        listing.sellerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  listing.categoryName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
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
                                    ?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                Icons.place_outlined,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                listing.cityName,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
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
