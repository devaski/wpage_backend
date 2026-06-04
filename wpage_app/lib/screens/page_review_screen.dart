import 'package:flutter/material.dart';

import '../models/block_model.dart';
import '../models/page_model.dart';
import '../services/wpage_api_service.dart';
import '../widgets/section_edit_card.dart';

class PageReviewScreen extends StatefulWidget {
  const PageReviewScreen({super.key, required this.generateResult});

  final GeneratePageResult generateResult;

  @override
  State<PageReviewScreen> createState() => _PageReviewScreenState();
}

class _PageReviewScreenState extends State<PageReviewScreen> {
  final _api = WPageApiService();
  late PageModel _page;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _page = widget.generateResult.page.copyWith(
      pageId: widget.generateResult.pageId,
      publicUrl: widget.generateResult.publicUrl,
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final updated = await _api.updatePage(_page);
      setState(() {
        _page = _page.copyWith(
          title: updated.title,
          description: updated.description,
          sections: updated.sections,
          updatedAt: updated.updatedAt,
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved')),
        );
      }
    } on WPageApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _updateSection(int index, BlockModel section) {
    final sections = List<BlockModel>.from(_page.sections);
    sections[index] = section;
    setState(() => _page = _page.copyWith(sections: sections));
  }

  void _preview() {
    Navigator.pushNamed(
      context,
      '/preview',
      arguments: _page,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Your Page')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Review and edit your sections',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap any section below to update the text.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    initialValue: _page.title,
                    decoration: const InputDecoration(
                      labelText: 'Page title',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) =>
                        setState(() => _page = _page.copyWith(title: v)),
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(_page.sections.length, (index) {
                    return SectionEditCard(
                      section: _page.sections[index],
                      onChanged: (s) => _updateSection(index, s),
                    );
                  }),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving…' : 'Save'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _preview,
                      child: const Text('Preview'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
