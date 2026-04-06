import 'package:flutter/material.dart';
import 'clipboard_history_widget.dart';

/// TextFormField with integrated clipboard history
class TextFieldWithClipboard extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final TextInputType keyboardType;
  final int maxLines;
  final int minLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool obscureText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Color? iconColor;
  final Color? prefixIconColor;
  final Widget? suffix;

  const TextFieldWithClipboard({
    Key? key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines = 1,
    this.validator,
    this.onChanged,
    this.textInputAction,
    this.focusNode,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.iconColor,
    this.prefixIconColor,
    this.suffix,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: prefixIconColor)
            : null,
        suffixIcon: suffix ?? (suffixIcon != null ? Icon(suffixIcon) : null),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      validator: validator,
      onChanged: onChanged,
      textInputAction: textInputAction,
      focusNode: focusNode,
      obscureText: obscureText,
    );
  }
}

/// TextField with clipboard button in suffix
class InputFieldWithClipboardButton extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final TextInputType keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final IconData? prefixIcon;
  final Color? iconColor;
  final TextInputAction? textInputAction;
  final FocusNode? nextFocusNode;

  const InputFieldWithClipboardButton({
    Key? key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    this.focusNode,
    this.prefixIcon,
    this.iconColor,
    this.textInputAction,
    this.nextFocusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: iconColor)
            : null,
        suffixIcon: ClipboardHistoryButton(
          controller: controller,
          iconColor: iconColor ?? Colors.blue,
          onPasted: () {
            // Optionally move focus to next field
            if (nextFocusNode != null) {
              FocusScope.of(context).requestFocus(nextFocusNode);
            }
          },
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      textInputAction: textInputAction,
      focusNode: focusNode,
    );
  }
}
