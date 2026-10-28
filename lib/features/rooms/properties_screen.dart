import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../data/models/property.dart';
import 'property_form_dialog.dart';
import 'providers/room_providers.dart';

class PropertiesScreen extends ConsumerWidget {
  const PropertiesScreen({super.key});

  Future<void> _archiveProperty(BuildContext context, WidgetRef ref, Property property) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Archive Property',
      message: 'Are you sure you want to archive "${property.name}"? Existing rooms and residents will be preserved, but it will no longer be listed as active.',
      confirmLabel: 'Archive',
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      try {
        await ref.read(propertiesProvider.notifier).archiveProperty(property.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Archived "${property.name}"'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Properties'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Property'),
        onPressed: () => PropertyFormDialog.show(context),
      ),
      body: propertiesAsync.when(
        loading: () => const LoadingView(message: 'Loading properties...'),
        error: (err, stack) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(propertiesProvider),
        ),
        data: (properties) {
          if (properties.isEmpty) {
            return EmptyState(
              title: 'No Properties Found',
              message: 'Add your first hostel building or branch to start adding rooms.',
              icon: Icons.apartment_rounded,
              actionLabel: 'Add Property',
              onAction: () => PropertyFormDialog.show(context),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: properties.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final prop = properties[index];
              final location = [prop.address, prop.city]
                  .where((e) => e != null && e.isNotEmpty)
                  .join(', ');

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.apartment_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prop.name,
                              style: AppText.titleLarge.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (location.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                location,
                                style: AppText.bodySmall.copyWith(color: AppColors.muted),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                        tooltip: 'Edit Property',
                        onPressed: () => PropertyFormDialog.show(context, property: prop),
                      ),
                      IconButton(
                        icon: const Icon(Icons.archive_outlined, color: AppColors.muted),
                        tooltip: 'Archive Property',
                        onPressed: () => _archiveProperty(context, ref, prop),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
