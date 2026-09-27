import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_gradients.dart';
import '../providers/farms_providers.dart';
import '../widgets/farm_card.dart';

/// Directory of sellers ("farme"). Same visual language as the listings
/// home screen: gradient header, rounded white sheet below.
class FarmsScreen extends ConsumerWidget {
  const FarmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmsAsync = ref.watch(farmsListProvider);

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
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.agriculture_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Farme',
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
                    child: farmsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Nije uspjelo učitavanje farmi.'),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () =>
                                    ref.invalidate(farmsListProvider),
                                child: const Text('Pokušaj ponovo'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      data: (farms) {
                        if (farms.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.agriculture_outlined,
                                    size: 48,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Još nema registrovanih farmi.',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () =>
                              ref.refresh(farmsListProvider.future),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                            itemCount: farms.length,
                            itemBuilder: (context, index) => FarmCard(
                              farm: farms[index],
                              onTap: () => context.push(
                                '${AppRoutes.farmDetail}/${farms[index].id}',
                              ),
                            ),
                          ),
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
