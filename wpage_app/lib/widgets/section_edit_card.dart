import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/block_model.dart';

class SectionEditCard extends StatelessWidget {
  const SectionEditCard({
    super.key,
    required this.section,
    required this.onChanged,
  });

  final BlockModel section;
  final ValueChanged<BlockModel> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = SectionLabels.forType(section.type);
    if (!SectionLabels.isEditable(section.type)) {
      return Card(
        child: ListTile(
          title: Text(label),
          subtitle: const Text('This section was created for you.'),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ..._fieldsForSection(section, onChanged),
          ],
        ),
      ),
    );
  }

  List<Widget> _fieldsForSection(
    BlockModel section,
    ValueChanged<BlockModel> onChanged,
  ) {
    switch (section.type) {
      case 'title':
        return [
          _field('Main title', section.heading, (v) {
            section.heading = v;
            onChanged(section);
          }),
          _field('Subtitle', section.subheading, (v) {
            section.subheading = v;
            onChanged(section);
          }),
        ];
      case 'contact':
        return [
          _field('Email', section.email, (v) {
            section.email = v;
            onChanged(section);
          }, keyboard: TextInputType.emailAddress),
        ];
      case 'about':
      case 'services':
        return [
          _field('Text', section.textContent, (v) {
            section.textContent = v;
            onChanged(section);
          }, maxLines: 4),
        ];
      case 'links':
        return [
          _field('Link text', section.textContent, (v) {
            section.textContent = v;
            onChanged(section);
          }, maxLines: 3),
        ];
      case 'image':
        return [
          _field('Image URL', section.content['src']?.toString() ?? section.content['url']?.toString() ?? '', (v) {
            section.content['src'] = v;
            onChanged(section);
          }),
          _field('Caption', section.content['caption']?.toString() ?? '', (v) {
            section.content['caption'] = v;
            onChanged(section);
          }),
        ];
      case 'video':
        return [
          _field('Video URL', section.content['url']?.toString() ?? '', (v) {
            section.content['url'] = v;
            onChanged(section);
          }),
        ];
      case 'table':
        return [
          _field('Table content', section.textContent, (v) {
            section.textContent = v;
            onChanged(section);
          }, maxLines: 4),
        ];
      default:
        return [
          _field('Content', section.textContent, (v) {
            section.textContent = v;
            onChanged(section);
          }, maxLines: 3),
        ];
    }
  }

  Widget _field(
    String label,
    String initial,
    ValueChanged<String> onChanged, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: initial,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
