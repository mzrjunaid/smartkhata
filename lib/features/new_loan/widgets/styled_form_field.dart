import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'package:smartkhata/core/theme/app_theme.dart';

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
      padding: EdgeInsets.only(bottom: AppTheme.spacingLg),
      child: FormBuilderTextField(
        name: name,
        initialValue: initialValue,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        onChanged: onChanged,
        enabled: enabled,
        style: AppTheme.text(context).bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: AppTheme.text(context).bodyMedium,
          hintStyle: AppTheme.text(context).bodyMedium.copyWith(
            color: AppTheme.colors(context).textTertiary,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: AppTheme.colors(context).textSecondary, size: 20)
              : null,
          prefixText: prefixText,
          prefixStyle: AppTheme.text(context).bodyLarge.copyWith(
            color: AppTheme.colors(context).textSecondary,
          ),
          suffixText: suffixText,
          suffixStyle: AppTheme.text(context).labelBold,
          filled: true,
          fillColor: AppTheme.colors(context).surface,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: AppTheme.spacingMd,
          ),
          border: OutlineInputBorder(
            borderRadius: AppTheme.radiusMd,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppTheme.radiusMd,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppTheme.radiusMd,
            borderSide: BorderSide(
              color: AppTheme.colors(context).primary,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppTheme.radiusMd,
            borderSide: BorderSide(
              color: AppTheme.colors(context).danger,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppTheme.radiusMd,
            borderSide: BorderSide(
              color: AppTheme.colors(context).danger,
              width: 1.5,
            ),
          ),
          errorStyle: AppTheme.text(context).bodySmall.copyWith(
            color: AppTheme.colors(context).danger,
          ),
        ),
      ),
    );
  }
}
