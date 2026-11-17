import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo de texto padrão do app (mesmo visual em todas as telas) com suporte a validação.
class CampoTexto extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icone;
  final String? hintText;
  final String? suffixText;
  final bool obscureText;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  const CampoTexto({
    super.key,
    required this.controller,
    required this.label,
    this.icone,
    this.hintText,
    this.suffixText,
    this.obscureText = false,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        suffixText: suffixText,
        alignLabelWithHint: maxLines > 1,
        border: const OutlineInputBorder(),
        prefixIcon: icone == null ? null : Icon(icone, color: Colors.teal),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
