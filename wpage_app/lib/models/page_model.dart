import 'block_model.dart';

class PageModel {
  PageModel({
    required this.identity,
    required this.alias,
    required this.purpose,
    required this.title,
    required this.description,
    required this.sections,
    this.pageId,
    this.publicUrl,
    this.published = false,
    this.geoLocationEnabled = false,
    this.location,
    this.updatedAt,
    this.publishedAt,
  });

  final String? pageId;
  final String? publicUrl;
  final String identity;
  final String alias;
  final String purpose;
  final String title;
  final String description;
  final List<BlockModel> sections;
  final bool published;
  final bool geoLocationEnabled;
  final String? location;
  final String? updatedAt;
  final String? publishedAt;

  factory PageModel.fromJson(Map<String, dynamic> json) {
    final sectionsJson = json['sections'] as List<dynamic>? ?? [];
    return PageModel(
      pageId: json['pageId'] as String?,
      publicUrl: json['publicUrl'] as String?,
      identity: json['identity'] as String? ?? '',
      alias: json['alias'] as String? ?? '',
      purpose: json['purpose'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      published: json['published'] as bool? ?? false,
      geoLocationEnabled: json['geoLocationEnabled'] as bool? ?? false,
      location: json['location'] as String?,
      updatedAt: json['updatedAt'] as String?,
      publishedAt: json['publishedAt'] as String?,
      sections: sectionsJson
          .map((s) => BlockModel.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'identity': identity,
      'alias': alias,
      'purpose': purpose,
      'title': title,
      'description': description,
      'sections': sections.map((s) => s.toJson()).toList(),
    };
  }

  PageModel copyWith({
    String? pageId,
    String? publicUrl,
    String? identity,
    String? alias,
    String? purpose,
    String? title,
    String? description,
    List<BlockModel>? sections,
    bool? published,
    String? updatedAt,
    String? publishedAt,
  }) {
    return PageModel(
      pageId: pageId ?? this.pageId,
      publicUrl: publicUrl ?? this.publicUrl,
      identity: identity ?? this.identity,
      alias: alias ?? this.alias,
      purpose: purpose ?? this.purpose,
      title: title ?? this.title,
      description: description ?? this.description,
      sections: sections ?? this.sections,
      published: published ?? this.published,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}

class GeneratePageResult {
  GeneratePageResult({
    required this.pageId,
    required this.publicUrl,
    required this.page,
  });

  final String pageId;
  final String publicUrl;
  final PageModel page;

  factory GeneratePageResult.fromJson(Map<String, dynamic> json) {
    return GeneratePageResult(
      pageId: json['pageId'] as String,
      publicUrl: json['publicUrl'] as String,
      page: PageModel.fromJson(json['page'] as Map<String, dynamic>),
    );
  }
}

class PublishResult {
  PublishResult({
    required this.alias,
    required this.publicUrl,
    required this.published,
    required this.publishedAt,
  });

  final String alias;
  final String publicUrl;
  final bool published;
  final String publishedAt;

  factory PublishResult.fromJson(Map<String, dynamic> json) {
    return PublishResult(
      alias: json['alias'] as String,
      publicUrl: json['publicUrl'] as String,
      published: json['published'] as bool? ?? true,
      publishedAt: json['publishedAt'] as String? ?? '',
    );
  }
}
