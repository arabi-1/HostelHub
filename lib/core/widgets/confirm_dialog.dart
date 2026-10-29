import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_button.dart';
import 'app_text_field.dart';

class ConfirmDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final String? requiredTextToConfirm;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.requiredTextToConfirm,
  });

  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    String? requiredTextToConfirm,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        requiredTextToConfirm: requiredTextToConfirm,
      ),
    );
    return result ?? false;
  }

  @override
  State<ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<ConfirmDialog> {
  final TextEditingController _inputController = TextEditingController();
  bool _canConfirm = true;

  @override
  void initState() {
    super.initState();
    if (widget.requiredTextToConfirm != null) {
      _canConfirm = false;
      _inputController.addListener(_validateInput);
    }
  }

  void _validateInput() {
    final valid = _inputController.text.trim() == widget.requiredTextToConfirm;
    if (valid != _canConfirm) {
      setState(() {
        _canConfirm = valid;
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.title,
        style: AppText.titleLarge.copyWith(
          color: widget.isDestructive ? AppColors.danger : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message, style: AppText.bodyMedium),
          if (widget.requiredTextToConfirm != null) ...[
            const SizedBox(height: 16),
            Text(
              'Type "${widget.requiredTextToConfirm}" to confirm:',
              style: AppText.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _inputController,
              hint: widget.requiredTextToConfirm,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(widget.cancelLabel, style: const TextStyle(color: AppColors.muted)),
        ),
        AppButton(
          text: widget.confirmLabel,
          variant: widget.isDestructive ? AppButtonVariant.danger : AppButtonVariant.primary,
          width: 110,
          height: 40,
          onPressed: _canConfirm ? () => Navigator.of(context).pop(true) : null,
        ),
      ],
    );
  }
}
