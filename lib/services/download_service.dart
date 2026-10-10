import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final downloadSyncProvider = NotifierProvider<DownloadSyncNotifier, int>(
  DownloadSyncNotifier.new,
);

class DownloadSyncNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() {
    state++;
  }
}

final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService(ref);
});

final isTrackDownloadedProvider = FutureProvider.family<bool, String>((
  ref,
  url,
) async {
  ref.watch(downloadSyncProvider);
  if (url.isEmpty || !url.startsWith('http')) return false;
  final service = ref.read(downloadServiceProvider);
  return service.isFileDownloaded(url);
});

class DownloadService {
  final Ref ref;
  final Dio _dio = Dio();

  DownloadService(this.ref);

  // Track download progress for different files by their URL or ID
  final Map<String, double> downloadProgress = {};

  Future<String> getLocalFilePath(String url) async {
    final dir = await getApplicationDocumentsDirectory();

    // Create a safe filename from the URL
    final uri = Uri.parse(url);
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    String fileName = segments.isNotEmpty
        ? segments.last
        : '${url.hashCode}.mp3';
    // Clean query parameters and hash fragments if present
    fileName = fileName.split('?').first.split('#').first;
    if (!fileName.contains('.')) {
      fileName = '$fileName.mp3';
    }
    return '${dir.path}/$fileName';
  }

  Future<bool> isFileDownloaded(String url) async {
    final path = await getLocalFilePath(url);
    final file = File(path);
    return await file.exists();
  }

  Future<String?> downloadFile(
    String url, {
    Function(double progress)? onProgress,
  }) async {
    String? path;
    try {
      path = await getLocalFilePath(url);

      // If it already exists, return the path immediately
      if (await isFileDownloaded(url)) {
        return path;
      }

      await _dio.download(
        url,
        path,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            downloadProgress[url] = progress;
            if (onProgress != null) {
              onProgress(progress);
            }
          }
        },
      );

      downloadProgress.remove(url);
      ref.read(downloadSyncProvider.notifier).increment();
      return path;
    } catch (e) {
      downloadProgress.remove(url);
      if (path != null) {
        try {
          final partial = File(path);
          if (await partial.exists()) {
            await partial.delete();
          }
        } catch (_) {}
      }
      return null;
    }
  }

  Future<void> removeFile(String url) async {
    try {
      final path = await getLocalFilePath(url);
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        ref.read(downloadSyncProvider.notifier).increment();
      }
    } catch (e) {
      // Ignore errors on deletion
    }
  }

  bool _isAudioFile(FileSystemEntity entity) {
    if (entity is! File) return false;
    final lower = entity.path.toLowerCase();
    return lower.endsWith('.mp3') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.flac') ||
        lower.endsWith('.mp4') ||
        lower.contains('sandya_vandan');
  }

  Future<int> getDownloadedAudioSize() async {
    int totalSize = 0;
    try {
      final dir = await getApplicationDocumentsDirectory();
      if (await dir.exists()) {
        final entities = dir.listSync();
        for (final entity in entities) {
          if (_isAudioFile(entity)) {
            try {
              totalSize += (entity as File).lengthSync();
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
    return totalSize;
  }

  Future<int> getDownloadedAudioCount() async {
    int count = 0;
    try {
      final dir = await getApplicationDocumentsDirectory();
      if (await dir.exists()) {
        final entities = dir.listSync();
        for (final entity in entities) {
          if (_isAudioFile(entity)) {
            count++;
          }
        }
      }
    } catch (_) {}
    return count;
  }

  Future<void> clearAllDownloadedAudio() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      if (await dir.exists()) {
        final entities = dir.listSync();
        for (final entity in entities) {
          if (_isAudioFile(entity)) {
            try {
              (entity as File).deleteSync();
            } catch (_) {}
          }
        }
      }
      ref.read(downloadSyncProvider.notifier).increment();
    } catch (_) {}
  }

  Future<int> getTempCacheSize() async {
    try {
      final dir = await getTemporaryDirectory();
      int totalSize = 0;
      if (await dir.exists()) {
        final files = dir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }
      return totalSize;
    } catch (_) {
      return 0;
    }
  }

  Future<void> clearTempCache() async {
    try {
      final dir = await getTemporaryDirectory();
      if (await dir.exists()) {
        final files = dir.listSync();
        for (final file in files) {
          try {
            await file.delete(recursive: true);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}
