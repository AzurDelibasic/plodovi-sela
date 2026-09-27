import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_gradients.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/presentation/widgets/gradient_pill_button.dart';
import '../../domain/entities/cart_item.dart';
import '../providers/listings_providers.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  String _fulfillmentType = 'pickup';
  final _addressController = TextEditingController();
  bool _isCheckingOut = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _checkout() async {
    if (_fulfillmentType == 'delivery' &&
        _addressController.text.trim().isEmpty) {
      AppToast.show(context, message: 'Unesite adresu za dostavu.');
      return;
    }

    setState(() => _isCheckingOut = true);
    final result = await ref
        .read(listingsRepositoryProvider)
        .checkout(
          fulfillmentType: _fulfillmentType,
          deliveryAddress: _fulfillmentType == 'delivery'
              ? _addressController.text.trim()
              : null,
        );
    if (!mounted) return;
    setState(() => _isCheckingOut = false);

    result.fold((failure) => AppToast.show(context, message: failure.message), (
      orderIds,
    ) {
      ref.invalidate(cartItemsProvider);
      ref.invalidate(cartItemCountProvider);
      AppToast.show(
        context,
        type: AppToastType.success,
        message: orderIds.length > 1
            ? 'Kreirano ${orderIds.length} narudžbi.'
            : 'Narudžba je uspješno kreirana.',
      );
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartItemsProvider);

    return Scaffold(
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppGradients.primary),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 16, 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      Text(
                        'Korpa',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: cartAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Nije uspjelo učitavanje korpe.'),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () =>
                                    ref.invalidate(cartItemsProvider),
                                child: const Text('Pokušaj ponovo'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      data: (items) {
                        if (items.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.shopping_basket_outlined,
                                    size: 48,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('Korpa je prazna.'),
                                ],
                              ),
                            ),
                          );
                        }

                        final total = items.fold<double>(
                          0,
                          (sum, item) => sum + item.subtotal,
                        );
                        final canPickup = items.every((i) => i.pickupAvailable);
                        final canDeliver = items.every(
                          (i) => i.deliveryAvailable,
                        );

                        return Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  8,
                                ),
                                itemCount: items.length,
                                itemBuilder: (context, index) =>
                                    _CartItemTile(item: items[index]),
                              ),
                            ),
                            _CheckoutBar(
                              total: total,
                              canPickup: canPickup,
                              canDeliver: canDeliver,
                              fulfillmentType: _fulfillmentType,
                              addressController: _addressController,
                              isCheckingOut: _isCheckingOut,
                              onFulfillmentChanged: (value) =>
                                  setState(() => _fulfillmentType = value),
                              onCheckout: _checkout,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartItemTile extends ConsumerStatefulWidget {
  const _CartItemTile({required this.item});

  final CartItem item;

  @override
  ConsumerState<_CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends ConsumerState<_CartItemTile> {
  bool _isUpdating = false;

  Future<void> _changeQuantity(double newQuantity) async {
    setState(() => _isUpdating = true);
    final result = await ref
        .read(listingsRepositoryProvider)
        .updateCartItemQuantity(widget.item.listingId, newQuantity);
    if (!mounted) return;
    setState(() => _isUpdating = false);

    result.fold((failure) => AppToast.show(context, message: failure.message), (
      _,
    ) {
      ref.invalidate(cartItemsProvider);
      ref.invalidate(cartItemCountProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final colorScheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: _isUpdating ? 0.5 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.sellerName,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.subtotal.toStringAsFixed(2)} KM',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: _isUpdating
                  ? null
                  : () => _changeQuantity(item.quantity - 1),
            ),
            Text(
              '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2)} ${item.unit}',
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _isUpdating
                  ? null
                  : () => _changeQuantity(item.quantity + 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.total,
    required this.canPickup,
    required this.canDeliver,
    required this.fulfillmentType,
    required this.addressController,
    required this.isCheckingOut,
    required this.onFulfillmentChanged,
    required this.onCheckout,
  });

  final double total;
  final bool canPickup;
  final bool canDeliver;
  final String fulfillmentType;
  final TextEditingController addressController;
  final bool isCheckingOut;
  final ValueChanged<String> onFulfillmentChanged;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canPickup && canDeliver)
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'pickup', label: Text('Preuzimanje')),
                ButtonSegment(value: 'delivery', label: Text('Dostava')),
              ],
              selected: {fulfillmentType},
              onSelectionChanged: (selection) =>
                  onFulfillmentChanged(selection.first),
            )
          else
            Text(
              canDeliver ? 'Dostava' : 'Lično preuzimanje',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          if (fulfillmentType == 'delivery') ...[
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Adresa za dostavu',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ukupno',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '${total.toStringAsFixed(2)} KM',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GradientPillButton(
            label: 'Naruči',
            isLoading: isCheckingOut,
            onPressed: isCheckingOut ? null : onCheckout,
          ),
        ],
      ),
    );
  }
}
