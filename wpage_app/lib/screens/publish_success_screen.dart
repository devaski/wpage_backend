import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/page_model.dart';
import '../services/wpage_api_service.dart';

class PublishSuccessScreen extends StatefulWidget {
  const PublishSuccessScreen({super.key, required this.result});

  final PublishResult result;

  @override
  State<PublishSuccessScreen> createState() => _PublishSuccessScreenState();
}

class _PublishSuccessScreenState extends State<PublishSuccessScreen> {
  final _api = WPageApiService();
  String? _qrUrl;
  bool _loadingQr = true;

  @override
  void initState() {
    super.initState();
    _loadQr();
  }

  Future<void> _loadQr() async {
    try {
      final url = await _api.getQrCodeUrl(widget.result.alias);
      if (mounted) setState(() => _qrUrl = url);
    } catch (_) {
      // QR is optional — page is still published
    } finally {
      if (mounted) setState(() => _loadingQr = false);
    }
  }

  Future<void> _copyUrl() async {
    await Clipboard.setData(ClipboardData(text: widget.result.publicUrl));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Page is Live')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 72, color: Colors.green.shade600),
              const SizedBox(height: 16),
              Text(
                'Your page is live!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share this link with anyone.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: SelectableText(
                  widget.result.publicUrl,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _copyUrl,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Public URL'),
                ),
              ),
              const SizedBox(height: 32),
              if (_loadingQr)
                const CircularProgressIndicator()
              else if (_qrUrl != null) ...[
                Text(
                  'Scan to visit your page',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _qrUrl!,
                    width: 200,
                    height: 200,
                    errorBuilder: (_, __, ___) => const Icon(Icons.qr_code, size: 120),
                  ),
                ),
              ],
              const Spacer(),
              TextButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Create another page'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
