import 'dart:async';

import 'package:get/get.dart';
import 'package:reconex/data/services/auth_service.dart';
import 'package:reconex/routes/app_routes.dart';

class SplashController extends GetxController {
  final AuthService _authService = Get.find();
  Timer? _timer;

  @override
  void onReady() {
    super.onReady();
    _timer = Timer(const Duration(milliseconds: 2500), _route);
  }

  // An expired token is caught by the first API call's 401, which returns the user to login.
  Future<void> _route() async {
    final loggedIn = await _authService.isLoggedIn();
    Get.offAllNamed(loggedIn ? AppRoutes.home : AppRoutes.login);
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
