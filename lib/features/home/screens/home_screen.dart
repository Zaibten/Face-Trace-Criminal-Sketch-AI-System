// ═══════════════════════════════════════════════════════════════════════════════
//  home_screen.dart  –  ALL IN ONE  |  ENHANCED PROFESSIONAL VERSION
//  Contains:
//    • _C                  (design constants — colors, styles)
//    • FaceOption          (data model)
//    • _PulseDot           (animated glow dot widget)
//    • _Shimmer            (skeleton loading widget)
//    • _RadarPainter       (header radar animation)
//    • _GridPatternPainter (card background pattern)
//    • HomeScreen          (AI image generator + animated sketch card)
//    • CriminalSketchScreen (full forensic sketch with voice, attrs, Node API)
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../constants/global_variables.dart';
import '../../../constants/utils.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  SERVER CONFIG  ← change host/port here only
// ─────────────────────────────────────────────────────────────────────────────
class _Server {
  /// Base URL of your Node.js backend.
  /// • Android emulator  → 'http://10.0.2.2:9000'
  /// • iOS simulator     → 'http://127.0.0.1:9000'
  /// • Physical device   → 'http://<your-local-ip>:9000'
  static const baseUrl = 'http://192.168.100.177:9000';

  static Uri generateImage() => Uri.parse('$baseUrl/api/generate-image');
  static Uri generateSketch() => Uri.parse('$baseUrl/api/generate-sketch');
}

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFF080C12);
  static const surface   = Color(0xFF0F1923);
  static const card      = Color(0xFF131F2E);
  static const border    = Color(0xFF1E3050);
  static const borderHi  = Color(0xFF2D4E7A);
  static const blue      = Color(0xFF4D9FFF);
  static const cyan      = Color(0xFF00D4FF);
  static const green     = Color(0xFF00E676);
  static const red       = Color(0xFFFF5252);
  static const amber     = Color(0xFFFFD740);
  static const textPrimary   = Color(0xFFECF0F5);
  static const textSecondary = Color(0xFF8BAAC8);
  static const textMuted     = Color(0xFF4A6580);
  static const textUrdu      = Color(0xFF6B8FAF);

  static const headerGrad = LinearGradient(
    colors: [Color(0xFF0A1628), Color(0xFF0D2040), Color(0xFF0A1628)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const blueGrad = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
  );
  static const greenGrad = LinearGradient(
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
  );
  static const sketchCardGrad = LinearGradient(
    colors: [Color(0xFF0D2040), Color(0xFF0A2850), Color(0xFF071830)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const generateGrad = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF1976D2), Color(0xFF1565C0)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static const tsSectionTitle = TextStyle(
    color: textPrimary, fontSize: 13,
    fontWeight: FontWeight.w700, letterSpacing: 0.5,
  );
  static const tsUrdu = TextStyle(color: textUrdu, fontSize: 11, height: 1.4);
  static const tsHint = TextStyle(color: textMuted, fontSize: 13);
}

// ─────────────────────────────────────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────
class FaceOption {
  final String label, labelUrdu, description;
  final IconData icon;
  final Color accentColor;
  final List<String> choices;
  String? selected;
  FaceOption({
    required this.label, required this.labelUrdu, required this.description,
    required this.icon, required this.accentColor, required this.choices,
    this.selected,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  const _PulseDot({this.color = _C.green, this.size = 8});
  @override State<_PulseDot> createState() => _PulseDotState();
}
class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      width: widget.size, height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle, color: widget.color,
        boxShadow: [BoxShadow(
          color: widget.color.withOpacity(0.6 * _a.value),
          blurRadius: 8 * _a.value, spreadRadius: 2 * _a.value,
        )],
      ),
    ),
  );
}

