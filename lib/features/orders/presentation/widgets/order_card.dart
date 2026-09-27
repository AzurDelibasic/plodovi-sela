import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_toast.dart';
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
        return const Color(0xFFB6862C);
      case OrderStatus.confirmed:
        return const Color(0xFF1B4B91);
      case OrderStatus.ready:
        return const Color(0xFF6B3FA0);
      case OrderStatus.completed:
        return colorScheme.primary;
      case OrderStatus.cancelled:
        return colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(order.status, colorScheme);

    return Opacity(
      opacity: _isUpdating ? 0.6 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
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
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.counterpartName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
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
            const SizedBox(height: 8),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2)}x ${item.title}',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  order.fulfillmentType == 'delivery'
                      ? Icons.local_shipping_outlined
                      : Icons.storefront_outlined,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  order.fulfillmentType == 'delivery'
                      ? 'Dostava${order.deliveryAddress != null ? ' — ${order.deliveryAddress}' : ''}'
                      : 'Preuzimanje',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '${order.totalAmount.toStringAsFixed(2)} KM',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (_actions().isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (final action in _actions()) ...[
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

  List<Widget> _actions() {
    if (_isUpdating) return [];
    final status = widget.order.status;

    if (widget.asSeller) {
      switch (status) {
        case OrderStatus.pending:
          return [
            TextButton(
              onPressed: () => _setStatus('cancelled'),
              child: const Text('Otkaži'),
            ),
            FilledButton(
              onPressed: () => _setStatus('confirmed'),
              child: const Text('Potvrdi'),
            ),
          ];
        case OrderStatus.confirmed:
          return [
            FilledButton(
              onPressed: () => _setStatus('ready'),
              child: const Text('Spremno'),
            ),
          ];
        case OrderStatus.ready:
          return [
            FilledButton(
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
            onPressed: () => _setStatus('cancelled'),
            child: const Text('Otkaži narudžbu'),
          ),
        ];
      }
      return [];
    }
  }
}
