import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import 'providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _emailKey = GlobalKey<FormState>();
  final _otpKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _codeSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_emailKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_emailController.text);

    if (success && mounted) {
      setState(() {
        _codeSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset instructions sent. Please check your email.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      final error = ref.read(authControllerProvider).errorMessage ?? AppStrings.genericError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _verifyAndReset() async {
    if (!_otpKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).verifyOtpAndResetPassword(
          email: _emailController.text,
          token: _otpController.text,
          newPassword: _newPasswordController.text,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully! Please sign in.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/login');
    } else if (mounted) {
      final error = ref.read(authControllerProvider).errorMessage ?? AppStrings.genericError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: const Text(AppStrings.resetPassword, style: TextStyle(color: AppColors.ink)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _codeSent ? 'Enter Verification Code' : 'Forgot Password',
                style: AppText.headlineLarge.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                _codeSent
                    ? 'Enter the 6-digit code sent to ${_emailController.text} and your new password.'
                    : 'Enter your account email to receive a password recovery link or verification code.',
                style: AppText.bodyMedium.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 28),
              if (!_codeSent) ...[
                Form(
                  key: _emailKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _emailController,
                        label: AppStrings.email,
                        hint: 'owner@example.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return AppStrings.requiredField;
                          }
                          if (!val.contains('@') || !val.contains('.')) {
                            return AppStrings.invalidEmail;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        text: AppStrings.sendResetCode,
                        isLoading: authState.isLoading,
                        onPressed: _sendCode,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Form(
                  key: _otpKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _otpController,
                        label: AppStrings.otpCode,
                        hint: '123456',
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(Icons.pin_outlined),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return AppStrings.requiredField;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _newPasswordController,
                        label: AppStrings.newPassword,
                        hint: 'At least 8 characters',
                        obscureText: true,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return AppStrings.requiredField;
                          }
                          if (val.length < 8) {
                            return AppStrings.passwordMinLength;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        text: AppStrings.verifyAndReset,
                        isLoading: authState.isLoading,
                        onPressed: _verifyAndReset,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => setState(() => _codeSent = false),
                        child: const Text('Back to enter email'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
