import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_surface_colors.dart';
import '../../../../core/widgets/screen_header.dart';
import '../providers/farms_providers.dart';
import '../widgets/farm_card.dart';

/// Directory of sellers ("farme").
class FarmsScreen extends ConsumerWidget {
  const FarmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmsAsync = ref.watch(farmsListProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ScreenHeader(
              title: 'Farme',
              subtitle: 'Domaći proizvođači iz tvoje okoline',
            ),
            Expanded(
              child: farmsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Nije uspjelo učitavanje farmi.'),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => ref.invalidate(farmsListProvider),
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
                              size: 40,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Još nema registrovanih farmi.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.surfaceColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.refresh(farmsListProvider.future),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
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
          ],
        ),
      ),
    );
  }
}
