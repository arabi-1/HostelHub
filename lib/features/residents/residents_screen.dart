import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/phone.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/models/room.dart';
import '../billing/widgets/write_lock_guard.dart';
import '../rooms/providers/room_providers.dart';
import 'providers/resident_providers.dart';

class ResidentsScreen extends ConsumerWidget {
  const ResidentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final residentsAsync = ref.watch(filteredResidentsProvider);
    final currentFilter = ref.watch(residentFilterProvider);
    final roomsAsync = ref.watch(roomsProvider);
    final roomsList = roomsAsync.value ?? [];
    final roomsMap = <String, Room>{for (final rm in roomsList) rm.id: rm};
    final currencyFormatter = NumberFormat('#,##0');

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navResidents),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Resident'),
        onPressed: () {
          if (WriteLockGuard.checkAndNavigate(context, ref)) {
            context.push('/residents/add');
          }
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search & Filter Header
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Search as-you-type input
                TextField(
                  onChanged: (val) {
                    ref.read(residentSearchQueryProvider.notifier).setQuery(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by name, phone, or room...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Filter Chips (Active vs Left vs All)
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Active'),
                      selected: currentFilter == 'active',
                      selectedColor: AppColors.primaryContainer,
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(residentFilterProvider.notifier).setFilter('active');
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Left'),
                      selected: currentFilter == 'left',
                      selectedColor: AppColors.primaryContainer,
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(residentFilterProvider.notifier).setFilter('left');
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('All'),
                      selected: currentFilter == 'all',
                      selectedColor: AppColors.primaryContainer,
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(residentFilterProvider.notifier).setFilter('all');
                        }
                      },
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.muted),
                      tooltip: 'Refresh',
                      onPressed: () {
                        ref.invalidate(residentsProvider);
                        ref.invalidate(roomOccupancyProvider);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Resident List
          Expanded(
            child: residentsAsync.when(
              loading: () => const LoadingView(message: 'Loading residents...'),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.refresh(residentsProvider),
              ),
              data: (residents) {
                if (residents.isEmpty) {
                  return EmptyState(
                    title: 'No Residents Found',
                    message: currentFilter == 'active'
                        ? 'No active residents found. Tap "+ Add Resident" to register a resident.'
                        : 'No residents matching current filters.',
                    icon: Icons.people_outline_rounded,
                    actionLabel: currentFilter == 'active' ? 'Add Resident' : null,
                    onAction: currentFilter == 'active' ? () => context.push('/residents/add') : null,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 80),
                  itemCount: residents.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final resident = residents[index];
                    final assignedRoom = resident.roomId != null ? roomsMap[resident.roomId] : null;
                    final roomLabel = assignedRoom != null ? 'Room ${assignedRoom.roomNumber}' : 'No Room';

                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.push('/residents/${resident.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: resident.isActive
                                    ? AppColors.primaryContainer
                                    : AppColors.outline,
                                child: Text(
                                  resident.fullName.isNotEmpty
                                      ? resident.fullName[0].toUpperCase()
                                      : 'R',
                                  style: AppText.titleLarge.copyWith(
                                    color: resident.isActive ? AppColors.primary : AppColors.muted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            resident.fullName,
                                            style: AppText.titleLarge.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        StatusChip(
                                          label: resident.isActive ? 'Active' : 'Left',
                                          type: resident.isActive ? StatusType.active : StatusType.left,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      PhoneUtils.formatDisplay(resident.phone),
                                      style: AppText.bodySmall.copyWith(color: AppColors.muted),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.background,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: AppColors.outline),
                                          ),
                                          child: Text(
                                            roomLabel,
                                            style: AppText.labelMedium.copyWith(color: AppColors.primaryDark),
                                          ),
                                        ),
                                        Text(
                                          'Rs ${currencyFormatter.format(resident.monthlyRent.toInt())} / mo',
                                          style: AppText.labelLarge.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
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
      ),
    );
  }
}
