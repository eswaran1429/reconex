import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_button/custom_button.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/custom_textfield/custom_textfield.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/data/models/network.dart';
import 'package:reconex/data/services/network_service.dart';
import 'package:reconex/features/auth/widgets/auth_widgets.dart';

/// Add a network, or rename one when [network] is given. Resolves to true when saved.
class NetworkFormSheet extends StatefulWidget {
  final NetworkProfile? network;

  const NetworkFormSheet({super.key, this.network});

  static Future<bool?> show({NetworkProfile? network}) => Get.bottomSheet<bool>(
    NetworkFormSheet(network: network),
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
  );

  @override
  State<NetworkFormSheet> createState() => _NetworkFormSheetState();
}

class _NetworkFormSheetState extends State<NetworkFormSheet> {
  final NetworkService _networkService = Get.find();
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.network?.name);
  final _subnetController = TextEditingController();
  bool _saving = false;

  bool get _isEdit => widget.network != null;

  @override
  void dispose() {
    _nameController.dispose();
    _subnetController.dispose();
    super.dispose();
  }

  static String? _validateName(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Name is required';
    if (value.length > 100) return 'Name must be at most 100 characters';
    return null;
  }

  // Shape only; the server decides which ranges are allowed.
  static String? _validateSubnet(String? v) {
    final value = v?.trim() ?? '';
    if (!RegExp(r'^\d{1,3}(\.\d{1,3}){3}/\d{1,2}$').hasMatch(value)) return 'Enter a range like 192.168.1.0/24';
    return null;
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final name = _nameController.text.trim();
    try {
      if (_isEdit) {
        await _networkService.rename(widget.network!.id, name);
      } else {
        await _networkService.add(name: name, subnet: _subnetController.text.trim());
      }
      if (!mounted) return;
      // Navigator.pop, not Get.back: Get.back closes an open snackbar instead of the sheet.
      Navigator.of(context).pop(true);
      AppSnackbar.success(_isEdit ? 'Network renamed' : 'Network added', name);
    } catch (e) {
      AppSnackbar.warning(_isEdit ? 'Rename failed' : 'Could not add network', e.toString());
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                AppSpacing.xl.height,
                CustomText(
                  text: _isEdit ? 'Rename network' : 'Add network',
                  fontSize: AppTextTokens.titleSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.normalText,
                  textAlign: TextAlign.left,
                ),
                if (!_isEdit) ...[
                  AppSpacing.sm.height,
                  const CustomText(
                    text: 'Only add networks you own or are allowed to check.',
                    fontSize: 13,
                    color: AppColors.grey500,
                    textAlign: TextAlign.left,
                  ),
                ],
                AppSpacing.xl.height,
                const AuthFieldLabel('Name'),
                CustomTextField(
                  label: 'Home Wi-Fi',
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  prefix: const Icon(Icons.label_outline_rounded, color: AppColors.grey500, size: 20),
                  validator: _validateName,
                ),
                if (!_isEdit) ...[
                  AppSpacing.lg.height,
                  const AuthFieldLabel('Address range'),
                  CustomTextField(
                    label: '192.168.1.0/24',
                    controller: _subnetController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefix: const Icon(Icons.lan_outlined, color: AppColors.grey500, size: 20),
                    validator: _validateSubnet,
                  ),
                  AppSpacing.sm.height,
                  const CustomText(
                    text: 'Private ranges only (10.x, 172.16–31.x, 192.168.x), up to /22. Can\'t be changed later.',
                    fontSize: 12,
                    color: AppColors.grey500,
                    textAlign: TextAlign.left,
                  ),
                ],
                AppSpacing.xl.height,
                CustomButton(
                  text: _isEdit ? 'Save' : 'Add network',
                  gradient: AppColors.gradientButton,
                  textColor: AppColors.white,
                  loading: _saving,
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
