import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../lender_dashboard/theme/dashboard_theme.dart';

/// Reusable themed form field wrapper that applies consistent styling
/// from [DashboardTheme] to every [FormBuilderTextField].
///
/// Eliminates repetitive decoration boilerplate across the form.
class StyledFormField extends StatelessWidget {
  const StyledFormField({
    super.key,
    required this.name,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.prefixText,
    this.suffixText,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
    this.maxLines = 1,
    this.onChanged,
    this.initialValue,
    this.enabled = true,
  });

  final String name;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final String? prefixText;
  final String? suffixText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<dynamic>? inputFormatters;
  final int maxLines;
  final ValueChanged<String?>? onChanged;
  final String? initialValue;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DashboardTheme.spacingLg),
      child: FormBuilderTextField(
        name: name,
        initialValue: initialValue,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        onChanged: onChanged,
        enabled: enabled,
        style: DashboardTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: DashboardTheme.bodyMedium,
          hintStyle: DashboardTheme.bodyMedium.copyWith(
            color: DashboardTheme.textTertiary,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: DashboardTheme.textSecondary, size: 20)
              : null,
          prefixText: prefixText,
          prefixStyle: DashboardTheme.bodyLarge.copyWith(
            color: DashboardTheme.textSecondary,
          ),
          suffixText: suffixText,
          suffixStyle: DashboardTheme.labelBold,
          filled: true,
          fillColor: DashboardTheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DashboardTheme.spacingLg,
            vertical: DashboardTheme.spacingMd,
          ),
          border: OutlineInputBorder(
            borderRadius: DashboardTheme.radiusMd,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: DashboardTheme.radiusMd,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: DashboardTheme.radiusMd,
            borderSide: const BorderSide(
              color: DashboardTheme.primary,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: DashboardTheme.radiusMd,
            borderSide: const BorderSide(
              color: DashboardTheme.danger,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: DashboardTheme.radiusMd,
            borderSide: const BorderSide(
              color: DashboardTheme.danger,
              width: 1.5,
            ),
          ),
          errorStyle: DashboardTheme.bodySmall.copyWith(
            color: DashboardTheme.danger,
          ),
        ),
      ),
    );
  }
}
