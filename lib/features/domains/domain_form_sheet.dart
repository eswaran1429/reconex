import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_button/custom_button.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/custom_widgets/custom_textfield/custom_textfield.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/data/models/domain.dart';
import 'package:reconex/data/services/domain_service.dart';
import 'package:reconex/features/auth/widgets/auth_widgets.dart';

/// Bottom sheet to add a domain, or edit one when [domain] is given. Resolves to true when saved.
class DomainFormSheet extends StatefulWidget {
  final Domain? domain;

  const DomainFormSheet({super.key, this.domain});

  static Future<bool?> show({Domain? domain}) => Get.bottomSheet<bool>(
    DomainFormSheet(domain: domain),
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
  );

  @override
  State<DomainFormSheet> createState() => _DomainFormSheetState();
}

class _DomainFormSheetState extends State<DomainFormSheet> {
  final DomainService _domainService = Get.find();
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.domain?.name);
  late final _urlController = TextEditingController(text: widget.domain?.url ?? 'https://');
  late bool _active = widget.domain?.isActive ?? true;
  bool _saving = false;

  bool get _isEdit => widget.domain != null;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  static String? _validateName(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Name is required';
    if (value.length > 100) return 'Name must be at most 100 characters';
    return null;
  }

  static String? _validateUrl(String? v) {
    final uri = Uri.tryParse(v?.trim() ?? '');
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) {
      return 'Enter a URL starting with http:// or https://';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    try {
      if (_isEdit) {
        await _domainService.update(widget.domain!.id, name: name, url: url, status: _active ? 'ACTIVE' : 'INACTIVE');
      } else {
        await _domainService.add(name: name, url: url);
      }
      if (!mounted) return;
      // Navigator.pop, not Get.back: Get.back closes an open snackbar instead of the sheet.
      Navigator.of(context).pop(true);
      AppSnackbar.success(_isEdit ? 'Domain updated' : 'Domain added', name);
    } catch (e) {
      AppSnackbar.warning(_isEdit ? 'Update failed' : 'Could not add domain', e.toString());
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // No viewInsets padding here: Get.bottomSheet already pads for the keyboard.
    return SafeArea(
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
                text: _isEdit ? 'Edit domain' : 'Add domain',
                fontSize: AppTextTokens.titleSize,
                fontWeight: FontWeight.bold,
                color: AppColors.normalText,
                textAlign: TextAlign.left,
              ),
              AppSpacing.xl.height,
              const AuthFieldLabel('Name'),
              CustomTextField(
                label: 'My website',
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                prefix: const Icon(Icons.label_outline_rounded, color: AppColors.grey500, size: 20),
                validator: _validateName,
              ),
              AppSpacing.lg.height,
              const AuthFieldLabel('URL'),
              CustomTextField(
                label: 'https://example.com',
                controller: _urlController,
                keyboardType: TextInputType.url,
                prefix: const Icon(Icons.link_rounded, color: AppColors.grey500, size: 20),
                validator: _validateUrl,
              ),
              if (_isEdit) ...[
                AppSpacing.md.height,
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                  activeThumbColor: AppColors.primary,
                  title: const CustomText(
                    text: 'Active',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.normalText,
                    textAlign: TextAlign.left,
                  ),
                  subtitle: const CustomText(
                    text: 'Inactive domains stay saved but are not monitored.',
                    fontSize: 12,
                    color: AppColors.grey500,
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
              AppSpacing.xl.height,
              CustomButton(
                text: _isEdit ? 'Save changes' : 'Add domain',
                gradient: AppColors.gradientButton,
                textColor: AppColors.white,
                loading: _saving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
