import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import 'providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).signUp(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _nameController.text,
        );

    if (!success && mounted) {
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
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.signUp,
                    style: AppText.displayLarge.copyWith(
                      color: AppColors.primary,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your account to start managing hostel rooms and residents with 30-day free trial.',
                    style: AppText.bodyMedium.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: 28),
                  AppTextField(
                    controller: _nameController,
                    label: AppStrings.fullName,
                    hint: 'Muhammad Arabi',
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return AppStrings.requiredField;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _passwordController,
                    label: AppStrings.password,
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
                  const SizedBox(height: 28),
                  AppButton(
                    text: AppStrings.signUp,
                    isLoading: authState.isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppText.bodyMedium.copyWith(color: AppColors.muted),
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text(
                          AppStrings.signIn,
                          style: AppText.labelLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