class _Shimmer extends StatefulWidget {
  final double width, height;
  final BorderRadius borderRadius;
  const _Shimmer({required this.width, required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8))});
  @override State<_Shimmer> createState() => _ShimmerState();
}
class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Container(
      width: widget.width, height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        gradient: LinearGradient(
          begin: Alignment(-1.0 + 3 * _c.value, 0),
          end: Alignment(1.0 + 3 * _c.value, 0),
          colors: const [Color(0xFF0F1923), Color(0xFF1E3050), Color(0xFF0F1923)],
        ),
      ),
    ),
  );
}

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
        startAngle: angle - 1.2, endAngle: angle,
        colors: [Colors.transparent, _C.blue.withOpacity(0.3)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: maxR))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), maxR, sweepPaint);
    paint.color = _C.blue.withOpacity(0.7);
    paint.strokeWidth = 1.5;
    canvas.drawLine(Offset(cx, cy),
        Offset(cx + maxR * math.cos(angle), cy + maxR * math.sin(angle)), paint);
  }
  @override bool shouldRepaint(_RadarPainter o) => o.angle != angle;
}

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _C.blue.withOpacity(0.04)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 24)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += 24)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }
  @override bool shouldRepaint(_GridPatternPainter _) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  HOME SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';
  const HomeScreen({Key? key}) : super(key: key);
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _sizes  = ['Square (1024)', 'Wide (1792×1024)', 'Tall (1024×1792)'];
  final _values = ['1024x1024', '1792x1024', '1024x1792'];
  String? _dropValue;
  final _textCtrl = TextEditingController();
  String _image = '';
  bool _isLoaded = false, _isGenerating = false;
  final _screenshotCtrl = ScreenshotController();

  late final AnimationController _radarCtrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  late final AnimationController _entryCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final Animation<double> _entrySlide =
      Tween<double>(begin: 50, end: 0).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
  late final Animation<double> _entryFade =
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 150), () => _entryCtrl.forward());
  }
  @override
  void dispose() {
    _radarCtrl.dispose(); _entryCtrl.dispose(); _textCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(color: _C.textPrimary)),
    backgroundColor: _C.card, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));

  Future<void> _shareImage() async {
    try {
      final img = await _screenshotCtrl.capture(
          delay: const Duration(milliseconds: 100), pixelRatio: 2.0);
      if (img == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/facetrace_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(img);
      await Share.shareXFiles([XFile(path)], text: 'Generated By FaceTrace AI');
    } catch (e) { _snack('Share failed: $e'); }
  }

Future<void> _downloadImage() async {
  if (!(await Permission.storage.request()).isGranted) { 
    _snack('Permission denied'); 
    return; 
  }
  
  final dir = await getExternalStorageDirectory();
  final folder = Directory('${dir?.path}/FaceTrace');
  final fname = 'facetrace_${DateTime.now().millisecondsSinceEpoch}.png';
  
  if (!await folder.exists()) await folder.create(recursive: true);
  
  await _screenshotCtrl.captureAndSave(
    folder.path,
    delay: const Duration(milliseconds: 100), 
    fileName: fname, 
    pixelRatio: 2.0
  );
  
  // Notify that an image was saved
  HomeScreenStateManager.notifyImageSaved();
  
  _snack('✓ Image saved to FaceTrace folder');
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(children: [
        _buildHeader(),
        Expanded(child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: AnimatedBuilder(
            animation: _entryCtrl,
            builder: (_, child) => Opacity(opacity: _entryFade.value,
              child: Transform.translate(
                  offset: Offset(0, _entrySlide.value), child: child)),
            child: Column(children: [
              const SizedBox(height: 16),
              _buildSketchCard(),
              const SizedBox(height: 20),
              _buildDivider('IMAGE GENERATOR', 'تصویر ساز'),
              const SizedBox(height: 16),
              _buildPromptRow(),
              const SizedBox(height: 12),
              _buildGenerateButton(),
              const SizedBox(height: 16),
              _buildResultArea(),
            ]),
          ),
        )),
      ]),
    );
  }

  Widget _buildHeader() => Container(
    decoration: const BoxDecoration(
      gradient: _C.headerGrad,
      border: Border(bottom: BorderSide(color: _C.border)),
    ),
    child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
      child: Row(children: [
        AnimatedBuilder(
          animation: _radarCtrl,
          builder: (_, __) => SizedBox(width: 48, height: 48,
            child: CustomPaint(painter: _RadarPainter(_radarCtrl.value * 2 * math.pi))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('FACE', style: TextStyle(color: _C.blue, fontSize: 22,
                fontWeight: FontWeight.w900, letterSpacing: 3)),
            const Text('TRACE', style: TextStyle(color: _C.textPrimary, fontSize: 22,
                fontWeight: FontWeight.w900, letterSpacing: 3)),
            const SizedBox(width: 8),
            const _PulseDot(size: 7),
          ]),
          const Text('AI FORENSIC SYSTEM  •  فرانزک سسٹم',
              style: TextStyle(color: _C.textMuted, fontSize: 9,
                  letterSpacing: 2, fontWeight: FontWeight.w500)),
        ])),
        GestureDetector(
          onTap: () {
            setState(() { _isLoaded = false; _image = ''; });
            _textCtrl.clear();
            HapticFeedback.lightImpact();
          },
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: _C.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.border)),
            child: const Icon(Icons.refresh_rounded, color: _C.textSecondary, size: 18),
          ),
        ),
      ]),
    )),
  );

  Widget _buildSketchCard() => GestureDetector(
    onTap: () {
      HapticFeedback.mediumImpact();
      Navigator.push(context, PageRouteBuilder(
        pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: const CriminalSketchScreen()),
        transitionDuration: const Duration(milliseconds: 400),
      ));
    },
    child: Container(
      decoration: BoxDecoration(
        gradient: _C.sketchCardGrad,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.borderHi, width: 1.2),
        boxShadow: [BoxShadow(color: _C.blue.withOpacity(0.15), blurRadius: 30, spreadRadius: -5)],
      ),
      child: Stack(children: [
        Positioned.fill(child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: CustomPaint(painter: _GridPatternPainter()),
        )),
        Padding(padding: const EdgeInsets.all(20), child: Row(children: [
          Container(
            width: 58, height: 58,
            decoration: BoxDecoration(
              gradient: _C.blueGrad, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: _C.blue.withOpacity(0.4), blurRadius: 16, spreadRadius: -2)],
            ),
            child: const Icon(Icons.person_search_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('Criminal Sketch AI', style: TextStyle(
                  color: _C.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _C.blue.withOpacity(0.2), borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _C.blue.withOpacity(0.4)),
                ),
                child: const Text('NEW', style: TextStyle(color: _C.blue,
                    fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
            ]),
            const SizedBox(height: 4),
            const Text('مجرم کا خاکہ بنائیں', style: _C.tsUrdu),
            const SizedBox(height: 8),
            const Text('Voice-guided forensic sketch generator\nwith 25+ facial attribute controls',
                style: TextStyle(color: _C.textSecondary, fontSize: 11, height: 1.5)),
          ])),
          Container(width: 32, height: 32,
            decoration: BoxDecoration(color: _C.blue.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.arrow_forward_ios_rounded, color: _C.blue, size: 14)),
        ])),
      ]),
    ),
  );

  Widget _buildDivider(String label, String urdu) => Row(children: [
    Expanded(child: Container(height: 1,
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, _C.border])))),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Column(children: [
      Text(label, style: const TextStyle(color: _C.textMuted, fontSize: 10,
          fontWeight: FontWeight.w700, letterSpacing: 2)),
      Text(urdu, style: const TextStyle(color: _C.textMuted, fontSize: 9)),
    ])),
    Expanded(child: Container(height: 1,
        decoration: BoxDecoration(gradient: LinearGradient(colors: [_C.border, Colors.transparent])))),
  ]);

  Widget _buildPromptRow() => Row(children: [
    Expanded(child: Container(
      height: 52,
      decoration: BoxDecoration(color: _C.card, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border)),
      child: Row(children: [
        const SizedBox(width: 14),
        const Icon(Icons.auto_awesome_outlined, color: _C.textMuted, size: 16),
        const SizedBox(width: 8),
        Expanded(child: TextFormField(
          controller: _textCtrl,
          style: const TextStyle(color: _C.textPrimary, fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'Describe image…  /  تصویر بیان کریں',
            hintStyle: _C.tsHint, border: InputBorder.none, isDense: true,
          ),
        )),
      ]),
    )),
    const SizedBox(width: 10),
    Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: _C.card, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: _dropValue,
        hint: const Text('Size', style: TextStyle(color: _C.textMuted, fontSize: 12)),
        dropdownColor: _C.card,
        style: const TextStyle(color: _C.textPrimary, fontSize: 12),
        icon: const Icon(Icons.expand_more, color: _C.blue, size: 18),
        onChanged: (v) => setState(() => _dropValue = v),
        items: List.generate(_sizes.length,
            (i) => DropdownMenuItem(value: _values[i], child: Text(_sizes[i]))),
      )),
    ),
  ]);

  Widget _buildGenerateButton() => SizedBox(
    width: double.infinity, height: 50,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: _isGenerating ? null : _C.generateGrad,
        color: _isGenerating ? _C.card : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _isGenerating ? null :
            [BoxShadow(color: _C.blue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _isGenerating ? null : _onGenerate,
        icon: _isGenerating
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: _C.blue))
            : const Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 18),
        label: Text(
          _isGenerating ? 'Generating…  /  بنایا جا رہا ہے' : 'Generate Image  /  تصویر بنائیں',
          style: const TextStyle(color: Colors.white, fontSize: 13,
              fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
    ),
  );

  // ── Calls Node.js POST /api/generate-image ──────────────────────────────────
  Future<void> _onGenerate() async {
    if (_textCtrl.text.trim().isEmpty || _dropValue == null) {
      _snack('Please enter a prompt and select size');
      return;
    }
    setState(() => _isGenerating = true);
    HapticFeedback.mediumImpact();
    try {
      final res = await http.post(
        _Server.generateImage(),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': _textCtrl.text.trim(),
          'size': _dropValue,
        }),
      ).timeout(
        const Duration(seconds: 100),
        onTimeout: () => throw Exception('Request timed out'),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && body['success'] == true) {
        final url = body['imageUrl'] as String;
        setState(() { _image = url; _isLoaded = true; _isGenerating = false; });
        HapticFeedback.heavyImpact();
      } else {
        throw Exception(body['error'] ?? 'Generation failed (HTTP ${res.statusCode})');
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      _snack('Error: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Widget _buildResultArea() {
    if (_isGenerating) return Container(
      height: 280,
      decoration: BoxDecoration(color: _C.card, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const _Shimmer(width: double.infinity, height: 160,
            borderRadius: BorderRadius.all(Radius.circular(12))),
        const SizedBox(height: 16),
        const Text('AI is crafting your image…',
            style: TextStyle(color: _C.textSecondary, fontSize: 13)),
        const Text('تصویر بنائی جا رہی ہے', style: _C.tsUrdu),
      ]),
    );
    if (!_isLoaded) return Container(
      height: 260,
      decoration: BoxDecoration(color: _C.card, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 72, height: 72,
          decoration: BoxDecoration(color: _C.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20), border: Border.all(color: _C.border)),
          child: const Icon(Icons.image_outlined, color: _C.textMuted, size: 32)),
        const SizedBox(height: 16),
        const Text('Generated image appears here',
            style: TextStyle(color: _C.textSecondary, fontSize: 13)),
        const Text('تیار کردہ تصویر یہاں نظر آئے گی', style: _C.tsUrdu),
      ]),
    );
    return Column(children: [
      Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.borderHi),
          boxShadow: [BoxShadow(color: _C.blue.withOpacity(0.2), blurRadius: 30, spreadRadius: -5)]),
        child: ClipRRect(borderRadius: BorderRadius.circular(16),
          child: Screenshot(controller: _screenshotCtrl,
            child: Image.network(_image, fit: BoxFit.contain,
              loadingBuilder: (_, child, prog) => prog == null ? child
                  : Container(height: 300, color: _C.card, alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        value: prog.expectedTotalBytes != null
                            ? prog.cumulativeBytesLoaded / prog.expectedTotalBytes! : null,
                        color: _C.blue)),
            )),
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _actionBtn(Icons.download_rounded, 'Download', 'ڈاؤن لوڈ', _C.blueGrad, _downloadImage)),
        const SizedBox(width: 10),
        Expanded(child: _actionBtn(Icons.share_rounded, 'Share', 'شیئر', _C.greenGrad, _shareImage)),
      ]),
    ]);
  }

  Widget _actionBtn(IconData icon, String label, String urdu,
      LinearGradient grad, VoidCallback onTap) =>
    GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(height: 48,
        decoration: BoxDecoration(gradient: grad, borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label, style: const TextStyle(color: Colors.white,
                fontSize: 12, fontWeight: FontWeight.w700)),
            Text(urdu, style: const TextStyle(color: Colors.white60, fontSize: 9)),
          ]),
        ]),
      ),
    );
}

