import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int? maxLines;
  final int? maxLength;
  final Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final String? initialValue;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final Function(String)? onSubmitted;
  final bool isRequired;

  const CustomTextField({
    Key? key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.initialValue,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.isRequired = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          maxLength: maxLength,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          onTap: onTap,
          focusNode: focusNode,
          autofocus: autofocus,
          enabled: enabled,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
            counterText: "",
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isRequired
                    ? const Color(0xFFDDDDDD)
                    : const Color(0xFFEEEEEE),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade500),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
