import 'package:flutter/material.dart';

import '../services/wpage_api_service.dart';

class GeneratePageScreen extends StatefulWidget {
  const GeneratePageScreen({super.key, required this.purpose});

  final String purpose;

  @override
  State<GeneratePageScreen> createState() => _GeneratePageScreenState();
}

class _GeneratePageScreenState extends State<GeneratePageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();
  final _aliasController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _api = WPageApiService();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _identityController.dispose();
    _aliasController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _api.generatePage(
        identity: _identityController.text.trim(),
        alias: _aliasController.text.trim(),
        purpose: widget.purpose,
        description: _descriptionController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/review',
        arguments: result,
      );
    } on WPageApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not create your page. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tell Us About You')),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _loading,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Chip(label: Text(widget.purpose)),
                  const SizedBox(height: 16),
                  Text(
                    'Describe yourself or your business in plain language.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _identityController,
                    decoration: const InputDecoration(
                      labelText: 'Email or identity',
                      border: OutlineInputBorder(),
                      hintText: 'you@example.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _aliasController,
                    decoration: const InputDecoration(
                      labelText: 'Your page name (URL)',
                      border: OutlineInputBorder(),
                      hintText: 'john',
                      helperText: 'Your page will be wpage.app/your-name',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(v.trim())) {
                        return 'Use letters, numbers, - or _ only';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                      hintText:
                          'Example: I am a nurse in Manchester looking for hospital roles.',
                    ),
                    maxLines: 5,
                    validator: (v) =>
                        v == null || v.trim().length < 10
                            ? 'Please write at least a few sentences'
                            : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _loading ? null : _generate,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      _loading ? 'Creating your page…' : 'Create My Page',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
