class Ashram {
  final int id;
  final String title;
  final String content;
  final String? imageUrl;
  final List<int> countryIds;
  final String? link;
  final String? phone;
  final String? mapUrl;
  final String? address;

  Ashram({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.countryIds,
    this.link,
    this.phone,
    this.mapUrl,
    this.address,
  });

  bool get hasPhone => phone != null && phone!.trim().isNotEmpty;
  bool get hasMapUrl => mapUrl != null && mapUrl!.trim().isNotEmpty;

  factory Ashram.fromJson(Map<String, dynamic> json) {
    String? imageUrl;

    // Extract featured image from _embedded if available
    try {
      if (json.containsKey('_embedded') &&
          json['_embedded']['wp:featuredmedia'] != null) {
        final mediaList = json['_embedded']['wp:featuredmedia'] as List;
        if (mediaList.isNotEmpty && mediaList.first is Map) {
          final media = mediaList.first as Map<String, dynamic>;
          if (media['source_url'] != null) {
            imageUrl = media['source_url']?.toString();
          }
        }
      }
    } catch (_) {}

    // Title
    String title = '';
    if (json['title'] is Map) {
      title = json['title']['rendered']?.toString() ?? '';
    } else {
      title = json['title']?.toString() ?? '';
    }

    // Content
    String content = '';
    if (json['content'] is Map) {
      content = json['content']['rendered']?.toString() ?? '';
    } else {
      content = json['content']?.toString() ?? '';
    }

    // Country IDs
    final List<int> countryIds = [];
    if (json['country'] is List) {
      for (final c in json['country']) {
        final id = int.tryParse(c.toString());
        if (id != null) countryIds.add(id);
      }
    }

    // Dynamic phone, mapUrl, address parsing from ashram_details or meta/root fields
    String? phone;
    String? mapUrl;
    String? address;

    if (json.containsKey('ashram_details') && json['ashram_details'] is Map) {
      final details = json['ashram_details'] as Map<String, dynamic>;
      phone = details['phone']?.toString();
      mapUrl = details['map_url']?.toString();
      address = details['address']?.toString();
    }

    if (json.containsKey('meta') && json['meta'] is Map) {
      final meta = json['meta'] as Map<String, dynamic>;
      phone ??=
          meta['phone']?.toString() ?? meta['ashram_primary_phone']?.toString();
      mapUrl ??=
          meta['map_url']?.toString() ??
          meta['ashram_google_maps_url']?.toString();
      address ??=
          meta['address']?.toString() ?? meta['ashram_address']?.toString();
    }

    if (phone == null || phone.isEmpty) {
      phone =
          json['phone']?.toString() ?? json['ashram_primary_phone']?.toString();
    }
    if (mapUrl == null || mapUrl.isEmpty) {
      mapUrl =
          json['map_url']?.toString() ??
          json['ashram_google_maps_url']?.toString();
    }
    if (address == null || address.isEmpty) {
      address =
          json['address']?.toString() ?? json['ashram_address']?.toString();
    }

    // Fallback: extract tel: link from content HTML if present
    if (phone == null || phone.isEmpty) {
      final telMatch = RegExp(r'tel:([0-9+\s\-]{7,15})').firstMatch(content);
      if (telMatch != null) {
        phone = telMatch.group(1);
      }
    }

    return Ashram(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: title,
      content: content,
      imageUrl: imageUrl,
      countryIds: countryIds,
      link: json['link']?.toString() ?? 'https://jaisamadha.com',
      phone: phone?.trim().isNotEmpty == true ? phone!.trim() : null,
      mapUrl: mapUrl?.trim().isNotEmpty == true ? mapUrl!.trim() : null,
      address: address?.trim().isNotEmpty == true ? address!.trim() : null,
    );
  }
}
