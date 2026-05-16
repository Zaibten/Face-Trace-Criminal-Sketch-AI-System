// ignore_for_file: prefer_const_literals_to_create_immutables

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/global_variables.dart';
import '../../../constants/utils.dart';
import '../services/auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN CONSTANTS  (mirrors home_screen.dart _C)
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg           = Color(0xFF080C12);
  static const surface      = Color(0xFF0F1923);
  static const card         = Color(0xFF131F2E);
  static const border       = Color(0xFF1E3050);
  static const borderHi     = Color(0xFF2D4E7A);
  static const blue         = Color(0xFF4D9FFF);
  static const cyan         = Color(0xFF00D4FF);
  static const green        = Color(0xFF00E676);
  static const red          = Color(0xFFFF5252);
  static const amber        = Color(0xFFFFD740);
  static const textPrimary  = Color(0xFFECF0F5);
  static const textSecond   = Color(0xFF8BAAC8);
  static const textMuted    = Color(0xFF4A6580);
  static const textUrdu     = Color(0xFF6B8FAF);

  static const headerGrad = LinearGradient(
    colors: [Color(0xFF0A1628), Color(0xFF0D2040), Color(0xFF0A1628)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const blueGrad = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const greenGrad = LinearGradient(
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const generateGrad = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF1976D2), Color(0xFF1565C0)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static const tsHint = TextStyle(color: textMuted, fontSize: 13);
  static const tsUrdu = TextStyle(color: textUrdu,  fontSize: 11, height: 1.4);
}

// ─────────────────────────────────────────────────────────────────────────────
//  RADAR PAINTER  (same as HomeScreen)
// ─────────────────────────────────────────────────────────────────────────────
class _RadarPainter extends CustomPainter {
  final double angle;
  _RadarPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final maxR = math.min(cx, cy);
    final paint = Paint()..style = PaintingStyle.stroke;
    for (int i = 1; i <= 4; i++) {
      paint.color = _C.blue.withOpacity(0.08);
      paint.strokeWidth = 0.5;
      canvas.drawCircle(Offset(cx, cy), maxR * i / 4, paint);
    }
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: angle - 1.2,
        endAngle: angle,
        colors: [Colors.transparent, _C.blue.withOpacity(0.3)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: maxR))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), maxR, sweepPaint);
    paint
      ..color = _C.blue.withOpacity(0.7)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + maxR * math.cos(angle), cy + maxR * math.sin(angle)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_RadarPainter o) => o.angle != angle;
}

// ─────────────────────────────────────────────────────────────────────────────
//  GRID PATTERN PAINTER  (same as HomeScreen)
// ─────────────────────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = _C.blue.withOpacity(0.04)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 24)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += 24)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  PULSE DOT  (same as HomeScreen)
// ─────────────────────────────────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  const _PulseDot({this.color = _C.green, this.size = 8});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: Curves.easeInOut);

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.color,
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(0.6 * _a.value),
            blurRadius: 8 * _a.value,
            spreadRadius: 2 * _a.value,
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  AUTH SCREEN
// ─────────────────────────────────────────────────────────────────────────────
enum Gender { male, female }

class AuthScreen extends StatefulWidget {
  static const String routeName = '/auth_screen';
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with TickerProviderStateMixin {

  final AuthService _authService = AuthService();

  // Controllers
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _scrollCtrl   = ScrollController();

  // State
  bool _isLoginMode       = true;
  bool _isMale            = true;
  bool _isPasswordVisible = false;
  bool _isLoading         = false;
  bool _rememberMe        = false;

  // Animation controllers
  late final AnimationController _radarCtrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..repeat();

  late final AnimationController _entryCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  late final AnimationController _switchCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

  late final AnimationController _pulseCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
        ..repeat(reverse: true);

  late final Animation<double> _entryFade  =
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
  late final Animation<double> _entrySlide =
      Tween<double>(begin: 40, end: 0)
          .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
  late final Animation<double> _switchFade =
      CurvedAnimation(parent: _switchCtrl, curve: Curves.easeInOut);
  late final Animation<double> _pulseAnim  =
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () => _entryCtrl.forward());
    _switchCtrl.value = 1;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose();
    _scrollCtrl.dispose();
    _radarCtrl.dispose(); _entryCtrl.dispose();
    _switchCtrl.dispose(); _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Mode toggle ─────────────────────────────────────────────────────────────
  void _toggleMode(bool loginMode) {
    if (_isLoginMode == loginMode) return;
    HapticFeedback.selectionClick();
    _switchCtrl.reverse().then((_) {
      setState(() => _isLoginMode = loginMode);
      _nameCtrl.clear(); _emailCtrl.clear(); _passCtrl.clear();
      _switchCtrl.forward();
    });
  }

