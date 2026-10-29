import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/cnic.dart';
import '../../core/utils/phone.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/models/resident.dart';
import '../../data/models/room.dart';
import '../auth/providers/auth_provider.dart';
import '../receipts/services/whatsapp_service.dart';
import '../rent/providers/rent_providers.dart';
import '../rooms/providers/room_providers.dart';
import 'providers/resident_providers.dart';

class ResidentDetailScreen extends ConsumerStatefulWidget {
  final String residentId;

  const ResidentDetailScreen({super.key, required this.residentId});

  @override
  ConsumerState<ResidentDetailScreen> createState() => _ResidentDetailScreenState();
}

class _ResidentDetailScreenState extends ConsumerState<ResidentDetailScreen> {
  bool _isCnicRevealed = false;
  Timer? _revealTimer;

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleRevealCnic(String rawCnic) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Reveal CNIC',
      message: 'The resident CNIC will be revealed for 5 seconds for verification. Proceed?',
      confirmLabel: 'Reveal',
    );

    if (confirmed && mounted) {
      setState(() => _isCnicRevealed = true);
      _revealTimer?.cancel();
      _revealTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _isCnicRevealed = false);
        }
      });
    }
  }

  Future<void> _sendRentReminder(Resident resident, double balance) async {
    final profile = await ref.read(currentProfileProvider.future);
    final bName = profile?.businessName;
    final businessName = (bName != null && bName.trim().isNotEmpty) ? bName.trim() : 'HostelHub';

    final message = WhatsAppService.buildReminderMessage(
      residentName: resident.fullName,
      businessName: businessName,
      balance: balance,
      period: DateTime(DateTime.now().year, DateTime.now().month, 1),
      dueDate: DateTime(DateTime.now().year, DateTime.now().month, resident.rentDueDay),
      isOverdue: DateTime.now().day > resident.rentDueDay,
    );

    if (mounted) {
      await WhatsAppService.launchOrCopy(
        context: context,
        phone: resident.phone,
        message: message,
      );
    }
  }

  Future<void> _launchCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not initiate phone call')),
      );
    }
  }

  Future<void> _launchWhatsApp(String phone, String name) async {
    final normalized = PhoneUtils.normalize(phone);
    final url = 'https://wa.me/$normalized?text=${Uri.encodeComponent('Hello $name, from HostelHub.')}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp is not installed on this device')),
      );
    }
  }

  Future<void> _handleMarkAsLeft(Resident resident) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Mark as Left',
      message: 'Are you sure you want to mark ${resident.fullName} as left? This will immediately free their assigned bed, while preserving their rent history.',
      confirmLabel: 'Mark as Left',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      try {
        await ref.read(residentsProvider.notifier).markResidentLeft(resident.id, DateTime.now());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${resident.fullName} marked as left and bed freed.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
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
  Widget build(BuildContext context) {
    final residentAsync = ref.watch(residentDetailProvider(widget.residentId));
    final ledgerAsync = ref.watch(residentLedgerProvider(widget.residentId));
    final roomsAsync = ref.watch(roomsProvider);
    final roomsList = roomsAsync.value ?? [];
    final roomsMap = <String, Room>{for (final rm in roomsList) rm.id: rm};

    final currencyFormatter = NumberFormat('#,##0');
    final dateFormat = DateFormat('dd MMM yyyy');

    return residentAsync.when(
      loading: () => const Scaffold(body: LoadingView(message: 'Loading resident details...')),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Resident Details')),
        body: ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(residentDetailProvider(widget.residentId)),
        ),
      ),
      data: (resident) {
        if (resident == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Resident Details')),
            body: const Center(child: Text('Resident not found')),
          );
        }

        final room = resident.roomId != null ? roomsMap[resident.roomId] : null;
        final roomText = room != null ? 'Room ${room.roomNumber}' : 'Unassigned';

        return Scaffold(
          appBar: AppBar(
            title: Text(resident.fullName),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Resident',
                onPressed: () => context.push('/residents/${resident.id}/edit', extra: resident),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Resident Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: resident.isActive
                            ? AppColors.primaryContainer
                            : AppColors.outline,
                        child: Text(
                          resident.fullName.isNotEmpty ? resident.fullName[0].toUpperCase() : 'R',
                          style: AppText.displayLarge.copyWith(
                            color: resident.isActive ? AppColors.primary : AppColors.muted,
                            fontSize: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resident.fullName,
                              style: AppText.headlineLarge.copyWith(fontSize: 20),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              PhoneUtils.formatDisplay(resident.phone),
                              style: AppText.bodyMedium.copyWith(color: AppColors.muted),
                            ),
                            const SizedBox(height: 8),
                            StatusChip(
                              label: resident.isActive ? 'Active Resident' : 'Left Resident',
                              type: resident.isActive ? StatusType.active : StatusType.left,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick Contact Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.phone_rounded, color: AppColors.primary),
                      label: const Text('Call'),
                      onPressed: () => _launchCall(resident.phone),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.chat_bubble_rounded),
                      label: const Text('WhatsApp'),
                      onPressed: () => _launchWhatsApp(resident.phone, resident.fullName),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Unpaid Dues & WhatsApp Reminder (FR-17, FR-18)
              if (resident.isActive && (ledgerAsync.value?.totalBalance ?? 0) > 0) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unpaid Dues: Rs ${currencyFormatter.format((ledgerAsync.value?.totalBalance ?? 0).toInt())}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.danger,
                              ),
                            ),
                            const Text(
                              'Rent reminder ready to send',
                              style: TextStyle(fontSize: 12, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.chat, size: 16),
                        label: const Text('Send Reminder'),
                        onPressed: () => _sendRentReminder(
                          resident,
                          ledgerAsync.value!.totalBalance,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Rent & Room Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Accommodation & Dues',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Assigned Room', roomText, icon: Icons.hotel_outlined),
                      const Divider(height: 16),
                      _buildInfoRow(
                        'Monthly Rent',
                        'Rs ${currencyFormatter.format(resident.monthlyRent.toInt())}',
                        icon: Icons.payments_outlined,
                      ),
                      const Divider(height: 16),
                      _buildInfoRow(
                        'Security Deposit',
                        'Rs ${currencyFormatter.format(resident.securityDeposit.toInt())}',
                        icon: Icons.security_outlined,
                      ),
                      const Divider(height: 16),
                      _buildInfoRow(
                        'Rent Due Day',
                        'Every ${resident.rentDueDay}th of month',
                        icon: Icons.calendar_month_outlined,
                      ),
                      const Divider(height: 16),
                      _buildInfoRow(
                        'Joined On',
                        dateFormat.format(resident.joinDate),
                        icon: Icons.event_available_outlined,
                      ),
                      if (resident.leftDate != null) ...[
                        const Divider(height: 16),
                        _buildInfoRow(
                          'Left On',
                          dateFormat.format(resident.leftDate!),
                          icon: Icons.event_busy_outlined,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // CNIC & Identity
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'CNIC / National Identity',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (resident.cnic != null && resident.cnic!.isNotEmpty)
                            TextButton.icon(
                              icon: Icon(
                                _isCnicRevealed ? Icons.visibility_off : Icons.visibility,
                                size: 18,
                              ),
                              label: Text(_isCnicRevealed ? 'Hide' : 'Reveal (5s)'),
                              onPressed: () {
                                if (_isCnicRevealed) {
                                  setState(() => _isCnicRevealed = false);
                                  _revealTimer?.cancel();
                                } else {
                                  _handleRevealCnic(resident.cnic!);
                                }
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        resident.cnic != null && resident.cnic!.isNotEmpty
                            ? (_isCnicRevealed
                                ? CnicUtils.format(resident.cnic!)
                                : CnicUtils.mask(resident.cnic!))
                            : 'No CNIC provided',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'monospace',
                          letterSpacing: 1.2,
                          color: _isCnicRevealed ? AppColors.primary : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Guardian Contact
              if (resident.guardianName != null || resident.guardianPhone != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Guardian Contact',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        if (resident.guardianName != null)
                          _buildInfoRow('Guardian Name', resident.guardianName!, icon: Icons.person_pin_outlined),
                        if (resident.guardianPhone != null) ...[
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 20, color: AppColors.muted),
                                  const SizedBox(width: 8),
                                  Text(
                                    PhoneUtils.formatDisplay(resident.guardianPhone!),
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.phone, color: AppColors.primary),
                                    onPressed: () => _launchCall(resident.guardianPhone!),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                                    onPressed: () => _launchWhatsApp(
                                      resident.guardianPhone!,
                                      resident.guardianName ?? 'Guardian',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Notes
              if (resident.notes != null && resident.notes!.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(resident.notes!, style: AppText.bodyMedium),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Mark as Left Action
              if (resident.isActive) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.person_remove_outlined),
                  label: const Text('Mark Resident as Left'),
                  onPressed: () => _handleMarkAsLeft(resident),
                ),
                const SizedBox(height: 32),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: AppColors.muted),
          const SizedBox(width: 8),
        ],
        Text(label, style: const TextStyle(color: AppColors.muted)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
