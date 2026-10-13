import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/app_widgets/app_widgets.dart';
import 'package:reconex/core/custom_widgets/confirm_dialog/confirm_dialog.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/section_card/section_card.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/data/services/auth_service.dart';
import 'package:reconex/routes/app_routes.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  final AuthService _authService = Get.find();
  late final Future<({String name, String email})?> _user = _authService.currentUser();

  Future<void> _logout() async {
    final confirmed = await AppConfirmDialog.show(
      title: 'Log out?',
      message: 'You will need to log in again to see your domains.',
      confirmText: 'Log out',
      icon: Icons.logout_rounded,
    );
    if (!confirmed) return;
    await _authService.logout();
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 120),
        children: [
          const CustomText(
            text: 'Account',
            fontSize: AppTextTokens.displaySize,
            fontWeight: FontWeight.bold,
            color: AppColors.normalText,
            textAlign: TextAlign.left,
          ),
          AppSpacing.xl.height,
          FutureBuilder(
            future: _user,
            builder: (context, snapshot) => _ProfileCard(user: snapshot.data),
          ),
          AppSpacing.lg.height,
          SectionCard(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: buildSettingsTile(
              icon: Icons.logout_rounded,
              iconColor: AppColors.red500,
              iconBgColor: AppColors.red50,
              title: 'Log out',
              titleColor: AppColors.red500,
              onTap: _logout,
            ),
          ),
        ],
      ),
    );
  }
}

/// Initials avatar with the signed-in user's name and email.
class _ProfileCard extends StatelessWidget {
  final ({String name, String email})? user;

  const _ProfileCard({required this.user});

  String get _initials {
    final parts = (user?.name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.gradientButton),
            child: CustomText(
              text: _initials,
              fontSize: AppTextTokens.titleSize,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          AppSpacing.lg.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: user?.name ?? 'Signed in',
                  fontSize: AppTextTokens.titleSmSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.normalText,
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppSpacing.xs.height,
                Row(
                  children: [
                    const Icon(Icons.mail_outline_rounded, size: 16, color: AppColors.grey500),
                    AppSpacing.xs.width,
                    Expanded(
                      child: CustomText(
                        text: user?.email ?? 'Log in again to show your email',
                        fontSize: AppTextTokens.bodySmSize,
                        color: AppColors.grey500,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
