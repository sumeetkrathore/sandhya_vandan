import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class SandyaVandanAudioHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();
  final _completionController = StreamController<void>.broadcast();
  Stream<void> get completionStream => _completionController.stream;

  SandyaVandanAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _player.playbackEventStream.listen((event) {
      _broadcastState(event);
    });

    _player.playingStream.listen((playing) {
      // Re-broadcast the latest playback event to update the playing state in the notification
      _broadcastState(_player.playbackEvent);
    });

    _player.durationStream.listen((duration) {
      if (mediaItem.value != null && duration != null) {
        mediaItem.add(mediaItem.value!.copyWith(duration: duration));
      }
    });

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _player.pause();
        _player.seek(Duration.zero);
        _completionController.add(null);
      }
    });
  }

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.rewind,
          if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.fastForward,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState:
            const {
              ProcessingState.idle: AudioProcessingState.idle,
              ProcessingState.loading: AudioProcessingState.loading,
              ProcessingState.buffering: AudioProcessingState.buffering,
              ProcessingState.ready: AudioProcessingState.ready,
              ProcessingState.completed: AudioProcessingState.completed,
            }[_player.processingState] ??
            AudioProcessingState.idle,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ),
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> fastForward() async {
    final newPos = _player.position + const Duration(seconds: 10);
    await seek(
      newPos > (_player.duration ?? Duration.zero)
          ? (_player.duration ?? Duration.zero)
          : newPos,
    );
  }

  @override
  Future<void> rewind() async {
    final newPos = _player.position - const Duration(seconds: 10);
    await seek(newPos < Duration.zero ? Duration.zero : newPos);
  }

  String? _currentSourceId;

  @override
  Future<void> stop() async {
    _currentSourceId = null;
    await _player.stop();
    return super.stop();
  }

  static final Uri _defaultArtUri = Uri.parse('asset:///assets/images/app_icon.png');

  Uri _parseArtUri(String? artUri) {
    if (artUri != null && artUri.trim().isNotEmpty) {
      final trimmed = artUri.trim();
      if (trimmed.startsWith('http://') ||
          trimmed.startsWith('https://') ||
          trimmed.startsWith('asset://') ||
          trimmed.startsWith('file://')) {
        final parsed = Uri.tryParse(trimmed);
        if (parsed != null) return parsed;
      } else if (trimmed.startsWith('assets/')) {
        final parsed = Uri.tryParse('asset:///$trimmed');
        if (parsed != null) return parsed;
      }
    }
    return _defaultArtUri;
  }

  Future<void> loadAsset(
    String assetPath, {
    Duration? initialPosition,
    Duration? start,
    Duration? end,
    String? title,
    String? artist,
    String? artUri,
    bool isLocalFile = false,
  }) async {
    final parsedArtUri = _parseArtUri(artUri);

    mediaItem.add(
      MediaItem(
        id: assetPath,
        album: isLocalFile ? 'Sandhya Vandan (Offline)' : 'Sandhya Vandan',
        title: title ?? 'Sandhya Vandan Nem',
        artist: artist ?? 'Pooj Samadha Ashram, Shikarpur',
        artUri: parsedArtUri,
      ),
    );

    // If switching to a new audio file or previously playing something else, reload
    if (_player.audioSource == null || _currentSourceId != assetPath) {
      if (_player.playing) {
        await _player.pause();
      }

      _currentSourceId = assetPath;
      if (isLocalFile) {
        await _player.setFilePath(
          assetPath,
          initialPosition: initialPosition ?? Duration.zero,
        );
      } else {
        await _player.setAsset(
          assetPath,
          initialPosition: initialPosition ?? Duration.zero,
        );
      }
    } else if (initialPosition != null) {
      await _player.seek(initialPosition);
    }

    if (start != null || end != null) {
      await _player.setClip(start: start, end: end);
    }
  }

  void updateTitle(String title) {
    if (mediaItem.value != null && mediaItem.value!.title != title) {
      mediaItem.add(mediaItem.value!.copyWith(title: title));
    }
  }

  Future<void> loadUrl(
    String url, {
    Duration? initialPosition,
    String? title,
    String? artist,
    String? artUri,
    Map<String, String>? headers,
  }) async {
    final parsedArtUri = _parseArtUri(artUri);

    final isSandhya = url.contains('sandya_vandan');

    mediaItem.add(
      MediaItem(
        id: url,
        album: isSandhya ? 'Sandhya Vandan' : 'Audio Hub',
        title: title ?? (isSandhya ? 'Sandhya Vandan Nem' : 'Audio Track'),
        artist: artist ?? 'Pooj Samadha Ashram',
        artUri: parsedArtUri,
      ),
    );

    if (_player.audioSource == null || _currentSourceId != url) {
      if (_player.playing) {
        await _player.pause();
      }

      _currentSourceId = url;
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(url), headers: headers),
        initialPosition: initialPosition ?? Duration.zero,
      );
    } else if (initialPosition != null) {
      await _player.seek(initialPosition);
    }
  }

  Stream<bool> get playingStream => _player.playingStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<double> get speedStream => _player.speedStream;
}
