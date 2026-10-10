import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/audio_item.dart';
import '../services/audio_service.dart';

final audioRepositoryProvider = Provider((ref) => AudioRepository());

final audioGroupedProvider = FutureProvider<Map<String, List<AudioItem>>>((
  ref,
) async {
  final repo = ref.read(audioRepositoryProvider);
  return repo.fetchAudioGroupedByArtist(
    categoryId: '153,200,201',
  ); // All Audio tracks from previous Audio Hub
});

// Alias for backwards compatibility
final bhajansGroupedProvider = audioGroupedProvider;

final allAudioTracksProvider = FutureProvider<List<AudioItem>>((ref) async {
  final grouped = await ref.watch(audioGroupedProvider.future);
  final all = grouped.values
      .expand((element) => element)
      .where((item) => !item.audioUrl.contains('youtu'))
      .toList();
  all.sort((a, b) {
    final dateComp = b.createdAt.compareTo(a.createdAt);
    if (dateComp != 0) return dateComp;
    final bId = int.tryParse(b.id) ?? 0;
    final aId = int.tryParse(a.id) ?? 0;
    return bId.compareTo(aId);
  });
  return all;
});

final videosProvider = FutureProvider<List<AudioItem>>((ref) async {
  final repo = ref.read(audioRepositoryProvider);
  final items = await repo.fetchAudioItems(
    categoryId: 99,
  ); // Category 99 = Video
  // Sort descending by date (newest first)
  items.sort((a, b) {
    final dateComp = b.createdAt.compareTo(a.createdAt);
    if (dateComp != 0) return dateComp;
    final bId = int.tryParse(b.id) ?? 0;
    final aId = int.tryParse(a.id) ?? 0;
    return bId.compareTo(aId);
  });
  return items;
});

class AudioRepository {
  final AudioService _audioService = AudioService();

  Future<List<AudioItem>> fetchAudioItems({
    dynamic categoryId = '153,200,201',
  }) async {
    try {
      // Fetch directly from WordPress REST API via AudioService
      return await _audioService.fetchAudioTracks(categoryId: categoryId);
    } catch (e) {
      // Return empty on failure to ensure UI fallback handles it gracefully
      return [];
    }
  }

  Future<Map<String, List<AudioItem>>> fetchAudioGroupedByArtist({
    dynamic categoryId = '153,200,201',
  }) async {
    final allItems = await fetchAudioItems(categoryId: categoryId);

    // We already filter empty URLs in AudioService, but we can ensure they are published
    final publishedItems = allItems.where((item) => item.isPublished).toList();

    // Sort descending by date (newest first)
    publishedItems.sort((a, b) {
      final dateComp = b.createdAt.compareTo(a.createdAt);
      if (dateComp != 0) return dateComp;
      final bId = int.tryParse(b.id) ?? 0;
      final aId = int.tryParse(a.id) ?? 0;
      return bId.compareTo(aId);
    });

    final Map<String, List<AudioItem>> grouped = {};
    for (var item in publishedItems) {
      final artist = item.artist.trim().isNotEmpty
          ? item.artist.trim()
          : 'Pooj Samadha Ashram';
      grouped.putIfAbsent(artist, () => []).add(item);
    }
    return grouped;
  }
}
