import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Widget que envuelve TextFormField para prevenir errores comunes en Flutter Web
class WebSafeTextFormField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final InputDecoration? decoration;
  final TextStyle? style;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final bool enabled;
  final FocusNode? focusNode;

  const WebSafeTextFormField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.decoration,
    this.style,
    this.onChanged,
    this.onTap,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<WebSafeTextFormField> createState() => _WebSafeTextFormFieldState();
}

class _WebSafeTextFormFieldState extends State<WebSafeTextFormField> {
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    
    // Para web, agregar un delay para evitar problemas de elementos activos
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Configuración específica para Flutter Web
    InputDecoration decoration = widget.decoration ?? InputDecoration(
      labelText: widget.labelText,
      hintText: widget.hintText,
      prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
      suffixIcon: widget.suffixIcon,
    );

    // En web, ajustar la decoración para prevenir problemas
    if (kIsWeb) {
      decoration = decoration.copyWith(
        // Forzar bordes para evitar problemas de renderizado
        border: decoration.border ?? const OutlineInputBorder(),
        enabledBorder: decoration.enabledBorder ?? const OutlineInputBorder(),
        focusedBorder: decoration.focusedBorder ?? const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
        // Configuración específica para evitar elementos nativos
        filled: decoration.filled ?? true,
        fillColor: decoration.fillColor ?? Colors.white,
      );
    }

    Widget textField = TextFormField(
      controller: widget.controller,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      decoration: decoration,
      style: widget.style,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      enabled: widget.enabled,
      focusNode: _focusNode,
      // Configuraciones específicas para web
      autofocus: false,
      enableSuggestions: !kIsWeb, // Deshabilitar sugerencias en web
      autocorrect: !kIsWeb, // Deshabilitar autocorrección en web
    );

    // En web, envolver en un Container para mejor control
    if (kIsWeb) {
      return Container(
        key: ValueKey('web_safe_${widget.controller?.hashCode ?? widget.labelText}'),
        child: Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus && _hasFocus) {
              // Pequeño delay para evitar problemas de elementos activos
              Future.delayed(const Duration(milliseconds: 50), () {
                if (mounted) {
                  FocusScope.of(context).unfocus();
                }
              });
            }
          },
          child: textField,
        ),
      );
    }

    return textField;
  }
}

/// Widget que envuelve DropdownButtonFormField para prevenir errores en Flutter Web
class WebSafeDropdownButtonFormField<T> extends StatefulWidget {
  final T? value;
  final List<DropdownMenuItem<T>>? items;
  final void Function(T?)? onChanged;
  final InputDecoration? decoration;
  final String? Function(T?)? validator;
  final Color? dropdownColor;
  final TextStyle? style;
  final Widget? icon;

  const WebSafeDropdownButtonFormField({
    super.key,
    this.value,
    this.items,
    this.onChanged,
    this.decoration,
    this.validator,
    this.dropdownColor,
    this.style,
    this.icon,
  });

  @override
  State<WebSafeDropdownButtonFormField<T>> createState() => _WebSafeDropdownButtonFormFieldState<T>();
}

class _WebSafeDropdownButtonFormFieldState<T> extends State<WebSafeDropdownButtonFormField<T>> {
  @override
  Widget build(BuildContext context) {
    Widget dropdown = DropdownButtonFormField<T>(
      value: widget.value,
      items: widget.items,
      onChanged: widget.onChanged,
      decoration: widget.decoration,
      validator: widget.validator,
      dropdownColor: widget.dropdownColor,
      style: widget.style,
      icon: widget.icon,
      // Configuraciones específicas para web
      isExpanded: true,
      isDense: kIsWeb ? true : false, // Más compacto en web
    );

    // En web, envolver para mejor control
    if (kIsWeb) {
      return Container(
        key: ValueKey('web_safe_dropdown_${widget.value}'),
        child: dropdown,
      );
    }

    return dropdown;
  }
}
