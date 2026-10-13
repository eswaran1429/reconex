import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_button/custom_button.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_textfield/custom_textfield.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/core/utils/validators.dart';
import 'package:reconex/features/auth/controllers/login_controller.dart';
import 'package:reconex/features/auth/widgets/auth_widgets.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

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
                  24.height,
                  const AuthHeader(title: 'Welcome back', subtitle: 'Log in to continue to your Reconex account'),
                  36.height,
                  const AuthFieldLabel('Email'),
                  CustomTextField(
                    label: 'you@example.com',
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefix: const Icon(Icons.mail_outline_rounded, color: AppColors.grey500, size: 20),
                    validator: Validators.email,
                  ),
                  AppSpacing.xl.height,
                  const AuthFieldLabel('Password'),
                  Obx(
                    () => CustomTextField(
                      label: 'Enter your password',
                      controller: controller.passwordController,
                      obscureText: controller.obscurePassword.value,
                      prefix: const Icon(Icons.lock_outline_rounded, color: AppColors.grey500, size: 20),
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
                      text: 'Log In',
                      gradient: AppColors.gradientButton,
                      textColor: AppColors.white,
                      loading: controller.isLoading.value,
                      onPressed: controller.login,
                    ),
                  ),
                  AppSpacing.xxl.height,
                  AuthSwitchPrompt(prompt: "Don't have an account?", action: 'Sign Up', onTap: controller.goToSignup),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