// Add a StreamController for communication between screens
class HomeScreenStateManager {
  static final StreamController<void> _imageSavedController = StreamController.broadcast();
  static Stream<void> get onImageSaved => _imageSavedController.stream;
  static void notifyImageSaved() => _imageSavedController.add(null);
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CRIMINAL SKETCH SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class CriminalSketchScreen extends StatefulWidget {
  static const String routeName = '/criminal-sketch';
  const CriminalSketchScreen({Key? key}) : super(key: key);
  @override State<CriminalSketchScreen> createState() => _CriminalSketchScreenState();
}

class _CriminalSketchScreenState extends State<CriminalSketchScreen>
    with TickerProviderStateMixin {

  final _descCtrl = TextEditingController();
  final _promptCtrl = TextEditingController();
  final _screenshotCtrl = ScreenshotController();
  final _scrollCtrl = ScrollController();

  final _speech = stt.SpeechToText();
  bool _isListening = false, _speechAvail = false;
  String _activeField = '';
  double _soundLevel = 0;

  bool _isGenerating = false;
  String? _imageUrl, _errorMsg;
  double _progress = 0;
  String _statusMsg = '';

  late final AnimationController _pulseCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  late final Animation<double> _pulseAnim =
      Tween<double>(begin: 0.9, end: 1.1).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

  late final AnimationController _fadeCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

  late final AnimationController _headerCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final Animation<double> _headerAnim =
      CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutBack);

