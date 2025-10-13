import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_constants.dart';

/// Modern Phone Input Card with Glassmorphic Design
///
/// Features:
/// - Country code selector with flag
/// - Real-time phone number formatting
/// - Validation feedback
/// - Animated transitions
/// - Glassmorphic design
class PhoneInputCard extends StatefulWidget {
  final TextEditingController phoneController;
  final VoidCallback onContinue;
  final bool isLoading;

  const PhoneInputCard({
    super.key,
    required this.phoneController,
    required this.onContinue,
    this.isLoading = false,
  });

  @override
  State<PhoneInputCard> createState() => _PhoneInputCardState();
}

class _PhoneInputCardState extends State<PhoneInputCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _countryCode = '+90';
  String _countryFlag = '🇹🇷';
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    widget.phoneController.addListener(_validatePhone);
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: AuthConstants.slowDuration,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  void _validatePhone() {
    final phone = widget.phoneController.text.replaceAll(' ', '');
    setState(() {
      // Turkish phone: 10 digits (5XX XXX XX XX)
      _isValid = phone.length == 10 && phone.startsWith('5');
    });
  }


  @override
  void dispose() {
    _controller.dispose();
    widget.phoneController.removeListener(_validatePhone);
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
          padding: const EdgeInsets.all(AuthConstants.spacingLarge), // 24px instead of 32px
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

              // Subtitle
              _buildSubtitle(),
              const SizedBox(height: AuthConstants.spacingLarge), // 24px instead of 32px

              // Phone Input Row
              _buildPhoneInputRow(theme),
              const SizedBox(height: AuthConstants.spacingSmall), // 12px instead of 16px

              // Validation hint
              _buildValidationHint(),
              const SizedBox(height: AuthConstants.spacingLarge), // 24px instead of 32px

              // Continue Button
              _buildContinueButton(theme),
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
        'Telefon Numaranız',
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
    return Text(
      'Size SMS ile doğrulama kodu göndereceğiz',
      style: GoogleFonts.poppins(
        fontSize: 14, // 16 → 14
        color: Colors.white.withValues(alpha: 0.7),
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildPhoneInputRow(ThemeData theme) {
    return Row(
      children: [
        // Country Code Selector
        _buildCountryCodeSelector(theme),
        const SizedBox(width: AuthConstants.spacingSmall), // 12px instead of 16px

        // Phone Number Input
        Expanded(
          child: _buildPhoneInput(theme),
        ),
      ],
    );
  }

  Widget _buildCountryCodeSelector(ThemeData theme) {
    return InkWell(
      onTap: _showCountryPicker,
      borderRadius: BorderRadius.circular(AuthConstants.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10, // 16 → 10
          vertical: 14,   // 18 → 14
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: AuthConstants.glassOpacity),
          borderRadius: BorderRadius.circular(AuthConstants.radiusMedium),
          border: Border.all(
            color: Colors.white.withValues(alpha: AuthConstants.borderOpacity),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _countryFlag,
              style: const TextStyle(fontSize: 20), // 24 → 20
            ),
            const SizedBox(width: 6), // 8 → 6
            Text(
              _countryCode,
              style: GoogleFonts.poppins(
                fontSize: 15, // 16 → 15
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 2), // 4 → 2
            Icon(
              Icons.arrow_drop_down,
              color: Colors.white.withValues(alpha: 0.7),
              size: 20, // Add explicit size
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneInput(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: AuthConstants.glassOpacity),
        borderRadius: BorderRadius.circular(AuthConstants.radiusMedium),
        border: Border.all(
          color: _isValid
              ? theme.colorScheme.primary.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: AuthConstants.borderOpacity),
          width: 1.5,
        ),
      ),
      child: TextFormField(
        controller: widget.phoneController,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
          _PhoneNumberFormatter(),
        ],
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 15, // 16 → 15
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0, // 1.2 → 1.0
        ),
        decoration: InputDecoration(
          hintText: '5XX XXX XX XX',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 15, // 16 → 15
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0, // 1.2 → 1.0
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, // 20 → 16
            vertical: 14,   // 18 → 14
          ),
          suffixIcon: _isValid
              ? Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 20, // 24 → 20
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildValidationHint() {
    return AnimatedOpacity(
      opacity: widget.phoneController.text.isNotEmpty && !_isValid ? 1.0 : 0.0,
      duration: AuthConstants.fastDuration,
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 14, // 16 → 14
            color: Colors.orange.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 6), // 8 → 6
          Flexible(
            child: Text(
              'Lütfen geçerli bir telefon numarası girin',
              style: GoogleFonts.poppins(
                fontSize: 11, // 12 → 11
                color: Colors.orange.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(ThemeData theme) {
    return AnimatedContainer(
      duration: AuthConstants.mediumDuration,
      width: double.infinity,
      height: AuthConstants.buttonHeight,
      child: ElevatedButton(
        onPressed: _isValid && !widget.isLoading ? widget.onContinue : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isValid
              ? theme.colorScheme.primary
              : Colors.white.withValues(alpha: 0.2),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.2),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
          elevation: _isValid ? 8 : 0,
          shadowColor: theme.colorScheme.primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AuthConstants.radiusMedium),
          ),
        ),
        child: widget.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Devam Et',
                style: GoogleFonts.poppins(
                  fontSize: AuthConstants.buttonTextSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1F152E),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AuthConstants.radiusXLarge),
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(AuthConstants.spacingLarge),
              child: Text(
                'Ülke Seçin',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            // Countries list
            _buildCountryOption('🇹🇷', 'Türkiye', '+90'),
            const Divider(color: Colors.white10, height: 1),
            _buildCountryOption('🇺🇸', 'United States', '+1'),
            const Divider(color: Colors.white10, height: 1),
            _buildCountryOption('🇬🇧', 'United Kingdom', '+44'),
            const Divider(color: Colors.white10, height: 1),
            _buildCountryOption('🇩🇪', 'Germany', '+49'),

            const SizedBox(height: AuthConstants.spacingLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryOption(String flag, String name, String code) {
    final isSelected = _countryCode == code;

    return InkWell(
      onTap: () {
        setState(() {
          _countryFlag = flag;
          _countryCode = code;
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AuthConstants.spacingLarge,
          vertical: AuthConstants.spacingMedium,
        ),
        color: isSelected
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.transparent,
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: AuthConstants.spacingMedium),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              code,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle,
                color: Color(0xFF7f13ec),
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Phone Number Formatter
/// Formats: 5XX XXX XX XX
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');

    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String formatted = '';
    for (int i = 0; i < text.length && i < 10; i++) {
      if (i == 3 || i == 6 || i == 8) {
        formatted += ' ';
      }
      formatted += text[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length,
      ),
    );
  }
}
