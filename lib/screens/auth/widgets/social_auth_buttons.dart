import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_constants.dart';

/// Modern Social Auth Buttons
///
/// Features:
/// - Google Sign In
/// - Apple Sign In
/// - Glassmorphic design
/// - Animated effects
/// - Loading states
class SocialAuthButtons extends StatelessWidget {
  final VoidCallback onGoogleSignIn;
  final VoidCallback? onAppleSignIn;
  final bool isLoading;

  const SocialAuthButtons({
    super.key,
    required this.onGoogleSignIn,
    this.onAppleSignIn,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Divider with "veya" text
        _buildDivider(),
        const SizedBox(height: AuthConstants.spacingLarge),

        // Google Sign In Button
        _buildGoogleButton(context),

        // Apple Sign In Button (if available)
        if (onAppleSignIn != null) ...[
          const SizedBox(height: AuthConstants.spacingMedium),
          _buildAppleButton(context),
        ],
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AuthConstants.spacingMedium,
          ),
          child: Text(
            'veya',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton(BuildContext context) {
    return _SocialButton(
      onPressed: isLoading ? null : onGoogleSignIn,
      icon: _buildGoogleIcon(),
      label: 'Google ile Devam Et',
      backgroundColor: Colors.white.withValues(alpha: 0.15),
      isLoading: isLoading,
    );
  }

  Widget _buildAppleButton(BuildContext context) {
    return _SocialButton(
      onPressed: isLoading ? null : onAppleSignIn!,
      icon: const Icon(
        Icons.apple,
        color: Colors.white,
        size: 24,
      ),
      label: 'Apple ile Devam Et',
      backgroundColor: Colors.white.withValues(alpha: 0.15),
      isLoading: isLoading,
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(4),
      child: Image.network(
        'https://www.google.com/favicon.ico',
        width: 16,
        height: 16,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.g_mobiledata,
            color: Colors.red,
            size: 16,
          );
        },
      ),
    );
  }
}

/// Individual Social Button Widget
class _SocialButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final Color backgroundColor;
  final bool isLoading;

  const _SocialButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    this.isLoading = false,
  });

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AuthConstants.fastDuration,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
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

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: widget.onPressed != null ? _onTapDown : null,
        onTapUp: widget.onPressed != null ? _onTapUp : null,
        onTapCancel: _onTapCancel,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AuthConstants.fastDuration,
          width: double.infinity,
          height: AuthConstants.buttonHeight,
          decoration: BoxDecoration(
            color: _isPressed
                ? widget.backgroundColor.withValues(alpha: 0.25)
                : widget.backgroundColor,
            borderRadius: BorderRadius.circular(AuthConstants.radiusMedium),
            border: Border.all(
              color: Colors.white.withValues(alpha: _isPressed ? 0.3 : 0.2),
              width: 1.5,
            ),
            boxShadow: _isPressed
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: widget.isLoading
              ? Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    widget.icon,
                    const SizedBox(width: AuthConstants.spacingMedium),
                    Text(
                      widget.label,
                      style: GoogleFonts.poppins(
                        fontSize: AuthConstants.buttonTextSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
