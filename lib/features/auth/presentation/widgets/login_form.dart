import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';

class LoginForm extends StatefulWidget {
  final bool isLoading;
  final String? errorMessage;
  final void Function(String username, String password) onSubmit;

  const LoginForm({
    super.key,
    required this.isLoading,
    required this.onSubmit,
    this.errorMessage,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _passwordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      widget.onSubmit(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Username Field ────────────────────────────
          AppTextField(
            hintText: 'Username',
            controller: _usernameController,
            focusNode: _usernameFocus,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            enabled: !widget.isLoading,
            onEditingComplete: () =>
                FocusScope.of(context).requestFocus(_passwordFocus),
            suffixIcon: const Padding(
              padding: EdgeInsets.only(right: AppDimensions.spaceMD),
              child: Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary,
                size: AppDimensions.iconLG,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your username';
              }
              return null;
            },
          ),

          const SizedBox(height: AppDimensions.loginFieldSpacing),

          // ── Password Field ────────────────────────────
          AppTextField(
            hintText: 'Password',
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: !_passwordVisible,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            enabled: !widget.isLoading,
            onEditingComplete: _submit,
            suffixIcon: GestureDetector(
              onTap: () =>
                  setState(() => _passwordVisible = !_passwordVisible),
              child: Padding(
                padding:
                    const EdgeInsets.only(right: AppDimensions.spaceMD),
                child: Icon(
                  _passwordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.primary,
                  size: AppDimensions.iconLG,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your password';
              }
              if (value.trim().length < 4) {
                return 'Password is too short';
              }
              return null;
            },
          ),

          const SizedBox(height: AppDimensions.spaceXL),

          // ── Error Message ─────────────────────────────
          if (widget.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space,
                vertical: AppDimensions.spaceSM,
              ),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusSM),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: AppDimensions.iconMD,
                  ),
                  const SizedBox(width: AppDimensions.spaceSM),
                  Expanded(
                    child: Text(
                      widget.errorMessage!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space),
          ],

          // ── Login Button ──────────────────────────────
          AppButton(
            label: 'Log in',
            isLoading: widget.isLoading,
            onPressed: _submit,
            prefixIcon: widget.isLoading
                ? null
                : const Icon(
                    Icons.login_rounded,
                    color: AppColors.primary,
                    size: AppDimensions.iconMD,
                  ),
          ),
        ],
      ),
    );
  }
}
