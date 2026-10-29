import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/cnic.dart';
import '../../core/utils/phone.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/resident.dart';
import '../../data/models/room.dart';
import '../rooms/providers/room_providers.dart';
import 'providers/resident_providers.dart';

class ResidentFormScreen extends ConsumerStatefulWidget {
  final Resident? resident;

  const ResidentFormScreen({super.key, this.resident});

  @override
  ConsumerState<ResidentFormScreen> createState() => _ResidentFormScreenState();
}

class _ResidentFormScreenState extends ConsumerState<ResidentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cnicController;
  late final TextEditingController _guardianNameController;
  late final TextEditingController _guardianPhoneController;
  late final TextEditingController _rentController;
  late final TextEditingController _depositController;
  late final TextEditingController _dueDayController;
  late final TextEditingController _notesController;

  String? _selectedRoomId;
  DateTime _joinDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final r = widget.resident;
    _nameController = TextEditingController(text: r?.fullName ?? '');
    _phoneController = TextEditingController(
      text: r != null ? PhoneUtils.formatDisplay(r.phone) : '',
    );
    _cnicController = TextEditingController(
      text: r?.cnic != null ? CnicUtils.format(r!.cnic!) : '',
    );
    _guardianNameController = TextEditingController(text: r?.guardianName ?? '');
    _guardianPhoneController = TextEditingController(
      text: r?.guardianPhone != null ? PhoneUtils.formatDisplay(r!.guardianPhone!) : '',
    );
    _rentController = TextEditingController(
      text: r != null ? r.monthlyRent.toInt().toString() : '',
    );
    _depositController = TextEditingController(
      text: r != null ? r.securityDeposit.toInt().toString() : '0',
    );
    _dueDayController = TextEditingController(
      text: r != null ? r.rentDueDay.toString() : '5',
    );
    _notesController = TextEditingController(text: r?.notes ?? '');

    _selectedRoomId = (r?.roomId != null && r!.roomId!.trim().isNotEmpty) ? r.roomId : null;
    if (r != null) {
      _joinDate = r.joinDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _dueDayController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickJoinDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joinDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _joinDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final normalizedPhone = PhoneUtils.normalize(_phoneController.text.trim());
    final rawCnic = _cnicController.text.trim();
    final normalizedCnic = rawCnic.isNotEmpty ? CnicUtils.normalize(rawCnic) : null;

    final rawGuardianPhone = _guardianPhoneController.text.trim();
    final normalizedGuardianPhone =
        rawGuardianPhone.isNotEmpty ? PhoneUtils.normalize(rawGuardianPhone) : null;

    final monthlyRent = double.tryParse(_rentController.text.trim()) ?? 0.0;
    final securityDeposit = double.tryParse(_depositController.text.trim()) ?? 0.0;
    final dueDay = int.tryParse(_dueDayController.text.trim()) ?? 5;

    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(residentsProvider.notifier);
      final cleanRoomId = (_selectedRoomId != null && _selectedRoomId!.trim().isNotEmpty) ? _selectedRoomId!.trim() : null;
      if (widget.resident == null) {
        await notifier.addResident(
          roomId: cleanRoomId,
          fullName: _nameController.text.trim(),
          phone: normalizedPhone,
          cnic: normalizedCnic,
          guardianName: _guardianNameController.text.trim(),
          guardianPhone: normalizedGuardianPhone,
          monthlyRent: monthlyRent,
          securityDeposit: securityDeposit,
          rentDueDay: dueDay,
          joinDate: _joinDate,
          notes: _notesController.text.trim(),
        );
      } else {
        final updated = widget.resident!.copyWith(
          roomId: cleanRoomId,
          fullName: _nameController.text.trim(),
          phone: normalizedPhone,
          cnic: normalizedCnic,
          guardianName: _guardianNameController.text.trim().isEmpty ? null : _guardianNameController.text.trim(),
          guardianPhone: normalizedGuardianPhone,
          monthlyRent: monthlyRent,
          securityDeposit: securityDeposit,
          rentDueDay: dueDay,
          joinDate: _joinDate,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
        await notifier.updateResident(updated);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.resident == null ? 'Resident added successfully' : 'Resident updated successfully',
            ),
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
    final isEditing = widget.resident != null;
    final availableRooms = ref.watch(availableRoomsProvider(widget.resident?.roomId));
    final occupancy = ref.watch(roomOccupancyProvider).value ?? {};
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Resident' : 'Add Resident'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Personal Information Header
                const Text(
                  'Personal Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _nameController,
                  label: AppStrings.fullName,
                  hint: 'e.g. Muhammad Ali',
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return AppStrings.requiredField;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _phoneController,
                  label: AppStrings.phone,
                  hint: '0300 1234567',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return AppStrings.requiredField;
                    }
                    if (!PhoneUtils.isValid(val)) {
                      return 'Enter a valid Pakistani mobile number (03XXXXXXXXX)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _cnicController,
                  label: 'CNIC (Optional, 13 digits)',
                  hint: '35201-1234567-1',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  validator: (val) {
                    if (val != null && val.trim().isNotEmpty && !CnicUtils.isValid(val)) {
                      return 'CNIC must be 13 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Room & Stay Details
                const Text(
                  'Room Assignment & Rent',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 12),

                // Room Picker Dropdown
                DropdownButtonFormField<String?>(
                  initialValue: (_selectedRoomId != null && _selectedRoomId!.trim().isNotEmpty)
                      ? _selectedRoomId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Assign Room (Available Beds)',
                    prefixIcon: Icon(Icons.hotel_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Unassigned (No room)'),
                    ),
                    ...availableRooms.map((Room r) {
                      final occupied = occupancy[r.id] ?? 0;
                      final free = r.capacity - occupied;
                      final freeText = free > 0 ? '$free free beds' : 'Current room';
                      return DropdownMenuItem<String?>(
                        value: r.id,
                        child: Text('Room ${r.roomNumber} ($freeText) — Rs ${r.defaultRent.toInt()}'),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedRoomId = (val != null && val.trim().isNotEmpty) ? val.trim() : null;
                      if (_selectedRoomId != null && _rentController.text.isEmpty) {
                        final room = availableRooms.firstWhere((r) => r.id == _selectedRoomId);
                        _rentController.text = room.defaultRent.toInt().toString();
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Rent & Security Deposit
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _rentController,
                        label: 'Monthly Rent (PKR)',
                        hint: '15000',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        prefixIcon: const Icon(Icons.payments_outlined),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return AppStrings.requiredField;
                          }
                          final amount = double.tryParse(val.trim());
                          if (amount == null || amount < 0) {
                            return 'Must be >= 0';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _depositController,
                        label: 'Security Deposit (PKR)',
                        hint: '0',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        prefixIcon: const Icon(Icons.security_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Rent Due Day & Join Date
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _dueDayController,
                        label: 'Rent Due Day (1-28)',
                        hint: '5',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                        validator: (val) {
                          final day = int.tryParse(val?.trim() ?? '');
                          if (day == null || day < 1 || day > 28) {
                            return 'Between 1-28';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _pickJoinDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Join Date',
                            prefixIcon: Icon(Icons.event_available_outlined),
                          ),
                          child: Text(
                            dateFormat.format(_joinDate),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Guardian Information
                const Text(
                  'Guardian Contact (Optional)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _guardianNameController,
                  label: 'Guardian Name',
                  hint: 'Parent or emergency contact',
                  prefixIcon: const Icon(Icons.person_pin_outlined),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _guardianPhoneController,
                  label: 'Guardian Phone',
                  hint: '03XX XXXXXXX',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_in_talk_outlined),
                  validator: (val) {
                    if (val != null && val.trim().isNotEmpty && !PhoneUtils.isValid(val)) {
                      return 'Enter a valid Pakistani mobile number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Notes
                AppTextField(
                  controller: _notesController,
                  label: 'Notes / Remarks (Optional)',
                  hint: 'Special requests, student / workplace details',
                  maxLines: 2,
                ),
                const SizedBox(height: 28),

                AppButton(
                  text: isEditing ? 'Save Changes' : 'Save Resident',
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
