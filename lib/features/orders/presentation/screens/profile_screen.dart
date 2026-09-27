import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../../core/widgets/soft_card.dart';
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
                backgroundImage: user?.avatarUrl != null
                    ? CachedNetworkImageProvider(user!.avatarUrl!)
                    : null,
                child: user?.avatarUrl == null
                    ? Icon(
                        Icons.person_outline,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
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
                    'Izgled aplikacije',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  const _ThemeModeSelector(),
                  const SizedBox(height: 24),
                  if (user?.role == AppRole.prodavac) ...[
                    SoftCard(
                      onTap: () => context.push(AppRoutes.editProfile),
                      child: Row(
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            color: context.surfaceColors.textMuted,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(child: Text('Uredi profil farme')),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: context.surfaceColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
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
              style: TextStyle(color: context.surfaceColors.textMuted),
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

class _ThemeModeSelector extends ConsumerWidget {
  const _ThemeModeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(
            value: ThemeMode.light,
            icon: Icon(Icons.light_mode_outlined, size: 18),
            label: Text('Svijetla'),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            icon: Icon(Icons.dark_mode_outlined, size: 18),
            label: Text('Tamna'),
          ),
          ButtonSegment(
            value: ThemeMode.system,
            icon: Icon(Icons.smartphone_outlined, size: 18),
            label: Text('Sistem'),
          ),
        ],
        selected: {themeMode},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => ref
            .read(themeModeProvider.notifier)
            .setThemeMode(selection.first),
      ),
    );
  }
}
