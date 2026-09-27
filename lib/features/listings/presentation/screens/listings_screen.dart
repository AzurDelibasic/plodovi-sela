import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/listing.dart';
import '../providers/listings_providers.dart';
import '../widgets/filter_dropdown.dart';
import '../widgets/listing_card.dart';

/// Home screen shown after login: search + filters over the active
/// listings feed.
class ListingsScreen extends ConsumerWidget {
  const ListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).asData?.value;
    final firstName = user?.fullName?.trim().isNotEmpty == true
        ? user!.fullName!.trim().split(' ').first
        : null;
    final cartCount = ref.watch(cartItemCountProvider).asData?.value ?? 0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: 'Plodovi sela',
              subtitle: firstName != null ? 'Zdravo, $firstName' : null,
              actions: [
                HeaderIconButton(
                  icon: Icons.shopping_basket_outlined,
                  tooltip: 'Korpa',
                  badgeCount: cartCount,
                  onPressed: () => context.push(AppRoutes.cart),
                ),
              ],
            ),
            const Expanded(child: _ListingsBody()),
          ],
        ),
      ),
    );
  }
}

class _ListingsBody extends ConsumerStatefulWidget {
  const _ListingsBody();

  @override
  ConsumerState<_ListingsBody> createState() => _ListingsBodyState();
}

class _ListingsBodyState extends ConsumerState<_ListingsBody> {
  final _searchController = TextEditingController();
  String _query = '';
  int? _selectedCategoryId;
  String? _selectedCityName;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Listing> _applyFilters(List<Listing> listings) {
    final query = _query.trim().toLowerCase();
    return listings.where((listing) {
      final matchesQuery =
          query.isEmpty || listing.title.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategoryId == null ||
          listing.categoryId == _selectedCategoryId;
      final matchesCity =
          _selectedCityName == null || listing.cityName == _selectedCityName;
      return matchesQuery && matchesCategory && matchesCity;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(activeListingsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final citiesAsync = ref.watch(citiesProvider);
    final cartQuantities = <String, double>{
      for (final item in ref.watch(cartItemsProvider).asData?.value ?? [])
        item.listingId: item.quantity,
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Pretraži oglase...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() {
                        _searchController.clear();
                        _query = '';
                      }),
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: categoriesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (categories) => FilterDropdown<int?>(
                    label: 'Kategorija',
                    icon: Icons.restaurant_menu_outlined,
                    value: _selectedCategoryId,
                    allLabel: 'Sve kategorije',
                    items: [
                      for (final category in categories)
                        (value: category.id, label: category.name),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedCategoryId = value),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: citiesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (cities) => FilterDropdown<String?>(
                    label: 'Grad',
                    icon: Icons.place_outlined,
                    value: _selectedCityName,
                    allLabel: 'Svi gradovi',
                    items: [
                      for (final city in cities)
                        (value: city.name, label: city.name),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedCityName = value),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: listingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 40,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nije uspjelo učitavanje oglasa.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => ref.invalidate(activeListingsProvider),
                      child: const Text('Pokušaj ponovo'),
                    ),
                  ],
                ),
              ),
            ),
            data: (listings) {
              final filtered = _applyFilters(listings);

              if (listings.isEmpty) return const _EmptyListingsState();
              if (filtered.isEmpty) {
                return const _EmptyListingsState(
                  message: 'Nema oglasa koji odgovaraju pretrazi.',
                );
              }

              return RefreshIndicator(
                onRefresh: () => ref.refresh(activeListingsProvider.future),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => ListingCard(
                    listing: filtered[index],
                    cartQuantity: cartQuantities[filtered[index].id] ?? 0,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyListingsState extends StatelessWidget {
  const _EmptyListingsState({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.storefront_outlined,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message == null ? 'Još nema oglasa' : 'Nema rezultata',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message ??
                  'Ovdje će se pojaviti domaće namirnice iz tvoje okoline čim '
                      'prodavci počnu da ih objavljuju.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
