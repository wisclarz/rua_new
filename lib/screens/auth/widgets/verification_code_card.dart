import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'auth_constants.dart';

/// Modern Verification Code Card
///
/// Features:
/// - 6-digit PIN input
/// - Individual animated boxes
/// - Auto-focus on next digit
/// - Backspace support
/// - Paste support
/// - Resend timer
/// - Glassmorphic design
class VerificationCodeCard extends StatefulWidget {
  final String phoneNumber;
  final Function(String code) onVerify;
  final VoidCallback onResend;
  final bool isLoading;

  const VerificationCodeCard({
    super.key,
    required this.phoneNumber,
    required this.onVerify,
    required this.onResend,
    this.isLoading = false,
  });

  @override
  State<VerificationCodeCard> createState() => _VerificationCodeCardState();
}

class _VerificationCodeCardState extends State<VerificationCodeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  Timer? _timer;
  int _remainingSeconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startTimer();

    // Auto-focus first box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _setupAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: AuthConstants.slowDuration,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
  }

  void _startTimer() {
    _remainingSeconds = 60;
    _canResend = false;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  void _onDigitChanged(int index, String value) {
    if (value.isEmpty) {
      // Backspace: Move to previous
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      return;
    }

    // Handle paste
    if (value.length > 1) {
      _handlePaste(value, index);
      return;
    }

    // Single digit: Move to next
    if (index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else {
      // Last digit entered: Verify
      _verifyCode();
    }
  }

  void _handlePaste(String value, int startIndex) {
    final digits = value.replaceAll(RegExp(r'\D'), ''); // Remove non-digits

    for (int i = 0; i < digits.length && (startIndex + i) < 6; i++) {
      _controllers[startIndex + i].text = digits[i];
    }

    // Focus on next empty box or last box
    final nextEmptyIndex = _controllers.indexWhere((c) => c.text.isEmpty);
    if (nextEmptyIndex != -1) {
      _focusNodes[nextEmptyIndex].requestFocus();
    } else {
      _focusNodes[5].requestFocus();
      _verifyCode();
    }
  }

  void _verifyCode() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 6) {
      // Unfocus all
      for (var node in _focusNodes) {
        node.unfocus();
      }
      widget.onVerify(code);
    }
  }

  void _clearCode() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _handleResend() {
    _clearCode();
    _startTimer();
    widget.onResend();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(AuthConstants.spacingLarge), // 32 → 24
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: AuthConstants.glassOpacity),
            borderRadius: BorderRadius.circular(AuthConstants.radiusXLarge),
            border: Border.all(
              color: Colors.white.withValues(alpha: AuthConstants.borderOpacity),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: AuthConstants.shadowBlur,
                offset: AuthConstants.shadowOffset,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              _buildTitle(),
              const SizedBox(height: AuthConstants.spacingXSmall),

              // Subtitle with phone number
              _buildSubtitle(),
              const SizedBox(height: AuthConstants.spacingLarge), // 32 → 24

              // PIN Input Boxes
              _buildPinBoxes(theme),
              const SizedBox(height: AuthConstants.spacingMedium), // 24 → 16

              // Resend section
              _buildResendSection(theme),
              const SizedBox(height: AuthConstants.spacingMedium), // 24 → 16

              // Loading indicator or clear button
              if (widget.isLoading) _buildLoadingIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Color(0xFF7f13ec),
          Color(0xFF9B4DE0),
        ],
      ).createShader(bounds),
      child: Text(
        'Doğrulama Kodu',
        style: GoogleFonts.poppins(
          fontSize: 24, // 28 → 24
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(
          fontSize: 14, // 16 → 14
          color: Colors.white.withValues(alpha: 0.7),
          fontWeight: FontWeight.w400,
        ),
        children: [
          const TextSpan(text: 'SMS ile gönderilen kodu girin\n'),
          TextSpan(
            text: widget.phoneNumber,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinBoxes(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return _buildPinBox(index, theme);
      }),
    );
  }

  Widget _buildPinBox(int index, ThemeData theme) {
    final hasFocus = _focusNodes[index].hasFocus;
    final hasValue = _controllers[index].text.isNotEmpty;

    return AnimatedContainer(
      duration: AuthConstants.fastDuration,
      width: 46, // 50 → 46
      height: 56, // 60 → 56
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: AuthConstants.glassOpacity),
        borderRadius: BorderRadius.circular(AuthConstants.radiusMedium),
        border: Border.all(
          color: hasFocus
              ? theme.colorScheme.primary
              : hasValue
                  ? theme.colorScheme.primary.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: AuthConstants.borderOpacity),
          width: hasFocus ? 2.5 : 1.5,
        ),
        boxShadow: hasFocus
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: GoogleFonts.poppins(
          fontSize: 22, // 24 → 22
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) => _onDigitChanged(index, value),
        onTap: () {
          // Select all on tap for easier editing
          _controllers[index].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controllers[index].text.length,
          );
        },
      ),
    );
  }

  Widget _buildResendSection(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          if (!_canResend)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  'Yeni kod: $_remainingSeconds saniye',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          if (_canResend)
            TextButton(
              onPressed: _handleResend,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AuthConstants.spacingLarge,
                  vertical: AuthConstants.spacingSmall,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Yeni Kod Gönder',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: AuthConstants.spacingMedium),
          Text(
            'Doğrulanıyor...',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
