import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/property.dart';
import 'providers/room_providers.dart';

class PropertyFormDialog extends ConsumerStatefulWidget {
  final Property? property;

  const PropertyFormDialog({super.key, this.property});

  static Future<Property?> show(BuildContext context, {Property? property}) {
    return showDialog<Property>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PropertyFormDialog(property: property),
    );
  }

  @override
  ConsumerState<PropertyFormDialog> createState() => _PropertyFormDialogState();
}

class _PropertyFormDialogState extends ConsumerState<PropertyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.property?.name ?? '');
    _addressController = TextEditingController(text: widget.property?.address ?? '');
    _cityController = TextEditingController(text: widget.property?.city ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(propertiesProvider.notifier);
      Property result;
      if (widget.property == null) {
        result = await notifier.addProperty(
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
        );
      } else {
        final updated = widget.property!.copyWith(
          name: _nameController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        );
        result = await notifier.updateProperty(updated);
      }
      if (mounted) {
        Navigator.of(context).pop(result);
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.property != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isEditing ? 'Edit Property' : 'Add Property'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Property Name',
                hint: 'e.g., Al-Rehman Hostel, Main Campus',
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Property name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _addressController,
                label: 'Address (Optional)',
                hint: 'e.g., Street 4, Sector G-9/1',
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _cityController,
                label: 'City (Optional)',
                hint: 'e.g., Islamabad / Lahore',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel, style: TextStyle(color: AppColors.muted)),
        ),
        AppButton(
          text: isEditing ? 'Save Changes' : 'Create Property',
          width: 130,
          height: 40,
          isLoading: _isLoading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
