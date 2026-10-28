import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

enum StatusType {
  paid,
  pending,
  partial,
  overdue,
  active,
  left,
}

class StatusChip extends StatelessWidget {
  final String label;
  final StatusType type;

  const StatusChip({
    super.key,
    required this.label,
    required this.type,
  });

  factory StatusChip.fromString(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const StatusChip(label: 'Paid', type: StatusType.paid);
      case 'partial':
        return const StatusChip(label: 'Partial', type: StatusType.partial);
      case 'overdue':
        return const StatusChip(label: 'Overdue', type: StatusType.overdue);
      case 'active':
        return const StatusChip(label: 'Active', type: StatusType.active);
      case 'left':
        return const StatusChip(label: 'Left', type: StatusType.left);
      case 'pending':
      default:
        return StatusChip(label: status.isEmpty ? 'Pending' : status, type: StatusType.pending);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (type) {
      case StatusType.paid:
        bg = AppColors.successContainer;
        fg = AppColors.success;
        break;
      case StatusType.pending:
      case StatusType.partial:
        bg = AppColors.warningContainer;
        fg = AppColors.warning;
        break;
      case StatusType.overdue:
        bg = AppColors.dangerContainer;
        fg = AppColors.danger;
        break;
      case StatusType.active:
        bg = AppColors.primaryContainer;
        fg = AppColors.primary;
        break;
      case StatusType.left:
        bg = AppColors.outline;
        fg = AppColors.muted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppText.labelMedium.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
