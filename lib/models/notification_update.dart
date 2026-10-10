class NotificationUpdate {
  final int id;
  final String title;
  final String excerpt;
  final String? imageUrl;
  final DateTime date;
  final String type;
  final bool isSandesh;

  NotificationUpdate({
    required this.id,
    required this.title,
    required this.excerpt,
    this.imageUrl,
    required this.date,
    required this.type,
    required this.isSandesh,
  });

  factory NotificationUpdate.fromJson(Map<String, dynamic> json) {
    return NotificationUpdate(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      excerpt: json['excerpt']?.toString() ?? '',
      imageUrl: json['image_url'] as String?,
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      type: json['type']?.toString() ?? 'general',
      isSandesh: json['is_sandesh'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'excerpt': excerpt,
      'image_url': imageUrl,
      'date': date.toIso8601String(),
      'type': type,
      'is_sandesh': isSandesh,
    };
  }
}
