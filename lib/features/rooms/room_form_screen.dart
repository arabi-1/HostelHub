import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/room.dart';
import 'providers/room_providers.dart';

class RoomFormScreen extends ConsumerStatefulWidget {
  final Room? room;
  final String? initialPropertyId;

  const RoomFormScreen({
    super.key,
    this.room,
    this.initialPropertyId,
  });

  @override
  ConsumerState<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends ConsumerState<RoomFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedPropertyId;
  late final TextEditingController _roomNumberController;
  late final TextEditingController _floorController;
  late final TextEditingController _capacityController;
  late final TextEditingController _rentController;
  late final TextEditingController _notesController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final r = widget.room;
    _selectedPropertyId = r?.propertyId ?? widget.initialPropertyId;
    _roomNumberController = TextEditingController(text: r?.roomNumber ?? '');
    _floorController = TextEditingController(text: r?.floor ?? '');
    _capacityController = TextEditingController(text: r != null ? r.capacity.toString() : '4');
    _rentController = TextEditingController(
      text: r != null ? r.defaultRent.toInt().toString() : '12000',
    );
    _notesController = TextEditingController(text: r?.notes ?? '');
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    _floorController.dispose();
    _capacityController.dispose();
    _rentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPropertyId == null || _selectedPropertyId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a property for this room.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final capacity = int.tryParse(_capacityController.text.trim()) ?? 1;
    final rent = double.tryParse(_rentController.text.trim()) ?? 0.0;

    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(roomsProvider.notifier);
      if (widget.room == null) {
        await notifier.addRoom(
          propertyId: _selectedPropertyId!,
          roomNumber: _roomNumberController.text.trim(),
          floor: _floorController.text.trim(),
          capacity: capacity,
          defaultRent: rent,
          notes: _notesController.text.trim(),
        );
      } else {
        final updated = widget.room!.copyWith(
          propertyId: _selectedPropertyId!,
          roomNumber: _roomNumberController.text.trim(),
          floor: _floorController.text.trim().isEmpty ? null : _floorController.text.trim(),
          capacity: capacity,
          defaultRent: rent,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
        await notifier.updateRoom(updated);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.room == null ? 'Room created successfully' : 'Room updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
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
    final propertiesAsync = ref.watch(propertiesProvider);
    final isEditing = widget.room != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Room' : 'Add Room'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Property Dropdown
                propertiesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading properties: $e'),
                  data: (properties) {
                    if (properties.isEmpty) {
                      return Card(
                        color: AppColors.warningContainer,
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('No active properties. Please create a property first.'),
                        ),
                      );
                    }
                    if (_selectedPropertyId == null || !properties.any((p) => p.id == _selectedPropertyId)) {
                      _selectedPropertyId = properties.first.id;
                    }

                    return DropdownButtonFormField<String>(
                      value: _selectedPropertyId,
                      decoration: const InputDecoration(
                        labelText: 'Property / Building',
                        prefixIcon: Icon(Icons.apartment_rounded),
                      ),
                      items: properties
                          .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                          .toList(),
                      onChanged: isEditing ? null : (val) => setState(() => _selectedPropertyId = val),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Room Number & Floor
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppTextField(
                        controller: _roomNumberController,
                        label: 'Room Number',
                        hint: 'e.g. 101, A-1',
                        prefixIcon: const Icon(Icons.meeting_room_outlined),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Room number is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: AppTextField(
                        controller: _floorController,
                        label: 'Floor',
                        hint: 'e.g. 1st, Ground',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Capacity & Rent
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _capacityController,
                        label: 'Bed Capacity (1-20)',
                        hint: '4',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        prefixIcon: const Icon(Icons.hotel_outlined),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Required';
                          }
                          final num = int.tryParse(val.trim());
                          if (num == null || num < 1 || num > 20) {
                            return 'Between 1-20';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _rentController,
                        label: 'Default Rent (PKR)',
                        hint: '12000',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        prefixIcon: const Icon(Icons.payments_outlined),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Required';
                          }
                          final rent = double.tryParse(val.trim());
                          if (rent == null || rent < 0) {
                            return 'Must be >= 0';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notes
                AppTextField(
                  controller: _notesController,
                  label: 'Notes / Facilities (Optional)',
                  hint: 'e.g. Attached washroom, AC, balcony',
                  maxLines: 3,
                ),
                const SizedBox(height: 28),

                AppButton(
                  text: isEditing ? 'Save Room' : 'Add Room',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
