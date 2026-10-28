import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import 'property_form_dialog.dart';
import 'providers/room_providers.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertiesProvider);
    final selectedPropId = ref.watch(selectedPropertyIdProvider);
    final roomsAsync = ref.watch(filteredRoomsProvider);
    final occupancyAsync = ref.watch(roomOccupancyProvider);
    final isVacantOnly = ref.watch(vacancyFilterProvider);
    final currencyFormatter = NumberFormat('#,##0');

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navRooms),
        actions: [
          IconButton(
            icon: const Icon(Icons.domain_rounded),
            tooltip: 'Manage Properties',
            onPressed: () => context.push('/properties'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Room'),
        onPressed: () {
          final props = propertiesAsync.value ?? [];
          if (props.isEmpty) {
            PropertyFormDialog.show(context);
          } else {
            context.push('/rooms/add?propertyId=${selectedPropId ?? props.first.id}');
          }
        },
      ),
      body: propertiesAsync.when(
        loading: () => const LoadingView(message: 'Loading properties...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(propertiesProvider),
        ),
        data: (properties) {
          if (properties.isEmpty) {
            return EmptyState(
              title: 'No Properties Yet',
              message: 'Add your first property before configuring rooms.',
              icon: Icons.apartment_rounded,
              actionLabel: 'Add Property',
              onAction: () => PropertyFormDialog.show(context),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Property selector tabs
              Container(
                color: Theme.of(context).cardColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: properties.map((prop) {
                      final isSelected = prop.id == selectedPropId;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(prop.name),
                          selected: isSelected,
                          selectedColor: AppColors.primaryContainer,
                          onSelected: (selected) {
                            if (selected) {
                              ref.read(selectedPropertyIdProvider.notifier).select(prop.id);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Filter Bar (Vacancy filter chip & total room counts)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FilterChip(
                      label: const Text('Vacant Only'),
                      selected: isVacantOnly,
                      selectedColor: AppColors.primaryContainer,
                      checkmarkColor: AppColors.primary,
                      onSelected: (val) {
                        ref.read(vacancyFilterProvider.notifier).setFilter(val);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.muted),
                      tooltip: 'Refresh Rooms',
                      onPressed: () {
                        ref.invalidate(roomsProvider);
                        ref.invalidate(roomOccupancyProvider);
                      },
                    ),
                  ],
                ),
              ),

              // Rooms List
              Expanded(
                child: roomsAsync.when(
                  loading: () => const LoadingView(message: 'Loading rooms...'),
                  error: (err, _) => ErrorView(
                    message: err.toString(),
                    onRetry: () => ref.refresh(roomsProvider),
                  ),
                  data: (rooms) {
                    if (rooms.isEmpty) {
                      return EmptyState(
                        title: isVacantOnly ? 'No Vacant Rooms' : 'No Rooms Added',
                        message: isVacantOnly
                            ? 'All rooms are fully occupied in this property.'
                            : 'Tap "+ Add Room" to add your first room.',
                        icon: Icons.hotel_outlined,
                      );
                    }

                    final occupancyMap = occupancyAsync.value ?? {};

                    return ListView.separated(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80),
                      itemCount: rooms.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        final occupied = occupancyMap[room.id] ?? 0;
                        final freeBeds = room.capacity - occupied;
                        final isFull = freeBeds <= 0;

                        return Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => context.push('/rooms/edit', extra: room),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryContainer,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.meeting_room_rounded,
                                              color: AppColors.primary,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Room ${room.roomNumber}',
                                                style: AppText.titleLarge,
                                              ),
                                              if (room.floor != null && room.floor!.isNotEmpty)
                                                Text(
                                                  '${room.floor} floor',
                                                  style: AppText.bodySmall.copyWith(color: AppColors.muted),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      // Bed capacity badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isFull
                                              ? AppColors.dangerContainer
                                              : AppColors.successContainer,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isFull ? Icons.block_rounded : Icons.check_circle_outline,
                                              size: 14,
                                              color: isFull ? AppColors.danger : AppColors.success,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$occupied / ${room.capacity} beds',
                                              style: AppText.labelMedium.copyWith(
                                                color: isFull ? AppColors.danger : AppColors.success,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Default Rent:',
                                        style: AppText.bodySmall.copyWith(color: AppColors.muted),
                                      ),
                                      Text(
                                        'Rs ${currencyFormatter.format(room.defaultRent.toInt())} / bed',
                                        style: AppText.labelLarge.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (room.notes != null && room.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      room.notes!,
                                      style: AppText.bodySmall.copyWith(color: AppColors.muted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
