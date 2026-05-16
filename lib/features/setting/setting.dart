import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/global_variables.dart';
import '../../../providers/user_provider.dart';
import '../auth/screens/auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  // ── Design constants ────────────────────────────────────────────────────────
  static const _bg       = Color(0xFF080C12);
  static const _surface  = Color(0xFF0F1923);
  static const _card     = Color(0xFF131F2E);
  static const _border   = Color(0xFF1E3050);
  static const _blue     = Color(0xFF4D9FFF);
  static const _green    = Color(0xFF00E676);
  static const _red      = Color(0xFFFF5252);
  static const _amber    = Color(0xFFFFD740);
  static const _tPrimary = Color(0xFFECF0F5);
  static const _tSecond  = Color(0xFF8BAAC8);
  static const _tMuted   = Color(0xFF4A6580);
  static const _tUrdu    = Color(0xFF6B8FAF);

  static const _tsUrdu = TextStyle(color: _tUrdu, fontSize: 10, height: 1.4);

  // ── Animations ──────────────────────────────────────────────────────────────
  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl,  curve: Curves.easeInOut);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Snack bar ────────────────────────────────────────────────────────────────
  void _snack(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(color: _tPrimary)),
        backgroundColor: color.withOpacity(0.85),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ));

  // ═══════════════════════════════════════════════════════════════════════════
  //  DIALOGS
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Profile dialog ───────────────────────────────────────────────────────────
  Future<void> _showProfileDialog(String email) async {
    try {
      final res = await http.post(
        Uri.parse('https://code-sync-server-kappa.vercel.app/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        final user = data['user'];
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => _AnimDialog(
            borderColor: _blue,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _dialogIcon(Icons.person_rounded, _blue, _pulseAnim),
              const SizedBox(height: 20),
              Text(user['name'],
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold,
                      color: Colors.white, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              const Text('پروفائل', style: _tsUrdu),
              const SizedBox(height: 8),
              Text(user['email'],
                  style: TextStyle(fontSize: 13, color: Colors.grey[400])),
              const SizedBox(height: 8),
              _badge("Type: ${user['type'] ?? 'Standard'}", _blue),
              const SizedBox(height: 24),
              _dialogBtn('Close  /  بند کریں', _blue,
                  () => Navigator.pop(context)),
            ]),
          ),
        );
      } else {
        _snack(data['error'] ?? 'Failed to fetch profile / پروفائل نہیں ملی',
            _red);
      }
    } catch (_) {
      _snack('Server error  /  سرور کی خرابی', _red);
    }
  }

  // ── Logout dialog ─────────────────────────────────────────────────────────────
  Future<void> _showLogoutDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AnimDialog(
        borderColor: _red,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _plainIcon(Icons.logout_rounded, _red),
          const SizedBox(height: 20),
          const Text('Logout  /  لاگ آؤٹ',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                  color: Colors.white, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          const Text('Are you sure you want to logout?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const Text('کیا آپ واقعی لاگ آؤٹ کرنا چاہتے ہیں؟',
              textAlign: TextAlign.center, style: _tsUrdu),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: _outlineBtn('Cancel  /  منسوخ',
                () => Navigator.pop(context))),
            const SizedBox(width: 12),
            Expanded(child: _solidBtn('Yes, Logout  /  ہاں', _red,
                () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (r) => false,
                );
              }
            })),
          ]),
        ]),
      ),
    );
  }

  // ── Reset password dialog ─────────────────────────────────────────────────────
  Future<void> _showResetPasswordDialog(String email) async {
    final passCtrl    = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          bool loading = false;
          return _AnimDialog(
            borderColor: _green,
            child: StatefulBuilder(builder: (ctx2, setS2) {
              return Column(mainAxisSize: MainAxisSize.min, children: [
                _plainIcon(Icons.lock_reset_rounded, _green),
                const SizedBox(height: 20),
                const Text('Reset Password',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const Text('پاس ورڈ تبدیل کریں', style: _tsUrdu),
                const SizedBox(height: 16),
                _passField(passCtrl,    'New Password  /  نیا پاس ورڈ',    _green),
                const SizedBox(height: 10),
                _passField(confirmCtrl, 'Confirm  /  تصدیق کریں', _green),
                const SizedBox(height: 20),
                if (loading)
                  const CircularProgressIndicator(color: _green)
                else
                  Row(children: [
                    Expanded(child: _outlineBtn('Cancel  /  منسوخ',
                        () => Navigator.pop(ctx))),
                    const SizedBox(width: 12),
                    Expanded(child: _solidBtn('Reset  /  تبدیل', _green,
                        () async {
                      final np = passCtrl.text.trim();
                      final cp = confirmCtrl.text.trim();
                      if (np.isEmpty || cp.isEmpty) {
                        _snack('Fill all fields  /  سب خانے بھریں', _red);
                        return;
                      }
                      if (np != cp) {
                        _snack('Passwords do not match  /  پاس ورڈ مختلف ہے',
                            _red);
                        return;
                      }
                      setS2(() => loading = true);
                      try {
                        final res = await http.post(
                          Uri.parse(
                              'https://code-sync-server-kappa.vercel.app/reset-password'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode(
                              {'email': email, 'newPassword': np}),
                        );
                        final d = jsonDecode(res.body);
                        if (d['success'] == true) {
                          _snack('Password updated  /  پاس ورڈ تبدیل ہو گیا',
                              _green);
                          Navigator.pop(ctx);
                        } else {
                          _snack(d['error'] ?? 'Failed  /  ناکام', _red);
                        }
                      } catch (_) {
                        _snack('Server error  /  سرور خرابی', _red);
                      } finally {
                        setS2(() => loading = false);
                      }
                    })),
                  ]),
              ]);
            }),
          );
        },
      ),
    );
  }

  // ── About dialog ──────────────────────────────────────────────────────────────
  Future<void> _showAboutDialog() async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _AnimDialog(
        borderColor: _blue,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _dialogIcon(Icons.psychology_rounded, _blue, _pulseAnim),
          const SizedBox(height: 20),
          const Text('FaceTrace AI',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                  color: Colors.white, letterSpacing: 1)),
          const SizedBox(height: 6),
          _badge('Version 2.0.0', _blue),
          const SizedBox(height: 12),
          const Text(
            'Advanced AI-powered forensic sketch generator for professional '
            'police composite sketches.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 6),
          const Text(
            'پیشہ ورانہ پولیس خاکہ بنانے کا جدید AI سسٹم۔',
            textAlign: TextAlign.center,
            style: _tsUrdu,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _infoChip(Icons.image_rounded,       'AI Generated', 'AI تصویر'),
                _infoChip(Icons.voice_chat_rounded,  'Voice Input',  'آواز'),
                _infoChip(Icons.security_rounded,    'Forensic',     'فرانزک'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _dialogBtn('Close  /  بند کریں', _blue,
              () => Navigator.pop(context)),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SHARED DIALOG WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _dialogIcon(IconData icon, Color color, Animation<double> pulse) =>
      AnimatedBuilder(
        animation: pulse,
        builder: (_, __) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [
              color.withOpacity(0.2 + pulse.value * 0.1),
              color.withOpacity(0.05),
            ]),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.3 * pulse.value),
                  blurRadius: 20, spreadRadius: 5),
            ],
          ),
          child: Icon(icon, size: 56, color: color),
        ),
      );

  Widget _plainIcon(IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(colors: [
        color.withOpacity(0.2), color.withOpacity(0.05),
      ]),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Icon(icon, size: 56, color: color),
  );

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Text(label,
        style: TextStyle(color: color, fontSize: 12,
            fontWeight: FontWeight.w600)),
  );

  Widget _infoChip(IconData icon, String en, String ur) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: _blue),
      const SizedBox(height: 4),
      Text(en,  style: const TextStyle(color: Colors.grey, fontSize: 10)),
      Text(ur,  style: _tsUrdu),
    ],
  );

  Widget _passField(TextEditingController ctrl, String hint, Color accent) =>
      Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: TextField(
          controller: ctrl,
          obscureText: true,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _tMuted, fontSize: 12),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            prefixIcon: Icon(Icons.lock_outline_rounded, color: accent, size: 18),
          ),
        ),
      );

  Widget _dialogBtn(String label, Color color, VoidCallback onTap) =>
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
          onPressed: onTap,
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      );

  Widget _outlineBtn(String label, VoidCallback onTap) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: _tMuted),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 13),
    ),
    child: Text(label,
        style: const TextStyle(color: Colors.grey, fontSize: 12)),
  );

  Widget _solidBtn(String label, Color color, VoidCallback onTap) =>
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 13),
        ),
        onPressed: onTap,
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 12,
                fontWeight: FontWeight.w700)),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  //  SETTINGS LIST WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _sectionTitle(String en, String ur) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
    child: Row(children: [
      Container(
        width: 3, height: 20,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_blue, Color(0xFF00D4FF)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(en.toUpperCase(),
            style: const TextStyle(
                fontSize: 11, letterSpacing: 2,
                color: _tSecond, fontWeight: FontWeight.w700)),
        Text(ur, style: _tsUrdu),
      ]),
      const SizedBox(width: 10),
      Expanded(child: Container(height: 1,
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [_border, Colors.transparent])))),
    ]),
  );

  Widget _tile({
    required IconData icon,
    required String title,
    required String titleUrdu,
    required String subtitle,
    required String subtitleUrdu,
    Color? iconColor,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final color = iconColor ?? _blue;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap?.call(); },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0F1923), Color(0xFF0A1628)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [
                color.withOpacity(0.2), color.withOpacity(0.05),
              ]),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(width: 6),
                Text('/ $titleUrdu',
                    style: const TextStyle(
                        color: _tUrdu, fontSize: 11)),
              ]),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: const TextStyle(fontSize: 11, color: _tSecond)),
              Text(subtitleUrdu, style: _tsUrdu),
            ],
          )),
          trailing ??
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF0A1628), Color(0xFF0D1F3C)],
            ),
          ),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Settings',
                style: TextStyle(fontWeight: FontWeight.w700,
                    letterSpacing: 0.5, fontSize: 18)),
            Text('ترتیبات',
                style: TextStyle(color: _tUrdu, fontSize: 11)),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 48),
          children: [

            // ── Profile card ───────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF0F1923), Color(0xFF0A1628)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _blue.withOpacity(0.3)),
              ),
              child: Row(children: [
                Container(
                  width: 68, height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [
                      _blue.withOpacity(0.3), _blue.withOpacity(0.08),
                    ]),
                    border: Border.all(color: _blue.withOpacity(0.5), width: 2),
                  ),
                  child: const Icon(Icons.person_rounded, color: _blue, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700,
                            color: Colors.white, letterSpacing: 0.3)),
                    const SizedBox(height: 2),
                    Text(user.email,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _green.withOpacity(0.3)),
                        ),
                        child: Row(children: const [
                          Icon(Icons.circle, size: 6, color: _green),
                          SizedBox(width: 5),
                          Text('Active Account',
                              style: TextStyle(color: _green,
                                  fontSize: 10, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      const Text('فعال اکاؤنٹ', style: _tsUrdu),
                    ]),
                  ],
                )),
              ]),
            ),

            // ── Account section ────────────────────────────────────────────
            _sectionTitle('Account', 'اکاؤنٹ'),
            _tile(
              icon: Icons.person_outline_rounded,
              title: 'Profile', titleUrdu: 'پروفائل',
              subtitle: 'Manage personal information',
              subtitleUrdu: 'ذاتی معلومات کا انتظام',
              onTap: () => _showProfileDialog(user.email),
            ),
            _tile(
              icon: Icons.lock_outline_rounded,
              title: 'Change Password', titleUrdu: 'پاس ورڈ تبدیل کریں',
              subtitle: 'Update your account password',
              subtitleUrdu: 'اپنا پاس ورڈ اپ ڈیٹ کریں',
              onTap: () => _showResetPasswordDialog(user.email),
            ),

            // ── Application section ────────────────────────────────────────
            _sectionTitle('Application', 'ایپلیکیشن'),
            _tile(
              icon: Icons.info_outline_rounded,
              title: 'About FaceTrace', titleUrdu: 'فیس ٹریس کے بارے میں',
              subtitle: 'Version 2.0.0, privacy & legal',
              subtitleUrdu: 'ورژن، رازداری اور قانونی',
              onTap: () => _showAboutDialog(),
            ),
            _tile(
              icon: Icons.palette_outlined,
              title: 'Theme', titleUrdu: 'تھیم',
              subtitle: 'Dark mode (default)',
              subtitleUrdu: 'ڈارک موڈ (ڈیفالٹ)',
            ),
            _tile(
              icon: Icons.language_rounded,
              title: 'Language', titleUrdu: 'زبان',
              subtitle: 'English / Urdu',
              subtitleUrdu: 'انگریزی / اردو',
            ),

            // ── Support section ────────────────────────────────────────────
            _sectionTitle('Support', 'مدد'),
            _tile(
              icon: Icons.help_outline_rounded,
              title: 'Help Center', titleUrdu: 'مدد مرکز',
              subtitle: 'FAQs and support',
              subtitleUrdu: 'عام سوالات اور مدد',
              iconColor: _amber,
            ),
            _tile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy', titleUrdu: 'رازداری کی پالیسی',
              subtitle: 'Data protection guidelines',
              subtitleUrdu: 'ڈیٹا کے تحفظ کے رہنما اصول',
              iconColor: _amber,
            ),

            // ── Danger zone ────────────────────────────────────────────────
            _sectionTitle('Danger Zone', 'خطرناک زون'),
            _tile(
              icon: Icons.logout_rounded,
              title: 'Logout', titleUrdu: 'لاگ آؤٹ',
              subtitle: 'Sign out from this device',
              subtitleUrdu: 'اس ڈیوائس سے سائن آؤٹ کریں',
              iconColor: _red,
              trailing: const Icon(Icons.exit_to_app_rounded,
                  color: _red, size: 18),
              onTap: _showLogoutDialog,
            ),

            const SizedBox(height: 20),

            // ── Footer ────────────────────────────────────────────────────
            Center(child: Column(children: const [
              Text('FaceTrace AI  •  Version 2.0.0',
                  style: TextStyle(color: _tMuted, fontSize: 11)),
              SizedBox(height: 2),
              Text('فیس ٹریس AI  •  فرانزک سسٹم',
                  style: TextStyle(color: _tUrdu, fontSize: 10)),
            ])),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  ANIMATED DIALOG WRAPPER
// ═════════════════════════════════════════════════════════════════════════════
class _AnimDialog extends StatelessWidget {
  final Widget child;
  final Color borderColor;

  const _AnimDialog({required this.child, required this.borderColor});

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(20),
    child: TweenAnimationBuilder(
      duration: const Duration(milliseconds: 400),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.elasticOut,
      builder: (_, scale, __) => Transform.scale(
        scale: scale,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF0F1923), Color(0xFF0A1628)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: borderColor.withOpacity(0.4), width: 1.5),
          ),
          child: child,
        ),
      ),
    ),
  );
}