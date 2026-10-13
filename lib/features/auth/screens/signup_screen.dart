import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_button/custom_button.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_textfield/custom_textfield.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/core/utils/validators.dart';
import 'package:reconex/features/auth/controllers/signup_controller.dart';
import 'package:reconex/features/auth/widgets/auth_widgets.dart';

class SignupScreen extends GetView<SignupController> {
  const SignupScreen({super.key});

  static const Icon _nameIcon = Icon(Icons.person_outline_rounded, color: AppColors.grey500, size: 20);
  static const Icon _mailIcon = Icon(Icons.mail_outline_rounded, color: AppColors.grey500, size: 20);
  static const Icon _lockIcon = Icon(Icons.lock_outline_rounded, color: AppColors.grey500, size: 20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthHeader(title: 'Create account', subtitle: 'Sign up to get started with Reconex'),
                  28.height,
                  const AuthFieldLabel('Full Name'),
                  CustomTextField(
                    label: 'John Doe',
                    controller: controller.nameController,
                    textCapitalization: TextCapitalization.words,
                    prefix: _nameIcon,
                    validator: Validators.name,
                  ),
                  AppSpacing.lg.height,
                  const AuthFieldLabel('Email'),
                  CustomTextField(
                    label: 'you@example.com',
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefix: _mailIcon,
                    validator: Validators.email,
                  ),
                  AppSpacing.lg.height,
                  const AuthFieldLabel('Password'),
                  Obx(
                    () => CustomTextField(
                      label: 'At least 8 characters',
                      controller: controller.passwordController,
                      obscureText: controller.obscurePassword.value,
                      prefix: _lockIcon,
                      suffix: PasswordVisibilityToggle(
                        obscured: controller.obscurePassword.value,
                        onTap: controller.togglePasswordVisibility,
                      ),
                      validator: Validators.password,
                    ),
                  ),
                  AppSpacing.xxl.height,
                  Obx(
                    () => CustomButton(
                      text: 'Sign Up',
                      gradient: AppColors.gradientButton,
                      textColor: AppColors.white,
                      loading: controller.isLoading.value,
                      onPressed: controller.signup,
                    ),
                  ),
                  AppSpacing.xl.height,
                  AuthSwitchPrompt(prompt: 'Already have an account?', action: 'Log In', onTap: controller.goToLogin),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
