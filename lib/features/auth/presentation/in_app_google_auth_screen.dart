import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/config/api_config.dart';
import '../providers/auth_provider.dart';

class InAppGoogleAuthScreen extends ConsumerStatefulWidget {
  const InAppGoogleAuthScreen({super.key});

  @override
  ConsumerState<InAppGoogleAuthScreen> createState() => _InAppGoogleAuthScreenState();
}

class _InAppGoogleAuthScreenState extends ConsumerState<InAppGoogleAuthScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() => _progress = progress / 100);
            }
          },
          onPageStarted: (url) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
            _checkForToken(url);
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
            _checkForToken(url);
          },
          onNavigationRequest: (request) {
            final url = request.url;
            debugPrint('🔗 Navigating to: $url');
            if (url.contains('token=')) {
              _handleCallback(url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('${ApiConfig.baseUrl}/api/auth/google/login'));
  }

  void _checkForToken(String url) {
    if (url.contains('token=')) {
      _handleCallback(url);
    }
  }

  Future<void> _handleCallback(String url) async {
    try {
      final uri = Uri.parse(url);
      final token = uri.queryParameters['token'];

      if (token != null && token.isNotEmpty) {
        if (mounted) {
          Navigator.of(context).pop();
        }
        await ref.read(authProvider.notifier).authenticateWithToken(token);
        return;
      }
    } catch (e) {
      debugPrint('❌ Error parsing auth callback token: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Sign-In failed. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF1E1B4B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Sign in with Google',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B4B),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: _isLoading
              ? LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  backgroundColor: const Color(0xFFEEF2FF),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                )
              : const SizedBox(height: 2),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading && _progress == 0)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6366F1),
              ),
            ),
        ],
      ),
    );
  }
}
