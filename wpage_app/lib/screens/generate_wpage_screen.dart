import 'package:flutter/material.dart';

import '../services/wpage_api_service.dart';

class GenerateWPageScreen extends StatefulWidget {
  const GenerateWPageScreen({super.key, this.purpose});

  /// Optional context from purpose picker — not shown to user on this screen.
  final String? purpose;

  @override
  State<GenerateWPageScreen> createState() => _GenerateWPageScreenState();
}

class _GenerateWPageScreenState extends State<GenerateWPageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _api = WPageApiService();

  bool _geoEnabled = false;
  bool _loading = false;
  String? _error;

  static const _mockDetectedLocation = 'Chennai, Tamil Nadu, India';

  @override
  void dispose() {
    _identityController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _detectLocation() {
    setState(() {
      _locationController.text = _mockDetectedLocation;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location detected')),
    );
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _api.generateWPage(
        identity: _identityController.text.trim(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        geoLocationEnabled: _geoEnabled,
        location: _geoEnabled ? _locationController.text.trim() : null,
        purpose: widget.purpose,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/review',
        arguments: result,
      );
    } on WPageApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not create your page. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Your WPage')),
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
                  Text(
                    'Tell us about yourself or your business.',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We will create your page automatically — no design skills needed.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _identityController,
                    decoration: const InputDecoration(
                      labelText:
                          'Enter your Email, Mobile Number, or Brand Name',
                      hintText:
                          'example@email.com, +919876543210, or your brand name',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Enter WPage Title',
                      hintText: 'Example: Devarajan G - Patent Attorney',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Describe what you want to display on your WPage',
                      hintText:
                          'Describe your services, profile, products, contact details, links, images, videos, tables, or anything to be shown on the page.',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 6,
                    validator: (v) =>
                        v == null || v.trim().length < 10
                            ? 'Please write at least a few sentences'
                            : null,
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable Geo Location'),
                    subtitle: const Text(
                      'Show your location on your page',
                    ),
                    value: _geoEnabled,
                    onChanged: (value) {
                      setState(() {
                        _geoEnabled = value;
                        if (!value) {
                          _locationController.clear();
                        }
                      });
                    },
                  ),
                  if (_geoEnabled) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _detectLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Detect Location'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        hintText: 'City, State, Country',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (_geoEnabled && (v == null || v.trim().isEmpty)) {
                          return 'Enter or detect a location';
                        }
                        return null;
                      },
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 28),
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
                      _loading ? 'Creating your WPage…' : 'Generate WPage',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
