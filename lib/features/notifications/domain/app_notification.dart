class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.titleKey,
    required this.bodyKey,
    required this.createdAt,
    this.entityType,
    this.entityId,
    this.payload = const {},
    this.readAt,
  });

  final String id;
  final String kind;
  final String titleKey;
  final String bodyKey;
  final DateTime createdAt;
  final String? entityType;
  final String? entityId;
  final Map<String, dynamic> payload;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      kind: json['kind'] as String,
      titleKey: json['title_key'] as String,
      bodyKey: json['body_key'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id'] as String?,
      payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String),
    );
  }
}
