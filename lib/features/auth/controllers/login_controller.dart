import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:reconex/data/services/auth_service.dart';
import 'package:reconex/routes/app_routes.dart';

class LoginController extends GetxController {
  final AuthService _authService = Get.find();

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;

  void togglePasswordVisibility() => obscurePassword.toggle();

  Future<void> login() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(formKey.currentState?.validate() ?? false)) return;

    isLoading.value = true;
    try {
      final user = await _authService.login(email: emailController.text.trim(), password: passwordController.text);
      Get.offAllNamed(AppRoutes.home);
      AppSnackbar.success('Welcome back', 'Logged in as ${user.name}');
    } catch (e) {
      AppSnackbar.warning('Login failed', e.toString());
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  void goToSignup() => Get.toNamed(AppRoutes.signup);

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
