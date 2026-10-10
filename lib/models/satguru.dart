class Satguru {
  final int id;
  final String slug;
  final String title;
  final String content;
  final String excerpt;
  final int featuredMedia;
  final String? imageUrl;

  Satguru({
    required this.id,
    required this.slug,
    required this.title,
    required this.content,
    required this.excerpt,
    required this.featuredMedia,
    this.imageUrl,
  });

  factory Satguru.fromJson(Map<String, dynamic> json) {
    String? imgUrl;
    if (json['_embedded'] != null &&
        json['_embedded']['wp:featuredmedia'] != null &&
        json['_embedded']['wp:featuredmedia'].isNotEmpty) {
      final media = json['_embedded']['wp:featuredmedia'][0];
      imgUrl = media['source_url'] as String?;
    }

    return Satguru(
      id: json['id'] as int? ?? 0,
      slug: json['slug'] as String? ?? '',
      title: json['title'] != null
          ? json['title']['rendered'] as String? ?? ''
          : '',
      content: json['content'] != null
          ? json['content']['rendered'] as String? ?? ''
          : '',
      excerpt: json['excerpt'] != null
          ? json['excerpt']['rendered'] as String? ?? ''
          : '',
      featuredMedia: json['featured_media'] as int? ?? 0,
      imageUrl: imgUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'title': {'rendered': title},
      'content': {'rendered': content},
      'excerpt': {'rendered': excerpt},
      'featured_media': featuredMedia,
      if (imageUrl != null)
        '_embedded': {
          'wp:featuredmedia': [
            {'source_url': imageUrl},
          ],
        },
    };
  }
}
