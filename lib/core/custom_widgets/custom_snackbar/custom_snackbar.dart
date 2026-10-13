import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';

class AppSnackbar {
  AppSnackbar._();
  static const Duration _dedupeWindow = Duration(seconds: 4);

  static String? _lastKey;
  static DateTime? _lastShownAt;

  static bool _isRepeat(String title, String message) {
    final String key = '$title|$message';
    final DateTime now = DateTime.now();
    if (_lastKey == key && _lastShownAt != null && now.difference(_lastShownAt!) < _dedupeWindow) {
      return true;
    }
    _lastKey = key;
    _lastShownAt = now;
    return false;
  }

  static void success(String title, String message) => _show(title, message, AppColors.success, Icons.check_rounded);
  static void warning(String title, String message) =>
      _show(title, message, AppColors.warning, Icons.warning_amber_rounded, duration: const Duration(seconds: 4));

  static void info(String title, String message) => _show(title, message, AppColors.info, Icons.bolt_rounded);

  static void _show(
    String title,
    String message,
    Color accent,
    IconData icon, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (_isRepeat(title, message)) return;
    HapticFeedback.lightImpact();
    Get.showSnackbar(
      GetSnackBar(
        backgroundColor: AppColors.transparent,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.symmetric(horizontal: 14),
        snackPosition: SnackPosition.TOP,
        duration: duration,
        animationDuration: const Duration(milliseconds: 400),
        forwardAnimationCurve: Curves.easeOutCubic,
        reverseAnimationCurve: Curves.easeInCubic,
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
        messageText: _SnackCard(title: title, message: message, accent: accent, icon: icon, duration: duration),
      ),
    );
  }
}

class _SnackCard extends StatelessWidget {
  const _SnackCard({
    required this.title,
    required this.message,
    required this.accent,
    required this.icon,
    required this.duration,
  });

  final String title;
  final String message;
  final Color accent;
  final IconData icon;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final bool hasMessage = message.trim().isNotEmpty;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Material(
          color: AppColors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(color: accent.withValues(alpha: 0.28), blurRadius: 22, offset: const Offset(0, 8)),
                BoxShadow(color: AppColors.black.withValues(alpha: 0.22), blurRadius: 26, offset: const Offset(0, 12)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accent.withValues(alpha: 0.35)),
                        ),
                        child: Icon(icon, color: accent, size: 20),
                      ),
                      13.width,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomText(
                              text: title,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.normalText,
                              textAlign: TextAlign.left,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              letterSpacing: 0.1,
                              height: 1.15,
                            ),
                            if (hasMessage) ...[
                              3.height,
                              CustomText(
                                text: message,
                                fontSize: 13,
                                color: AppColors.normalText.withValues(alpha: 0.72),
                                textAlign: TextAlign.left,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                height: 1.35,
                              ),
                            ],
                          ],
                        ),
                      ),
                      6.width,
                      GestureDetector(
                        onTap: Get.closeCurrentSnackbar,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.close_rounded, size: 17, color: AppColors.white.withValues(alpha: 0.45)),
                        ),
                      ),
                    ],
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 0.0),
                  duration: duration,
                  curve: Curves.linear,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value.clamp(0.0, 1.0),
                    minHeight: 2.5,
                    backgroundColor: AppColors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
