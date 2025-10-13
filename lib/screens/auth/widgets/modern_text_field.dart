import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth_constants.dart';

/// Modern Text Field with Glassmorphic Design
///
/// Features:
/// - Floating label
/// - Animated border
/// - Clear button
/// - Icon support
/// - Validation feedback
class ModernTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final String label;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool obscureText;
  final int? maxLength;
  final TextAlign textAlign;
  final VoidCallback? onEditingComplete;
  final bool showClearButton;

  const ModernTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.label,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.obscureText = false,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.onEditingComplete,
    this.showClearButton = true,
  });

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _borderAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AuthConstants.mediumDuration,
    );

    _borderAnimation = Tween<double>(
      begin: 1.5,
      end: 2.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _borderAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: AuthConstants.glassOpacity),
            borderRadius: BorderRadius.circular(AuthConstants.radiusMedium),
            border: Border.all(
              color: _isFocused
                  ? theme.colorScheme.primary
                  : Colors.white.withValues(alpha: AuthConstants.borderOpacity),
              width: _borderAnimation.value,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            maxLength: widget.maxLength,
            textAlign: widget.textAlign,
            inputFormatters: widget.inputFormatters,
            validator: widget.validator,
            onEditingComplete: widget.onEditingComplete,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              labelText: widget.label,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: AuthConstants.labelSize,
              ),
              labelStyle: TextStyle(
                color: _isFocused
                    ? theme.colorScheme.primary
                    : Colors.white.withValues(alpha: 0.7),
                fontSize: AuthConstants.labelSize,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused
                          ? theme.colorScheme.primary
                          : Colors.white70,
                    )
                  : null,
              suffixIcon: widget.showClearButton &&
                      widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () {
                        widget.controller.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
            onChanged: (_) => setState(() {}),
            onTap: () {
              setState(() => _isFocused = true);
              _controller.forward();
            },
            onTapOutside: (_) {
              setState(() => _isFocused = false);
              _controller.reverse();
            },
          ),
        );
      },
    );
  }
}
