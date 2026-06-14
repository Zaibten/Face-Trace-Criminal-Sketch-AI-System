// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class AIScreen extends StatefulWidget {
  static const String routeName = 'ai-screen';
  const AIScreen({Key? key}) : super(key: key);

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  WebViewController? _controller;

  double _loadingProgress = 0.0;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  static const Color _bgDark = Color(0xFF080C12);
  static const Color _bgNavy = Color(0xFF0A1628);
  static const Color _accent = Color(0xFF4D9FFF);

  // Base URL of your deployed Node.js API (no trailing slash)
  // e.g. https://your-backend.vercel.app
  static const String _apiBaseUrl = 'https://facetraceserver.vercel.app';

  // Fallback link used if the API call fails
  static const String _fallbackUrl =
      'https://github.com/Zaibten?tab=repositories';

  @override
  void initState() {
    super.initState();
    _fetchLinkAndLoad();
  }

  Future<void> _fetchLinkAndLoad() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    String urlToLoad = _fallbackUrl;

    try {
      final response = await http
          .get(Uri.parse('$_apiBaseUrl/api/ai-link'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['url'] != null) {
          urlToLoad = data['url'];
        }
      }
    } catch (e) {
      // Silently fall back to the default URL if the API call fails
      urlToLoad = _fallbackUrl;
    }

    _initWebView(urlToLoad);
  }

  void _initWebView(String url) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_bgDark)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() {
              _loadingProgress = progress / 100;
            });
          },
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (url) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = error.description;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    if (!mounted) return;
    setState(() {
      _controller = controller;
    });
  }

  Future<void> _reload() async {
    if (_controller == null) {
      await _fetchLinkAndLoad();
      return;
    }
    setState(() {
      _hasError = false;
      _isLoading = true;
      _loadingProgress = 0.0;
    });
    await _controller!.reload();
  }

  Future<bool> _onWillPop() async {
    if (_controller != null && await _controller!.canGoBack()) {
      await _controller!.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: _bgDark,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            // WebView (only once controller is ready)
            if (_controller != null && !_hasError)
              WebViewWidget(controller: _controller!),

            // Top loading progress bar
            if (_isLoading && !_hasError)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _loadingProgress == 0 ? null : _loadingProgress,
                  minHeight: 3,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(_accent),
                ),
              ),

            // Center loading indicator
            if (_isLoading && !_hasError)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _bgNavy.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _accent.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(_accent),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _controller == null
                            ? 'Fetching link...'
                            : 'Loading repositories...',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Error state
            if (_hasError) _buildErrorView(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _bgNavy,
              _bgNavy.withOpacity(0.95),
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: _accent.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _accent.withOpacity(0.25),
                  _accent.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _accent.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: _accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'AI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.refresh_rounded,
            color: _accent,
          ),
          onPressed: _reload,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _accent.withOpacity(0.15),
                    _accent.withOpacity(0.03),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _accent.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                color: _accent,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Couldn\'t load this page',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ??
                  'Check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _reload,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _accent.withOpacity(0.25),
                      _accent.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _accent.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: _accent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Retry',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}