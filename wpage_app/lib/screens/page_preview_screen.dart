import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/page_model.dart';
import '../services/wpage_api_service.dart';

class PagePreviewScreen extends StatefulWidget {
  const PagePreviewScreen({super.key, required this.page});

  final PageModel page;

  @override
  State<PagePreviewScreen> createState() => _PagePreviewScreenState();
}

class _PagePreviewScreenState extends State<PagePreviewScreen> {
  final _api = WPageApiService();
  late final WebViewController _controller;
  bool _publishing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(_api.renderUrl(widget.page.alias)));
  }

  Future<void> _publish() async {
    setState(() {
      _publishing = true;
      _error = null;
    });

    try {
      final result = await _api.publishPage(widget.page.alias);
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/success',
        arguments: result,
      );
    } on WPageApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: Column(
        children: [
          Expanded(child: WebViewWidget(controller: _controller)),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _publishing ? null : _publish,
                  icon: _publishing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.public),
                  label: Text(_publishing ? 'Publishing…' : 'Publish My Page'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
