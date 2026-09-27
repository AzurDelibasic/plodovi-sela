import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../auth/domain/entities/app_role.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/listing.dart';
import '../providers/listings_providers.dart';
import '../widgets/filter_dropdown.dart';
import '../widgets/listing_card.dart';

/// Home screen shown after login. The gradient header carries the user's
/// identity/role and cart; the white sheet below hosts search, category
/// filters and the listings themselves.
class ListingsScreen extends ConsumerWidget {
  const ListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).asData?.value;
    final displayName = user?.fullName?.trim().isNotEmpty == true
        ? user!.fullName!.trim()
        : user?.email ?? '';
    final cartCount = ref.watch(cartItemCountProvider).asData?.value ?? 0;

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
                  padding: const EdgeInsets.fromLTRB(24, 16, 12, 20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.eco_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Zdravo, $displayName',
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            if (user != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  user.role.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.shopping_basket_outlined,
                              color: Colors.white,
                            ),
                            tooltip: 'Korpa',
                            onPressed: () => context.push(AppRoutes.cart),
                          ),
                          if (cartCount > 0)
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFB3261E),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$cartCount',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                        ),
                        tooltip: 'Odjava',
                        onPressed: () =>
                            ref.read(authRepositoryProvider).signOut(),
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
                    child: const _ListingsBody(),
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Pretraži oglase...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        _searchController.clear();
                        _query = '';
                      }),
                    ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
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
        const SizedBox(height: 8),
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
                      size: 48,
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                ).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.storefront_outlined,
                size: 48,
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
