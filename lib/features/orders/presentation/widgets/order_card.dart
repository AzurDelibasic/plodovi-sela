import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/soft_card.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_status.dart';
import '../providers/orders_providers.dart';

/// Shows one order. [asSeller] controls which action buttons make sense —
/// a seller advances the order through its lifecycle, a buyer can only
/// cancel while it's still pending.
class OrderCard extends ConsumerStatefulWidget {
  const OrderCard({super.key, required this.order, required this.asSeller});

  final Order order;
  final bool asSeller;

  @override
  ConsumerState<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<OrderCard> {
  bool _isUpdating = false;

  Future<void> _setStatus(String status) async {
    setState(() => _isUpdating = true);
    final result = await ref
        .read(ordersRepositoryProvider)
        .updateOrderStatus(widget.order.id, status);
    if (!mounted) return;
    setState(() => _isUpdating = false);

    result.fold((failure) => AppToast.show(context, message: failure.message), (
      _,
    ) {
      ref.invalidate(myPurchasesProvider);
      ref.invalidate(mySalesProvider);
    });
  }

  Color _statusColor(OrderStatus status, ColorScheme colorScheme) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.statusPending;
      case OrderStatus.confirmed:
        return AppColors.statusConfirmed;
      case OrderStatus.ready:
        return AppColors.statusReady;
      case OrderStatus.completed:
        return colorScheme.primary;
      case OrderStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(order.status, colorScheme);
    final actions = _actions();

    return Opacity(
      opacity: _isUpdating ? 0.6 : 1,
      child: SoftCard(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.asSeller
                      ? Icons.person_outline
                      : Icons.storefront_outlined,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.counterpartName,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2)}x ${item.title}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  order.fulfillmentType == 'delivery'
                      ? Icons.local_shipping_outlined
                      : Icons.storefront_outlined,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.fulfillmentType == 'delivery'
                        ? 'Dostava${order.deliveryAddress != null ? ' — ${order.deliveryAddress}' : ''}'
                        : 'Preuzimanje',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${order.totalAmount.toStringAsFixed(2)} KM',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: colorScheme.primary),
                ),
              ],
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (final action in actions) ...[
                    action,
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static final _compactButtonStyle = FilledButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
  static final _compactTextButtonStyle = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  List<Widget> _actions() {
    if (_isUpdating) return [];
    final status = widget.order.status;

    if (widget.asSeller) {
      switch (status) {
        case OrderStatus.pending:
          return [
            TextButton(
              style: _compactTextButtonStyle,
              onPressed: () => _setStatus('cancelled'),
              child: const Text('Otkaži'),
            ),
            FilledButton(
              style: _compactButtonStyle,
              onPressed: () => _setStatus('confirmed'),
              child: const Text('Potvrdi'),
            ),
          ];
        case OrderStatus.confirmed:
          return [
            FilledButton(
              style: _compactButtonStyle,
              onPressed: () => _setStatus('ready'),
              child: const Text('Spremno'),
            ),
          ];
        case OrderStatus.ready:
          return [
            FilledButton(
              style: _compactButtonStyle,
              onPressed: () => _setStatus('completed'),
              child: const Text('Završi'),
            ),
          ];
        case OrderStatus.completed:
        case OrderStatus.cancelled:
          return [];
      }
    } else {
      if (status == OrderStatus.pending) {
        return [
          TextButton(
            style: _compactTextButtonStyle,
            onPressed: () => _setStatus('cancelled'),
            child: const Text('Otkaži narudžbu'),
          ),
        ];
      }
      return [];
    }
  }
}
