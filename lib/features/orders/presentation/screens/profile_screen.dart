import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../auth/domain/entities/app_role.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/order.dart';
import '../providers/orders_providers.dart';
import '../widgets/order_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).asData?.value;
    final displayName = user?.fullName?.trim().isNotEmpty == true
        ? user!.fullName!.trim()
        : user?.email ?? '';

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: displayName,
              subtitle: user?.role.label,
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.08),
                child: Icon(
                  Icons.person_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              actions: [
                HeaderIconButton(
                  icon: Icons.logout_rounded,
                  tooltip: 'Odjava',
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  Text(
                    'Moje narudžbe',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _OrdersList(provider: myPurchasesProvider, asSeller: false),
                  if (user?.role == AppRole.prodavac) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Primljene narudžbe',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _OrdersList(provider: mySalesProvider, asSeller: true),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersList extends ConsumerWidget {
  const _OrdersList({required this.provider, required this.asSeller});

  final FutureProvider<List<Order>> provider;
  final bool asSeller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(provider);

    return ordersAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nije uspjelo učitavanje narudžbi.'),
            TextButton(
              onPressed: () => ref.invalidate(provider),
              child: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      ),
      data: (orders) {
        if (orders.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              asSeller ? 'Još nema primljenih narudžbi.' : 'Još nema narudžbi.',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          );
        }
        return Column(
          children: [
            for (final order in orders)
              OrderCard(order: order, asSeller: asSeller),
          ],
        );
      },
    );
  }
}