  // ── Snackbar ────────────────────────────────────────────────────────────────
  void _snack(String msg, [Color color = _C.red]) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(color: _C.textPrimary)),
        backgroundColor: color.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ));

  // ── Validation ───────────────────────────────────────────────────────────────
  bool _isNameValid(String n) => RegExp(r'^[a-zA-Z\s]+$').hasMatch(n);
  bool _isEmailValid(String e) =>
      RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$').hasMatch(e);

  // ── Actions ─────────────────────────────────────────────────────────────────
  void _handleAction() {
    HapticFeedback.mediumImpact();
    if (_isLoginMode) {
      if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
        _snack('Please fill all login fields / تمام خانے بھریں'); return;
      }
      if (!_isEmailValid(_emailCtrl.text)) {
        _snack('Invalid email format / غلط ای میل'); return;
      }
      setState(() => _isLoading = true);
      _authService.signInUser(
        context: context,
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _isLoading = false);
      });
    } else {
      if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
        _snack('Please fill all fields / تمام خانے بھریں'); return;
      }
      if (!_isNameValid(_nameCtrl.text)) {
        _snack('Invalid name / غلط نام (letters only)'); return;
      }
      if (_passCtrl.text.length < 8) {
        _snack('Password must be 8+ characters / پاس ورڈ کم از کم 8 حروف'); return;
      }
      if (!_isEmailValid(_emailCtrl.text)) {
        _snack('Invalid email / غلط ای میل'); return;
      }
      setState(() => _isLoading = true);
      _authService.signUpUser(
        context: context,
        email: _emailCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        password: _passCtrl.text,
        gender: _isMale ? 'male' : 'female',
      );
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // Grid background (full screen)
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          // Decorative radar blobs
          Positioned(
            top: -60, right: -60,
            child: _buildGlowBlob(180, _C.blue.withOpacity(0.06)),
          ),
          Positioned(
            bottom: 100, left: -80,
            child: _buildGlowBlob(200, _C.cyan.withOpacity(0.04)),
          ),

          // Main scrollable content
          SafeArea(
            child: AnimatedBuilder(
              animation: _entryCtrl,
              builder: (_, child) => Opacity(
                opacity: _entryFade.value,
                child: Transform.translate(
                  offset: Offset(0, _entrySlide.value),
                  child: child,
                ),
              ),
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildTabRow(),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _switchFade,
                      child: _isLoginMode ? _buildLoginForm() : _buildSignupForm(),
                    ),
                    const SizedBox(height: 28),
                    _buildActionButton(),
                    const SizedBox(height: 24),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    _buildSocialRow(),
                    const SizedBox(height: 16),
                    _buildFooterSwitch(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Glow blob helper ────────────────────────────────────────────────────────
  Widget _buildGlowBlob(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: size * 0.6, spreadRadius: size * 0.1)]),
  );

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      // Radar animation
      AnimatedBuilder(
        animation: _radarCtrl,
        builder: (_, __) => SizedBox(
          width: 56, height: 56,
          child: CustomPaint(
            painter: _RadarPainter(_radarCtrl.value * 2 * math.pi),
          ),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('FACE', style: TextStyle(
                color: _C.blue, fontSize: 26,
                fontWeight: FontWeight.w900, letterSpacing: 3)),
            const Text('TRACE', style: TextStyle(
                color: _C.textPrimary, fontSize: 26,
                fontWeight: FontWeight.w900, letterSpacing: 3)),
            const SizedBox(width: 10),
            const _PulseDot(size: 7),
          ]),
          const Text('AI FORENSIC SYSTEM  •  فرانزک سسٹم',
              style: TextStyle(color: _C.textMuted, fontSize: 9,
                  letterSpacing: 2, fontWeight: FontWeight.w500)),
        ]),
      ),
    ],
  );

  // ── Tab row (Login / Signup) ─────────────────────────────────────────────────
  Widget _buildTabRow() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: _C.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _C.border),
    ),
    child: Row(children: [
      _tab('Login', 'لاگ ان', true),
      _tab('Sign Up', 'سائن اپ', false),
    ]),
  );

  Widget _tab(String label, String urdu, bool isLogin) {
    final active = _isLoginMode == isLogin;
    return Expanded(
      child: GestureDetector(
        onTap: () => _toggleMode(isLogin),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: active ? _C.blueGrad : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [BoxShadow(color: _C.blue.withOpacity(0.25),
                    blurRadius: 16, offset: const Offset(0, 4))]
                : null,
          ),
          child: Column(children: [
            Text(label,
                style: TextStyle(
                  color: active ? Colors.white : _C.textMuted,
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                  letterSpacing: 0.5,
                )),
            Text(urdu,
                style: TextStyle(
                  color: active ? Colors.white70 : _C.textMuted,
                  fontSize: 10,
                )),
          ]),
        ),
      ),
    );
  }

  // ── Login form ───────────────────────────────────────────────────────────────
  Widget _buildLoginForm() => Column(children: [
    _buildInfoBanner(
      icon: Icons.shield_outlined,
      en: 'Enter your credentials to access the forensic system',
      ur: 'سسٹم تک رسائی کے لیے معلومات درج کریں',
      color: _C.blue,
    ),
    const SizedBox(height: 16),
    _buildField(
      controller: _emailCtrl,
      icon: Icons.alternate_email_rounded,
      hint: 'Email address  /  ای میل',
      keyboardType: TextInputType.emailAddress,
    ),
    const SizedBox(height: 12),
    _buildPasswordField(),
    const SizedBox(height: 12),
    _buildRememberRow(),
  ]);

  // ── Signup form ──────────────────────────────────────────────────────────────
  Widget _buildSignupForm() => Column(children: [
    _buildInfoBanner(
      icon: Icons.verified_user_outlined,
      en: 'Create your account to join the FaceTrace system',
      ur: 'فیس ٹریس سسٹم میں شامل ہونے کے لیے اکاؤنٹ بنائیں',
      color: _C.green,
    ),
    const SizedBox(height: 16),
    _buildField(
      controller: _nameCtrl,
      icon: Icons.badge_outlined,
      hint: 'Full name  /  پورا نام',
    ),
    const SizedBox(height: 12),
    _buildField(
      controller: _emailCtrl,
      icon: Icons.alternate_email_rounded,
      hint: 'Email address  /  ای میل',
      keyboardType: TextInputType.emailAddress,
    ),
    const SizedBox(height: 12),
    _buildPasswordField(),
    const SizedBox(height: 16),
    _buildGenderSelector(),
    const SizedBox(height: 12),
    _buildTermsBanner(),
  ]);

  // ── Info banner ──────────────────────────────────────────────────────────────
  Widget _buildInfoBanner({
    required IconData icon,
    required String en,
    required String ur,
    required Color color,
  }) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(children: [
          Icon(icon, color: color.withOpacity(0.8), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(en, style: TextStyle(color: _C.textSecond, fontSize: 12)),
              Text(ur, style: _C.tsUrdu),
            ]),
          ),
        ]),
      );

  // ── Text field ───────────────────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      Container(
        height: 56,
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: Row(children: [
          const SizedBox(width: 14),
          Icon(icon, color: _C.textMuted, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(color: _C.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: _C.tsHint,
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ]),
      );

  // ── Password field ───────────────────────────────────────────────────────────
  Widget _buildPasswordField() => Container(
    height: 56,
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _C.border),
    ),
    child: Row(children: [
      const SizedBox(width: 14),
      const Icon(Icons.lock_outline_rounded, color: _C.textMuted, size: 18),
      const SizedBox(width: 10),
      Expanded(
        child: TextField(
          controller: _passCtrl,
          obscureText: !_isPasswordVisible,
          style: const TextStyle(color: _C.textPrimary, fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'Password  /  پاس ورڈ',
            hintStyle: _C.tsHint,
            border: InputBorder.none,
            isDense: true,
          ),
        ),
      ),
      GestureDetector(
        onTap: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(
            _isPasswordVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: _C.textMuted, size: 18,
          ),
        ),
      ),
    ]),
  );

  // ── Remember me row ──────────────────────────────────────────────────────────
  Widget _buildRememberRow() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      GestureDetector(
        onTap: () => setState(() => _rememberMe = !_rememberMe),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: _rememberMe ? _C.blue : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _rememberMe ? _C.blue : _C.textMuted,
              ),
            ),
            child: _rememberMe
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 8),
          const Text('Remember me  /  یاد رکھیں',
              style: TextStyle(color: _C.textSecond, fontSize: 12)),
        ]),
      ),
      GestureDetector(
        onTap: () {},
        child: const Text('Forgot password?',
            style: TextStyle(
                color: _C.blue, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    ],
  );

  // ── Gender selector ──────────────────────────────────────────────────────────
  Widget _buildGenderSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(children: [
        Icon(Icons.wc_rounded, color: _C.textMuted, size: 14),
        SizedBox(width: 6),
        Text('Gender  /  جنس',
            style: TextStyle(color: _C.textSecond, fontSize: 12,
                fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _genderChip(true,  Icons.man_rounded,   'Male',   'مرد')),
        const SizedBox(width: 10),
        Expanded(child: _genderChip(false, Icons.woman_rounded, 'Female', 'عورت')),
      ]),
    ],
  );

  Widget _genderChip(bool isMale, IconData icon, String label, String urdu) {
    final active = _isMale == isMale;
    final color  = isMale ? _C.blue : const Color(0xFFEC407A);
    return GestureDetector(
      onTap: () { setState(() => _isMale = isMale); HapticFeedback.selectionClick(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.12) : _C.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? color.withOpacity(0.6) : _C.border,
            width: active ? 1.3 : 1,
          ),
        ),
        child: Column(children: [
          Icon(icon, color: active ? color : _C.textMuted, size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
              color: active ? color : _C.textSecond,
              fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
          Text(urdu, style: TextStyle(
              color: active ? color.withOpacity(0.7) : _C.textMuted, fontSize: 10)),
        ]),
      ),
    );
  }

  // ── Terms banner ─────────────────────────────────────────────────────────────
  Widget _buildTermsBanner() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _C.amber.withOpacity(0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _C.amber.withOpacity(0.25)),
    ),
    child: Row(children: [
      Icon(Icons.info_outline_rounded, color: _C.amber.withOpacity(0.8), size: 16),
      const SizedBox(width: 8),
      Expanded(child: RichText(
        text: const TextSpan(
          style: TextStyle(color: _C.textSecond, fontSize: 11, height: 1.5),
          children: [
            TextSpan(text: 'By signing up you agree to our '),
            TextSpan(
              text: 'Terms & Conditions',
              style: TextStyle(
                  color: _C.blue, fontWeight: FontWeight.w700),
            ),
            TextSpan(text: '  /  سائن اپ کر کے آپ ہماری ', style: TextStyle(color: _C.textUrdu, fontSize: 10)),
            TextSpan(
              text: 'شرائط',
              style: TextStyle(color: _C.blue, fontSize: 10, fontWeight: FontWeight.w700),
            ),
            TextSpan(text: ' سے اتفاق کرتے ہیں', style: TextStyle(color: _C.textUrdu, fontSize: 10)),
          ],
        ),
      )),
    ]),
  );

  // ── Action button ────────────────────────────────────────────────────────────
  Widget _buildActionButton() => SizedBox(
    width: double.infinity,
    height: 56,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: _isLoading ? null : _C.generateGrad,
        color:    _isLoading ? _C.card : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isLoading ? null : [
          BoxShadow(
              color: _C.blue.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _isLoading ? null : _handleAction,
        child: _isLoading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: _C.blue))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(
                  _isLoginMode ? Icons.login_rounded : Icons.person_add_rounded,
                  color: Colors.white, size: 20,
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLoginMode ? 'Sign In to System' : 'Create Account',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14,
                          fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                    Text(
                      _isLoginMode ? 'سسٹم میں داخل ہوں' : 'اکاؤنٹ بنائیں',
                      style: const TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                  ],
                ),
              ]),
      ),
    ),
  );

  // ── Divider ──────────────────────────────────────────────────────────────────
  Widget _buildDivider() => Row(children: [
    Expanded(child: Container(height: 1,
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.transparent, _C.border])))),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(children: const [
        Text('OR', style: TextStyle(
            color: _C.textMuted, fontSize: 10,
            fontWeight: FontWeight.w700, letterSpacing: 2)),
        Text('یا', style: TextStyle(color: _C.textMuted, fontSize: 9)),
      ]),
    ),
    Expanded(child: Container(height: 1,
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [_C.border, Colors.transparent])))),
  ]);

  // ── Social buttons ───────────────────────────────────────────────────────────
  Widget _buildSocialRow() => Row(children: [
    Expanded(child: _socialBtn(Icons.facebook_rounded, 'Facebook',
        const Color(0xFF1877F2))),
    const SizedBox(width: 12),
    Expanded(child: _socialBtn(Icons.g_mobiledata_rounded, 'Google',
        const Color(0xFFEA4335))),
  ]);

  Widget _socialBtn(IconData icon, String label, Color color) =>
      GestureDetector(
        onTap: () {},
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  // ── Footer switch ─────────────────────────────────────────────────────────────
  Widget _buildFooterSwitch() => Center(
    child: GestureDetector(
      onTap: () => _toggleMode(!_isLoginMode),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13),
          children: [
            TextSpan(
              text: _isLoginMode
                  ? "Don't have an account?  "
                  : 'Already have an account?  ',
              style: const TextStyle(color: _C.textSecond),
            ),
            TextSpan(
              text: _isLoginMode ? 'Sign Up' : 'Login',
              style: const TextStyle(
                  color: _C.blue,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3),
            ),
          ],
        ),
      ),
    ),
  );

  // ─── Unused (kept for compatibility) ────────────────────────────────────────
  static const TextStyle _tsUrdu = _C.tsUrdu;
}