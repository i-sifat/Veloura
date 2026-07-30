import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/features/profile/presentation/profile_controller.dart';
import 'package:veloura/shared/widgets/error_state.dart';

/// Unified read-only view over existing per-feature favorite stores.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(profileControllerProvider),
        ),
        data: (state) => state.favorites.isEmpty
            ? const Center(child: Text('Your saved favorites will appear here.'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                itemCount: state.favorites.length,
                itemBuilder: (context, index) {
                  final item = state.favorites[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.favorite),
                      title: Text(item.label),
                      subtitle: Text(item.source),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
