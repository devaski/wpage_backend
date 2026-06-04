class BlockModel {
  BlockModel({
    required this.id,
    required this.type,
    required this.content,
    this.order,
  });

  final String id;
  final String type;
  final Map<String, dynamic> content;
  final int? order;

  factory BlockModel.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];
    Map<String, dynamic> contentMap;
    if (rawContent is Map<String, dynamic>) {
      contentMap = Map<String, dynamic>.from(rawContent);
    } else if (rawContent is String) {
      contentMap = {'text': rawContent};
    } else {
      contentMap = {};
    }

    return BlockModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      order: json['order'] as int?,
      content: contentMap,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'type': type,
      'content': content,
    };
    if (order != null) {
      json['order'] = order;
    }
    return json;
  }

  BlockModel copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? content,
    int? order,
  }) {
    return BlockModel(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? Map<String, dynamic>.from(this.content),
      order: order ?? this.order,
    );
  }

  String get textContent => content['text']?.toString() ?? '';

  set textContent(String value) => content['text'] = value;

  String get heading => content['heading']?.toString() ?? '';

  set heading(String value) => content['heading'] = value;

  String get subheading => content['subheading']?.toString() ?? '';

  set subheading(String value) => content['subheading'] = value;

  String get email => content['email']?.toString() ?? '';

  set email(String value) => content['email'] = value;
}
