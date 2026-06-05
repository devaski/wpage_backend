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
  bool _loadingPreview = true;
  bool _publishing = false;
  String? _previewError;
  String? _publishError;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    setState(() {
      _loadingPreview = true;
      _previewError = null;
    });

    try {
      final html = await _api.fetchPreviewHtml(widget.page);
      await _controller.loadHtmlString(html);
    } on WPageApiException catch (e) {
      setState(() => _previewError = e.message);
    } catch (_) {
      setState(() => _previewError = 'Could not load preview. Please try again.');
    } finally {
      if (mounted) setState(() => _loadingPreview = false);
    }
  }

  Future<void> _publish() async {
    setState(() {
      _publishing = true;
      _publishError = null;
    });

    try {
      await _api.updatePage(widget.page);
      final result = await _api.publishPage(widget.page.alias);
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/success',
        arguments: result,
      );
    } on WPageApiException catch (e) {
      setState(() => _publishError = e.message);
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
          Expanded(
            child: _loadingPreview
                ? const Center(child: CircularProgressIndicator())
                : _previewError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _previewError!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _loadPreview,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : WebViewWidget(controller: _controller),
          ),
          if (_publishError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_publishError!, style: const TextStyle(color: Colors.red)),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _publishing || _loadingPreview ? null : _publish,
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