  late final AnimationController _waveCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);

  late List<FaceOption> _faceOptions;
  String? _gender, _ageGroup, _build, _complexion;
  String? _hairColor, _hairStyle, _ethnicity, _expression;
  String? _glasses, _headCovering;

  int get _completedAttrs {
    int c = 0;
    for (final v in [_gender, _ageGroup, _build, _complexion,
          _hairColor, _hairStyle, _ethnicity, _expression, _glasses, _headCovering])
      if (v != null) c++;
    for (final o in _faceOptions) if (o.selected != null) c++;
    return c;
  }
  int get _totalAttrs => 10 + _faceOptions.length;

  @override
  void initState() {
    super.initState();
    _initFaceOptions();
    _initSpeech();
    _headerCtrl.forward();
  }

  void _initFaceOptions() {
    _faceOptions = [
      FaceOption(label: 'Face Shape', labelUrdu: 'چہرے کی شکل', description: 'Overall facial structure',
        icon: Icons.face_rounded, accentColor: const Color(0xFF4FC3F7),
        choices: ['Oval', 'Round', 'Square', 'Heart', 'Diamond', 'Oblong', 'Triangular']),
      FaceOption(label: 'Eyes', labelUrdu: 'آنکھیں', description: 'Eye shape and set',
        icon: Icons.remove_red_eye_rounded, accentColor: const Color(0xFF80DEEA),
        choices: ['Small', 'Large', 'Almond', 'Round', 'Deep-set', 'Close-set', 'Wide-set', 'Hooded', 'Upturned']),
      FaceOption(label: 'Eye Color', labelUrdu: 'آنکھوں کا رنگ', description: 'Iris color',
        icon: Icons.lens_outlined, accentColor: const Color(0xFF80CBC4),
        choices: ['Black', 'Dark Brown', 'Light Brown', 'Hazel', 'Green', 'Blue', 'Grey', 'Amber']),
      FaceOption(label: 'Nose', labelUrdu: 'ناک', description: 'Nose shape and size',
        icon: Icons.air_rounded, accentColor: const Color(0xFFCE93D8),
        choices: ['Flat', 'Pointed', 'Wide', 'Narrow', 'Hooked', 'Bulbous', 'Upturned', 'Roman', 'Snub']),
      FaceOption(label: 'Ears', labelUrdu: 'کان', description: 'Ear shape and position',
        icon: Icons.hearing_rounded, accentColor: const Color(0xFFF48FB1),
        choices: ['Small', 'Large', 'Protruding', 'Flat', 'Attached lobe', 'Free lobe', 'Cauliflower']),
      FaceOption(label: 'Mouth / Lips', labelUrdu: 'منہ / ہونٹ', description: 'Lip fullness and width',
        icon: Icons.sentiment_neutral_rounded, accentColor: const Color(0xFFFFCC02),
        choices: ['Thin lips', 'Full lips', 'Wide mouth', 'Small mouth', 'Downturned', 'Upturned', 'Bow-shaped']),
      FaceOption(label: 'Eyebrows', labelUrdu: 'ابرو', description: 'Brow thickness and arch',
        icon: Icons.horizontal_rule_rounded, accentColor: const Color(0xFFA5D6A7),
        choices: ['Thick', 'Thin', 'Arched', 'Straight', 'Bushy', 'Sparse', 'Monobrow', 'High-set', 'Low-set']),
      FaceOption(label: 'Jaw / Chin', labelUrdu: 'جبڑا / ٹھوڑی', description: 'Jawline definition',
        icon: Icons.crop_din_rounded, accentColor: const Color(0xFFFFAB91),
        choices: ['Strong', 'Soft', 'Pointed', 'Receding', 'Double chin', 'Cleft chin', 'Wide']),
      FaceOption(label: 'Forehead', labelUrdu: 'ماتھا', description: 'Forehead size and shape',
        icon: Icons.expand_less_rounded, accentColor: const Color(0xFFB39DDB),
        choices: ['High', 'Low', 'Wide', 'Narrow', 'Prominent', 'Sloped']),
      FaceOption(label: 'Cheekbones', labelUrdu: 'گالوں کی ہڈی', description: 'Cheekbone prominence',
        icon: Icons.face_retouching_off, accentColor: const Color(0xFF80DEEA),
        choices: ['High', 'Low', 'Prominent', 'Flat', 'Chubby', 'Hollow']),
      FaceOption(label: 'Facial Hair', labelUrdu: 'داڑھی / مونچھ', description: 'Beard and moustache',
        icon: Icons.face_retouching_natural_rounded, accentColor: const Color(0xFF90CAF9),
        choices: ['None', 'Clean shaven', 'Light stubble', 'Heavy stubble',
          'Moustache only', 'Goatee', 'Chin strap', 'Short beard', 'Long beard', 'Full beard']),
      FaceOption(label: 'Scars / Marks', labelUrdu: 'نشانات / داغ', description: 'Distinctive marks',
        icon: Icons.warning_amber_rounded, accentColor: const Color(0xFFFF8A65),
        choices: ['None', 'Scar on left cheek', 'Scar on right cheek', 'Scar on forehead',
          'Scar on chin', 'Birthmark', 'Tattoo on face', 'Mole', 'Acne marks', 'Burns']),
      FaceOption(label: 'Skin Texture', labelUrdu: 'جلد کی بناوٹ', description: 'Skin condition',
        icon: Icons.texture_rounded, accentColor: const Color(0xFFFFF176),
        choices: ['Smooth', 'Rough', 'Wrinkled', 'Pockmarked', 'Freckled', 'Oily', 'Dry', 'Aged']),
    ];
  }

  Future<void> _initSpeech() async {
    _speechAvail = await _speech.initialize(
      onStatus: (s) { if (mounted && (s == 'done' || s == 'notListening'))
          setState(() => _isListening = false); },
      onError: (_) { if (mounted) setState(() => _isListening = false); },
    );
    if (mounted) setState(() {});
  }

  Future<void> _toggleMic(String field) async {
    if (!_speechAvail) { _snack('⚠️ Microphone not available'); return; }
    HapticFeedback.selectionClick();
    if (_isListening && _activeField == field) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      if (_isListening) await _speech.stop();
      setState(() { _isListening = true; _activeField = field; });
      await _speech.listen(
        onResult: (r) { if (!mounted) return;
          setState(() {
            final ctrl = field == 'desc' ? _descCtrl : _promptCtrl;
            ctrl.text = r.recognizedWords;
            ctrl.selection = TextSelection.fromPosition(TextPosition(offset: ctrl.text.length));
          });
        },
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 6),
        partialResults: true, localeId: 'en_US', cancelOnError: true,
      );
    }
  }

  // ── Builds the structured attribute map sent to the Node server ─────────────
  Map<String, dynamic> _buildAttributes() {
    // Map FaceOption labels → server attribute keys
    const labelToKey = {
      'Face Shape':    'faceShape',
      'Eyes':          'eyes',
      'Eye Color':     'eyeColor',
      'Nose':          'nose',
      'Ears':          'ears',
      'Mouth / Lips':  'lips',
      'Eyebrows':      'eyebrows',
      'Jaw / Chin':    'jaw',
      'Forehead':      'forehead',
      'Cheekbones':    'cheekbones',
      'Facial Hair':   'facialHair',
      'Scars / Marks': 'scarsMarks',
      'Skin Texture':  'skinTexture',
    };

    final attrs = <String, dynamic>{};
    void add(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) attrs[key] = value.trim();
    }

    add('gender',       _gender);
    add('ageGroup',     _ageGroup);
    add('ethnicity',    _ethnicity);
    add('complexion',   _complexion);
    add('build',        _build);
    add('hairColor',    _hairColor);
    add('hairStyle',    _hairStyle);
    add('expression',   _expression);
    add('glasses',      _glasses);
    add('headCovering', _headCovering);

    for (final opt in _faceOptions) {
      final key = labelToKey[opt.label];
      if (key != null) add(key, opt.selected);
    }

    return attrs;
  }

  // ── Calls Node.js POST /api/generate-sketch ─────────────────────────────────
  Future<void> _generate() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _isGenerating = true; _imageUrl = null; _errorMsg = null;
      _progress = 0; _statusMsg = 'Initializing AI systems…';
    });

    // Progress animation (cosmetic)
    final statuses = [
      'Analyzing attributes…',
      'Compositing elements…',
      'Applying forensic style…',
      'Refining details…',
      'Finalizing…',
    ];
    int sIdx = 0;
    Stream.periodic(const Duration(milliseconds: 300), (i) => i).take(60).listen((i) {
      if (!_isGenerating || !mounted) return;
      setState(() {
        _progress = (i + 1) / 60;
        if (i % 12 == 0 && sIdx < statuses.length) _statusMsg = statuses[sIdx++];
      });
    });

    try {
      final res = await http.post(
        _Server.generateSketch(),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'attributes':       _buildAttributes(),
          'description':      _descCtrl.text.trim(),
          'additionalPrompt': _promptCtrl.text.trim(),
        }),
      ).timeout(
        const Duration(seconds: 100),
        onTimeout: () => throw Exception('Request timed out after 100 seconds'),
      );

      debugPrint('📡 Server status: ${res.statusCode}');

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && decoded['success'] == true) {
        final url = decoded['imageUrl'] as String;
        if (!mounted) return;
        setState(() { _imageUrl = url; _progress = 1.0; _statusMsg = 'Complete!'; });
        _fadeCtrl.forward(from: 0);
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _scrollCtrl.hasClients)
            _scrollCtrl.animateTo(
              _scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            );
        });
      } else {
        throw Exception(decoded['error'] ?? 'Generation failed (HTTP ${res.statusCode})');
      }
    } on Exception catch (e) {
      debugPrint('❌ Exception: $e');
      if (!mounted) return;
      setState(() => _errorMsg = e.toString().replaceFirst('Exception: ', ''));
      HapticFeedback.vibrate();
    } catch (e) {
      debugPrint('❌ Unknown error: $e');
      if (!mounted) return;
      setState(() => _errorMsg = 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _share() async {
    try {
      final img = await _screenshotCtrl.capture(
          delay: const Duration(milliseconds: 100), pixelRatio: 2);
      if (img == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/sketch_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(img);
      await Share.shareXFiles([XFile(path)], text: 'Criminal Composite Sketch – FaceTrace AI');
    } catch (e) { _snack('Share failed: $e'); }
  }

  Future<void> _download() async {
    if (!(await Permission.storage.request()).isGranted) { _snack('Permission denied'); return; }
    try {
      final dir = await getExternalStorageDirectory();
      final folder = Directory('${dir?.path}/CriminalSketches');
      if (!await folder.exists()) await folder.create(recursive: true);
      final fname = 'sketch_${DateTime.now().millisecondsSinceEpoch}.png';
      await _screenshotCtrl.captureAndSave(folder.path,
          delay: const Duration(milliseconds: 100), fileName: fname, pixelRatio: 3);
      _snack('✓ High-res sketch saved');
    } catch (e) { _snack('Download failed: $e'); }
  }

  void _resetAll() {
    HapticFeedback.mediumImpact();
    setState(() {
      _descCtrl.clear(); _promptCtrl.clear();
      _imageUrl = null; _errorMsg = null; _isGenerating = false; _progress = 0;
      _gender = _ageGroup = _build = _complexion = _hairColor = _hairStyle = null;
      _ethnicity = _expression = _glasses = _headCovering = null;
      for (final o in _faceOptions) o.selected = null;
    });
    _fadeCtrl.reset();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(color: _C.textPrimary)),
    backgroundColor: _C.card, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
  ));

  // ════════════════ BUILD ═══════════════════════
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(scaffoldBackgroundColor: _C.bg),
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Column(children: [
          _buildAppHeader(),
          _buildProgressBanner(),
          Expanded(child: SingleChildScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildCaseInfoBanner(),
              const SizedBox(height: 20),
              _section(Icons.record_voice_over_rounded, 'Witness Statement', 'گواہ کا بیان', '01'),
              const SizedBox(height: 10),
              _buildDescBox(),
              const SizedBox(height: 20),
              _section(Icons.person_pin_rounded, 'Identity Profile', 'شناختی پروفائل', '02'),
              const SizedBox(height: 10),
              _buildIdentitySection(),
              const SizedBox(height: 20),
              _section(Icons.accessibility_new_rounded, 'Physical Characteristics', 'جسمانی خصوصیات', '03'),
              const SizedBox(height: 10),
              _buildPhysicalSection(),
              const SizedBox(height: 20),
              _section(Icons.face_rounded, 'Facial Features', 'چہرے کی خصوصیات', '04'),
              const SizedBox(height: 10),
              ..._faceOptions.map(_buildFaceCard),
              const SizedBox(height: 20),
              _section(Icons.style_rounded, 'Accessories & Extras', 'زیورات اور اضافی', '05'),
              const SizedBox(height: 10),
              _buildAccessoriesSection(),
              const SizedBox(height: 20),
              _section(Icons.edit_note_rounded, 'Additional Notes', 'اضافی نوٹس', '06'),
              const SizedBox(height: 10),
              _buildPromptBox(),
              const SizedBox(height: 28),
              _buildGenerateBtn(),
              if (_isGenerating) ...[const SizedBox(height: 20), _buildLoadingCard()],
              if (_errorMsg != null) ...[const SizedBox(height: 16), _buildErrorCard()],
              if (_imageUrl != null) ...[
                const SizedBox(height: 28),
                _section(Icons.image_search_rounded, 'Generated Composite', 'تیار کردہ خاکہ', '✓'),
                const SizedBox(height: 12),
                _buildResultCard(),
              ],
            ]),
          )),
        ]),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────
  Widget _buildAppHeader() => AnimatedBuilder(
    animation: _headerAnim,
    builder: (_, child) => Opacity(
      opacity: _headerAnim.value.clamp(0, 1),
      child: Transform.translate(offset: Offset(0, -20 * (1 - _headerAnim.value)), child: child),
    ),
    child: Container(
      decoration: const BoxDecoration(
        gradient: _C.headerGrad,
        border: Border(bottom: BorderSide(color: _C.border)),
      ),
      child: SafeArea(bottom: false, child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 10, 12, 0), child: Row(children: [
          GestureDetector(
            onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
            child: Container(width: 36, height: 36,
              decoration: BoxDecoration(color: _C.card, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.border)),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: _C.blue, size: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('CRIMINAL', style: TextStyle(color: _C.blue, fontSize: 16,
                  fontWeight: FontWeight.w900, letterSpacing: 2.5)),
              const Text(' SKETCH', style: TextStyle(color: _C.textPrimary, fontSize: 16,
                  fontWeight: FontWeight.w900, letterSpacing: 2.5)),
              const SizedBox(width: 8),
              const _PulseDot(size: 6),
              const SizedBox(width: 4),
              const Text('LIVE', style: TextStyle(color: _C.green, fontSize: 8,
                  fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            ]),
            const Text('AI FORENSIC COMPOSITE SYSTEM',
                style: TextStyle(color: _C.textMuted, fontSize: 9, letterSpacing: 1.5)),
          ])),
          GestureDetector(
            onTap: _imageUrl != null || _descCtrl.text.isNotEmpty ? _showResetDialog : null,
            child: Container(width: 36, height: 36,
              decoration: BoxDecoration(color: _C.card, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.border)),
              child: Icon(Icons.restart_alt_rounded,
                  color: _imageUrl != null || _descCtrl.text.isNotEmpty ? _C.red : _C.textMuted,
                  size: 18)),
          ),
        ])),
        Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 12), child: Row(children: [
          _statChip(Icons.tune_rounded, '$_completedAttrs/$_totalAttrs', 'Filled', _C.blue),
          const SizedBox(width: 8),
          _statChip(Icons.mic_rounded, _speechAvail ? 'Ready' : 'N/A',
              'Voice', _speechAvail ? _C.green : _C.textMuted),
          const SizedBox(width: 8),
          _statChip(Icons.image_rounded, _imageUrl != null ? 'Done' : 'Pending',
              'Sketch', _imageUrl != null ? _C.green : _C.textMuted),
          const Spacer(),
          if (_completedAttrs > 0) Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _C.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _C.green.withOpacity(0.3)),
            ),
            child: Text('${((_completedAttrs / _totalAttrs) * 100).toInt()}% done',
                style: const TextStyle(color: _C.green, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ])),
      ])),
    ),
  );

  Widget _statChip(IconData icon, String value, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(children: [
      Icon(icon, color: color, size: 11),
      const SizedBox(width: 4),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: _C.textMuted, fontSize: 8, letterSpacing: 0.5)),
      ]),
    ]),
  );

  Widget _buildProgressBanner() {
    if (!_isGenerating && _completedAttrs == 0) return const SizedBox.shrink();
    return Container(
      color: _C.surface,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Column(children: [
        Row(children: [
          Text(_isGenerating ? _statusMsg : 'Profile: $_completedAttrs/$_totalAttrs filled',
              style: const TextStyle(color: _C.textSecondary, fontSize: 10)),
          const Spacer(),
          Text(_isGenerating ? '${(_progress * 100).toInt()}%'
              : '${((_completedAttrs / _totalAttrs) * 100).toInt()}%',
              style: const TextStyle(color: _C.blue, fontSize: 10, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: _isGenerating ? _progress : _completedAttrs / _totalAttrs,
            backgroundColor: _C.border,
            valueColor: AlwaysStoppedAnimation<Color>(_isGenerating ? _C.blue : _C.green),
            minHeight: 3,
          )),
      ]),
    );
  }

  Widget _buildCaseInfoBanner() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _C.amber.withOpacity(0.06), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _C.amber.withOpacity(0.25)),
    ),
    child: Row(children: [
      Icon(Icons.info_outline_rounded, color: _C.amber.withOpacity(0.8), size: 18),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('Fill as many attributes as possible for best results.',
            style: TextStyle(color: _C.textSecondary, fontSize: 12)),
        Text('بہترین نتائج کے لیے زیادہ سے زیادہ تفصیلات بھریں', style: _C.tsUrdu),
      ])),
    ]),
  );

  Widget _section(IconData icon, String title, String urdu, String num) => Row(children: [
    Container(width: 28, height: 28,
      decoration: BoxDecoration(color: _C.blue.withOpacity(0.15), borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _C.blue.withOpacity(0.3))),
      alignment: Alignment.center,
      child: Text(num, style: const TextStyle(color: _C.blue, fontSize: 10, fontWeight: FontWeight.w900))),
    const SizedBox(width: 10),
    Icon(icon, color: _C.blue, size: 16),
    const SizedBox(width: 8),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: _C.tsSectionTitle),
      Text(urdu, style: _C.tsUrdu),
    ]),
    const SizedBox(width: 10),
    Expanded(child: Container(height: 1, color: _C.border.withOpacity(0.5))),
  ]);

  Widget _buildDescBox() {
    final active = _isListening && _activeField == 'desc';
    return Container(
      decoration: BoxDecoration(
        color: _C.card, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: active ? _C.blue : _C.border, width: active ? 1.5 : 1),
        boxShadow: active ? [BoxShadow(color: _C.blue.withOpacity(0.15), blurRadius: 20, spreadRadius: -4)] : null,
      ),
      child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(14, 8, 6, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: TextField(
              controller: _descCtrl, maxLines: 5,
              style: const TextStyle(color: _C.textPrimary, fontSize: 13, height: 1.6),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Describe the suspect in detail…\n\n'
                    'ملزم کی تفصیل لکھیں: لمبا قد، گول چہرہ، کالی آنکھیں\n\n'
                    'Roman Urdu: Lamba qad, gol chehra, kali aankhein…',
                hintStyle: _C.tsHint,
              ),
            )),
            Column(children: [
              _micBtn('desc'),
              if (_descCtrl.text.isNotEmpty) IconButton(
                icon: const Icon(Icons.clear_rounded, color: _C.textMuted, size: 16),
                onPressed: () => setState(() => _descCtrl.clear()),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ]),
          ])),
        if (active) _buildWaveform(),
        _inputFooter('Speak or type in English or Roman Urdu',
            'انگریزی یا رومن اردو میں بولیں یا لکھیں'),
      ]),
    );
  }

  Widget _buildWaveform() => AnimatedBuilder(
    animation: _waveCtrl,
    builder: (_, __) => SizedBox(height: 32,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(22, (i) {
        final h = 4 + 16 * math.sin((i + _waveCtrl.value * 22) * 0.6).abs()
            * _soundLevel.clamp(0.2, 1.0);
        return Container(width: 3, height: h,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: _C.blue.withOpacity(0.5 + 0.5 * _waveCtrl.value),
            borderRadius: BorderRadius.circular(2)));
      })),
    ),
  );

  Widget _micBtn(String field) {
    final active = _isListening && _activeField == field;
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Transform.scale(scale: active ? _pulseAnim.value : 1, child: child),
      child: GestureDetector(
        onTap: () => _toggleMic(field),
        child: Container(width: 40, height: 40, margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? _C.blue.withOpacity(0.2) : _C.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? _C.blue : _C.border, width: active ? 1.5 : 1),
            boxShadow: active ? [BoxShadow(color: _C.blue.withOpacity(0.3), blurRadius: 12)] : null,
          ),
          child: Icon(active ? Icons.mic_rounded : Icons.mic_none_outlined,
              color: active ? _C.blue : _C.textMuted, size: 18)),
      ),
    );
  }

  Widget _inputFooter(String en, String ur) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: const BoxDecoration(color: _C.bg,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
    child: Row(children: [
      const Icon(Icons.lightbulb_outline_rounded, color: _C.textMuted, size: 11),
      const SizedBox(width: 6),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(en, style: const TextStyle(color: _C.blue, fontSize: 10, letterSpacing: 0.2)),
        Text(ur, style: _C.tsUrdu),
      ])),
    ]),
  );

  Widget _buildIdentitySection() => Column(children: [
    Row(children: [
      Expanded(child: _dropCard('Gender', 'جنس', Icons.wc_rounded, _gender,
          ['Male / مرد', 'Female / عورت', 'Unknown / نامعلوم'],
          (v) => setState(() => _gender = v))),
      const SizedBox(width: 10),
      Expanded(child: _dropCard('Ethnicity', 'نسل', Icons.public_rounded, _ethnicity,
          ['South Asian', 'East Asian', 'African', 'Caucasian',
           'Middle Eastern', 'Hispanic', 'Mixed', 'Unknown'],
          (v) => setState(() => _ethnicity = v))),
    ]),
    const SizedBox(height: 10),
    _dropCard('Age Group', 'عمر کا گروپ', Icons.cake_rounded, _ageGroup,
        ['Child (5-12)', 'Teen (13-19)', 'Young Adult (20-30)',
         'Adult (31-45)', 'Middle Age (46-60)', 'Senior (61+)'],
        (v) => setState(() => _ageGroup = v), fullWidth: true),
  ]);

  Widget _buildPhysicalSection() => Column(children: [
    Row(children: [
      Expanded(child: _dropCard('Build', 'جسمانی ساخت', Icons.fitness_center_rounded, _build,
          ['Slim', 'Average', 'Athletic', 'Heavy', 'Muscular', 'Obese'],
          (v) => setState(() => _build = v))),
      const SizedBox(width: 10),
      Expanded(child: _dropCard('Complexion', 'رنگ', Icons.palette_rounded, _complexion,
          ['Very Fair', 'Fair', 'Wheat', 'Medium', 'Olive', 'Dark', 'Very Dark'],
          (v) => setState(() => _complexion = v))),
    ]),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _dropCard('Hair Color', 'بالوں کا رنگ', Icons.format_color_fill_rounded, _hairColor,
          ['Black', 'Dark Brown', 'Light Brown', 'Blonde', 'Red', 'Grey', 'White', 'Bald', 'Dyed'],
          (v) => setState(() => _hairColor = v))),
      const SizedBox(width: 10),
      Expanded(child: _dropCard('Hair Style', 'بالوں کا انداز', Icons.cut_rounded, _hairStyle,
          ['Bald', 'Very Short', 'Short', 'Medium', 'Long', 'Curly', 'Wavy', 'Straight', 'Shaved sides'],
          (v) => setState(() => _hairStyle = v))),
    ]),
    const SizedBox(height: 10),
    _dropCard('Expression', 'چہرے کا تاثر', Icons.mood_rounded, _expression,
        ['Neutral', 'Angry', 'Sad', 'Scared', 'Smiling', 'Serious', 'Confused'],
        (v) => setState(() => _expression = v), fullWidth: true),
  ]);

  Widget _buildAccessoriesSection() => Row(children: [
    Expanded(child: _dropCard('Glasses', 'عینک', Icons.remove_red_eye_outlined, _glasses,
        ['None', 'Thin frame', 'Thick frame', 'Sunglasses', 'Half-rim', 'Rimless'],
        (v) => setState(() => _glasses = v))),
    const SizedBox(width: 10),
    Expanded(child: _dropCard('Head Covering', 'سر ڈھکنا', Icons.accessibility_rounded, _headCovering,
        ['None', 'Cap', 'Hat', 'Turban / پگڑی', 'Hijab / حجاب', 'Hood', 'Beanie'],
        (v) => setState(() => _headCovering = v))),
  ]);

  Widget _dropCard(String label, String urdu, IconData icon, String? value,
      List<String> opts, ValueChanged<String?> onChange, {bool fullWidth = false}) {
    final selected = value != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _C.card, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? _C.blue.withOpacity(0.5) : _C.border,
            width: selected ? 1.2 : 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: selected ? _C.blue : _C.textMuted, size: 12),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: selected ? _C.blue : _C.textSecondary,
              fontSize: 10, fontWeight: FontWeight.w600)),
          if (selected) ...[const Spacer(),
            GestureDetector(onTap: () => onChange(null),
                child: const Icon(Icons.close_rounded, color: _C.red, size: 12))],
        ]),
        Text(urdu, style: const TextStyle(color: _C.textMuted, fontSize: 9)),
        DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: value, isExpanded: true,
          hint: const Text('Select…', style: TextStyle(color: _C.textMuted, fontSize: 12)),
          dropdownColor: _C.card,
          style: const TextStyle(color: _C.textPrimary, fontSize: 12),
          icon: const Icon(Icons.expand_more_rounded, color: _C.blue, size: 16),
          onChanged: onChange,
          items: opts.map((o) => DropdownMenuItem(value: o,
              child: Text(o, style: const TextStyle(fontSize: 12)))).toList(),
        )),
      ]),
    );
  }

  Widget _buildFaceCard(FaceOption opt) {
    final sel = opt.selected != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: sel ? opt.accentColor.withOpacity(0.05) : _C.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sel ? opt.accentColor.withOpacity(0.5) : _C.border,
            width: sel ? 1.3 : 1),
        boxShadow: sel ? [BoxShadow(color: opt.accentColor.withOpacity(0.1),
            blurRadius: 16, spreadRadius: -4)] : null,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: Container(width: 36, height: 36,
            decoration: BoxDecoration(color: opt.accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(opt.icon, color: opt.accentColor, size: 18)),
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(opt.label, style: TextStyle(color: sel ? _C.textPrimary : _C.textSecondary,
                fontSize: 13, fontWeight: FontWeight.w700)),
            Text('${opt.labelUrdu} · ${opt.description}',
                style: const TextStyle(color: _C.textMuted, fontSize: 10)),
          ]),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (sel) ...[
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: opt.accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(opt.selected!, style: TextStyle(color: opt.accentColor,
                    fontSize: 9, fontWeight: FontWeight.w700))),
              const SizedBox(width: 6),
              GestureDetector(onTap: () => setState(() => opt.selected = null),
                  child: const Icon(Icons.close_rounded, color: _C.red, size: 14)),
              const SizedBox(width: 4),
            ],
            Icon(Icons.expand_more_rounded,
                color: sel ? opt.accentColor : _C.textMuted, size: 18),
          ]),
          children: [Wrap(
            spacing: 8, runSpacing: 8,
            children: opt.choices.map((c) {
              final isSel = opt.selected == c;
              return GestureDetector(
                onTap: () { setState(() => opt.selected = isSel ? null : c); HapticFeedback.selectionClick(); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSel ? opt.accentColor.withOpacity(0.2) : _C.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSel ? opt.accentColor : _C.border,
                        width: isSel ? 1.3 : 1),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (isSel) ...[Icon(Icons.check_rounded, color: opt.accentColor, size: 11),
                      const SizedBox(width: 4)],
                    Text(c, style: TextStyle(color: isSel ? opt.accentColor : _C.textSecondary,
                        fontSize: 12, fontWeight: isSel ? FontWeight.w700 : FontWeight.w400)),
                  ]),
                ),
              );
            }).toList(),
          )],
        ),
      ),
    );
  }

  Widget _buildPromptBox() {
    final active = _isListening && _activeField == 'prompt';
    return Container(
      decoration: BoxDecoration(
        color: _C.card, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: active ? _C.cyan : _C.border, width: active ? 1.5 : 1),
      ),
      child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(14, 8, 6, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: TextField(
              controller: _promptCtrl, maxLines: 4,
              style: const TextStyle(color: _C.textPrimary, fontSize: 13, height: 1.6),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Add special notes, style or extra clues…\n\n'
                    'اضافی نوٹس: "لال قمیض میں تھا" یا "بائیں آنکھ کے قریب نشان"',
                hintStyle: _C.tsHint,
              ),
            )),
            _micBtn('prompt'),
          ])),
        if (active) _buildWaveform(),
        _inputFooter('Extra style, expression or witness clues',
            'انداز، تاثرات یا گواہ کے اضافی اشارے'),
      ]),
    );
  }

  Widget _buildGenerateBtn() => Column(children: [
    if (_completedAttrs < 3) Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _C.amber.withOpacity(0.06), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.amber.withOpacity(0.2))),
      child: Row(children: [
        Icon(Icons.warning_amber_rounded, color: _C.amber.withOpacity(0.7), size: 16),
        const SizedBox(width: 8),
        const Expanded(child: Text(
          'Fill at least 3 attributes for better results.\n'
          'بہتر نتیجے کے لیے کم از کم 3 خصوصیات بھریں',
          style: TextStyle(color: _C.textSecondary, fontSize: 11, height: 1.5))),
      ]),
    ),
    SizedBox(width: double.infinity, height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _isGenerating ? null : _C.generateGrad,
          color: _isGenerating ? _C.card : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isGenerating ? null :
              [BoxShadow(color: _C.blue.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          onPressed: _isGenerating ? null : _generate,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _isGenerating
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _C.blue))
                : const Icon(Icons.person_search_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Column(mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_isGenerating ? 'Generating Composite Sketch…' : 'Generate Forensic Sketch',
                  style: const TextStyle(color: Colors.white, fontSize: 14,
                      fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              Text(_isGenerating ? 'خاکہ بنایا جا رہا ہے…' : 'فرانزک خاکہ بنائیں',
                  style: const TextStyle(color: Colors.white60, fontSize: 10)),
            ]),
          ]),
        ),
      )),
  ]);

  Widget _buildLoadingCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: _C.card, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border)),
    child: Column(children: [
      Row(children: [
        const _PulseDot(color: _C.blue, size: 10),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_statusMsg, style: const TextStyle(color: _C.textPrimary,
              fontSize: 13, fontWeight: FontWeight.w600)),
          const Text('AI فرانزک خاکہ بنا رہا ہے', style: _C.tsUrdu),
        ]),
        const Spacer(),
        Text('${(_progress * 100).toInt()}%',
            style: const TextStyle(color: _C.blue, fontSize: 22, fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 16),
      Row(children: List.generate(5, (i) {
        final filled = _progress >= (i + 1) / 5;
        final partial = _progress > i / 5 && _progress < (i + 1) / 5;
        return Expanded(child: Container(
          margin: EdgeInsets.only(right: i < 4 ? 4 : 0), height: 6,
          decoration: BoxDecoration(
            color: filled ? _C.blue : partial ? _C.blue.withOpacity(0.4) : _C.border,
            borderRadius: BorderRadius.circular(3)),
        ));
      })),
      const SizedBox(height: 12),
      const _Shimmer(width: double.infinity, height: 120,
          borderRadius: BorderRadius.all(Radius.circular(12))),
    ]),
  );

  Widget _buildErrorCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _C.red.withOpacity(0.06), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.red.withOpacity(0.3))),
    child: Row(children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(color: _C.red.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.error_outline_rounded, color: _C.red, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Generation Failed', style: TextStyle(color: _C.red,
            fontSize: 12, fontWeight: FontWeight.w700)),
        const Text('خاکہ بنانے میں ناکامی', style: _C.tsUrdu),
        const SizedBox(height: 4),
        Text(_errorMsg!, style: const TextStyle(color: _C.textSecondary, fontSize: 11)),
      ])),
      IconButton(icon: const Icon(Icons.close_rounded, color: _C.red, size: 18),
          onPressed: () => setState(() => _errorMsg = null)),
    ]),
  );

  Widget _buildResultCard() => FadeTransition(
    opacity: _fadeAnim,
    child: Column(children: [
      Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.borderHi, width: 1.5),
          boxShadow: [BoxShadow(color: _C.blue.withOpacity(0.2), blurRadius: 40, spreadRadius: -8)]),
        child: ClipRRect(borderRadius: BorderRadius.circular(20),
          child: Screenshot(controller: _screenshotCtrl,
            child: Image.network(_imageUrl!, fit: BoxFit.contain,
              loadingBuilder: (_, child, prog) => prog == null ? child
                  : Container(height: 300, color: _C.card, alignment: Alignment.center,
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        CircularProgressIndicator(
                          value: prog.expectedTotalBytes != null
                              ? prog.cumulativeBytesLoaded / prog.expectedTotalBytes! : null,
                          color: _C.blue),
                        const SizedBox(height: 12),
                        const Text('Loading sketch…',
                            style: TextStyle(color: _C.textMuted, fontSize: 12)),
                      ])),
              errorBuilder: (_, __, ___) => Container(height: 200, color: _C.card,
                alignment: Alignment.center,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
                  Icon(Icons.broken_image_outlined, color: _C.textMuted, size: 48),
                  SizedBox(height: 8),
                  Text('Image failed to load',
                      style: TextStyle(color: _C.textMuted, fontSize: 12)),
                ])),
            )),
        ),
      ),
      const SizedBox(height: 8),
      Row(children: [
        _badge(Icons.check_circle_rounded, 'AI Generated', _C.green),
        const SizedBox(width: 8),
        _badge(Icons.hd_rounded, 'HD Quality', _C.blue),
        const SizedBox(width: 8),
        _badge(Icons.security_rounded, 'Forensic', _C.amber),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _resultBtn(Icons.download_rounded, 'Download', 'ڈاؤن لوڈ',
            _C.blueGrad, _download)),
        const SizedBox(width: 8),
        Expanded(child: _resultBtn(Icons.share_rounded, 'Share', 'شیئر',
            _C.greenGrad, _share)),
        const SizedBox(width: 8),
        _resultBtn(Icons.refresh_rounded, 'Redo', 'دوبارہ',
            const LinearGradient(colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)]),
            _generate, compact: true),
      ]),
    ]),
  );

  Widget _badge(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 10),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _resultBtn(IconData icon, String label, String urdu,
      LinearGradient grad, VoidCallback onTap, {bool compact = false}) =>
    GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(height: 50,
        padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 0),
        decoration: BoxDecoration(gradient: grad, borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 16),
          if (!compact) ...[
            const SizedBox(width: 6),
            Column(mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: Colors.white,
                  fontSize: 12, fontWeight: FontWeight.w800)),
              Text(urdu, style: const TextStyle(color: Colors.white60, fontSize: 9)),
            ]),
          ],
        ]),
      ),
    );

  void _showResetDialog() => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: _C.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(children: [
        Icon(Icons.restart_alt_rounded, color: _C.red, size: 20),
        SizedBox(width: 8),
        Text('Reset All', style: TextStyle(color: _C.textPrimary, fontSize: 16)),
      ]),
      content: const Text(
        'This will clear all attributes and the generated sketch.\n\n'
        'کیا آپ سب صاف کرنا چاہتے ہیں؟',
        style: TextStyle(color: _C.textSecondary, fontSize: 13, height: 1.6)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _C.textMuted))),
        TextButton(
          onPressed: () { Navigator.pop(context); _resetAll(); },
          child: const Text('Reset', style: TextStyle(color: _C.red, fontWeight: FontWeight.w700))),
      ],
    ),
  );

  @override
  void dispose() {
    _descCtrl.dispose(); _promptCtrl.dispose(); _scrollCtrl.dispose();
    _pulseCtrl.dispose(); _fadeCtrl.dispose(); _headerCtrl.dispose(); _waveCtrl.dispose();
    _speech.stop();
    super.dispose();
  }
}