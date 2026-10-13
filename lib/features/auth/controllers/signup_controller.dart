import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:reconex/data/services/auth_service.dart';
import 'package:reconex/routes/app_routes.dart';

class SignupController extends GetxController {
  final AuthService _authService = Get.find();

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;

  void togglePasswordVisibility() => obscurePassword.toggle();

  Future<void> signup() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(formKey.currentState?.validate() ?? false)) return;

    isLoading.value = true;
    try {
      await _authService.register(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      isLoading.value = false;
      goToLogin();
      AppSnackbar.success('Account created', 'Please log in to continue');
    } catch (e) {
      AppSnackbar.warning('Signup failed', e.toString());
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  // Get.back() closes an open snackbar instead of the route, so navigate explicitly.
  void goToLogin() => Get.offAllNamed(AppRoutes.login);

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
