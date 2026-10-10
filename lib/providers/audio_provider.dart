import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/audio_timeline.dart';
import '../models/audio_section.dart';
import '../models/audio_item.dart';
import '../repositories/audio_repository.dart';
import '../main.dart';
import '../services/audio_handler.dart';
import '../services/download_service.dart';

enum AudioRepeatMode {
  off, // Plays playlist and stops
  all, // Loops playlist continuously
  one, // Loops current track continuously (ideal for chants/japa)
}

class AudioState {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double speed;
  final bool isLoaded;
  final bool isLoading;
  final AudioTimeline? timeline;
  final String activeAudioSectionId;
  final String? activeAudioUrl;
  final AudioItem? currentAudioItem;
  final List<AudioItem> playlist;
  final AudioRepeatMode repeatMode;
  final String? title;
  final String? artist;
  final String? coverImage;
  final Duration? sleepTimerRemaining;
  final bool sleepTimerEndOfTrack;

  AudioState({
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
    this.isLoaded = false,
    this.isLoading = false,
    this.timeline,
    this.activeAudioSectionId = 'full',
    this.activeAudioUrl,
    this.currentAudioItem,
    this.playlist = const [],
    this.repeatMode = AudioRepeatMode.all,
    this.title,
    this.artist,
    this.coverImage,
    this.sleepTimerRemaining,
    this.sleepTimerEndOfTrack = false,
  });

  AudioState copyWith({
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? speed,
    bool? isLoaded,
    bool? isLoading,
    AudioTimeline? timeline,
    String? activeAudioSectionId,
    String? activeAudioUrl,
    AudioItem? currentAudioItem,
    List<AudioItem>? playlist,
    AudioRepeatMode? repeatMode,
    String? title,
    String? artist,
    String? coverImage,
    Duration? sleepTimerRemaining,
    bool? sleepTimerEndOfTrack,
    bool clearSleepTimer = false,
    bool clearCurrentItem = false,
  }) {
    return AudioState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      isLoaded: isLoaded ?? this.isLoaded,
      isLoading: isLoading ?? this.isLoading,
      timeline: timeline ?? this.timeline,
      activeAudioSectionId: activeAudioSectionId ?? this.activeAudioSectionId,
      activeAudioUrl: activeAudioUrl ?? this.activeAudioUrl,
      currentAudioItem: clearCurrentItem
          ? null
          : (currentAudioItem ?? this.currentAudioItem),
      playlist: clearCurrentItem ? const [] : (playlist ?? this.playlist),
      repeatMode: repeatMode ?? this.repeatMode,
      title: clearCurrentItem ? null : (title ?? this.title),
      artist: clearCurrentItem ? null : (artist ?? this.artist),
      coverImage: clearCurrentItem ? null : (coverImage ?? this.coverImage),
      sleepTimerRemaining: clearSleepTimer
          ? null
          : (sleepTimerRemaining ?? this.sleepTimerRemaining),
      sleepTimerEndOfTrack: clearSleepTimer
          ? false
          : (sleepTimerEndOfTrack ?? this.sleepTimerEndOfTrack),
    );
  }
}

class AudioProviderNotifier extends Notifier<AudioState> {
  late final SandyaVandanAudioHandler _handler;
  StreamSubscription? _playingSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _speedSub;
  StreamSubscription? _completionSub;
  Timer? _sleepTimer;

  @override
  AudioState build() {
    _handler = audioHandler as SandyaVandanAudioHandler;

    _playingSub = _handler.playingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });

    _positionSub = _handler.positionStream.listen((position) {
      state = state.copyWith(position: position);

      // ONLY update section title if genuinely playing Sandhya Vandan Nem
      // and NOT playing an individual bhajan!
      if (state.currentAudioItem == null &&
          !state.activeAudioSectionId.startsWith('item_')) {
        if (state.activeAudioSectionId == 'full') {
          if (position.inSeconds > 0) {
            final matchingSections = audioSections
                .where(
                  (s) =>
                      s.id != 'full' &&
                      s.startTimestamp != null &&
                      position >= s.startTimestamp!,
                )
                .toList();

            if (matchingSections.isNotEmpty) {
              final activeSection = matchingSections.last;
              _handler.updateTitle(
                'Sandhya Vandan: ${activeSection.displayTitle}',
              );
            } else {
              _handler.updateTitle('Sandhya Vandan Nem');
            }
          } else {
            _handler.updateTitle('Sandhya Vandan Nem');
          }
        } else {
          final currentSection = audioSections.firstWhere(
            (s) => s.id == state.activeAudioSectionId,
            orElse: () => audioSections.first,
          );
          _handler.updateTitle(currentSection.displayTitle);
        }
      }
    });

    _durationSub = _handler.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });

    _speedSub = _handler.speedStream.listen((speed) {
      state = state.copyWith(speed: speed);
    });

    // Auto-advance or repeat track when playback completes
    _completionSub = _handler.completionStream.listen((_) {
      if (state.sleepTimerEndOfTrack) {
        pause();
        setSleepTimer(null);
        return;
      }
      if (state.currentAudioItem != null) {
        if (state.repeatMode == AudioRepeatMode.one) {
          seek(Duration.zero);
          play();
        } else if (hasNextTrack || state.repeatMode == AudioRepeatMode.all) {
          playNextTrack(userInitiated: false);
        }
      }
    });

    ref.onDispose(() {
      _sleepTimer?.cancel();
      _playingSub?.cancel();
      _positionSub?.cancel();
      _durationSub?.cancel();
      _speedSub?.cancel();
      _completionSub?.cancel();
    });

    return AudioState(
      isLoaded: false,
      isPlaying: false,
      position: Duration.zero,
      duration: Duration.zero,
      speed: 1.0,
      timeline: null,
      activeAudioSectionId: 'full',
      playlist: const [],
    );
  }

  Future<void> _loadTimeline() async {
    if (state.timeline != null) return;
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/audio_timeline.json',
      );
      final timeline = AudioTimeline.fromJson(jsonDecode(jsonString));
      state = state.copyWith(timeline: timeline);
    } catch (e) {
      //print("Error loading audio timeline: $e");
    }
  }

  final String mainSandhyaVandanUrl =
      'https://audio.jaisamadha.com/sandya_vandan_master.m4a';

  String? get currentAudioUrl => state.activeAudioUrl;

  Future<void> prepareAudio({bool force = false}) async {
    if (!force &&
        (state.isLoaded ||
            state.currentAudioItem != null ||
            state.isPlaying ||
            state.isLoading)) {
      return;
    }
    await _loadTimeline();

    if (state.timeline != null) {
      try {
        final downloadService = ref.read(downloadServiceProvider);

        if (await downloadService.isFileDownloaded(mainSandhyaVandanUrl)) {
          final localPath = await downloadService.getLocalFilePath(
            mainSandhyaVandanUrl,
          );
          await _handler.loadAsset(
            localPath,
            title: 'Sandhya Vandan Nem',
            artist: 'Sandhya Vandan',
            artUri: 'assets/images/app_icon.png',
            isLocalFile: true,
          );
        } else {
          // Stream from Cloudflare R2
          await _handler.loadUrl(
            mainSandhyaVandanUrl,
            title: 'Sandhya Vandan Nem',
            artist: 'Sandhya Vandan',
            artUri: 'assets/images/app_icon.png',
          );
        }

        state = state.copyWith(
          isLoaded: true,
          isLoading: false,
          activeAudioSectionId: 'full',
          activeAudioUrl: mainSandhyaVandanUrl,
          clearCurrentItem: true,
          title: 'Sandhya Vandan Nem',
          artist: 'Sandhya Vandan',
        );
      } catch (e, st) {
        log('Error loading Sandhya Vandan audio asset: $e\n$st');
      }
    }
  }

  /// Explicit, atomic trigger to load and play Sandhya Vandan Nem
  Future<void> playSandhyaVandan({
    String sectionId = 'full',
    bool? autoPlay,
  }) async {
    final bool shouldAutoPlay = autoPlay ?? true;

    // 1. Immediately pause any currently playing track to avoid overlap
    if (state.isPlaying) {
      await _handler.pause();
    }

    // 2. Set loading state & clear any previous bhajan item/playlist
    state = state.copyWith(
      isLoading: true,
      isLoaded: false,
      activeAudioSectionId: sectionId,
      activeAudioUrl: mainSandhyaVandanUrl,
      clearCurrentItem: true,
      title: 'Sandhya Vandan Nem',
      artist: 'Sandhya Vandan',
    );

    await _loadTimeline();

    try {
      final downloadService = ref.read(downloadServiceProvider);
      AudioSection? section;
      if (sectionId != 'full') {
        section = audioSections.firstWhere(
          (s) => s.id == sectionId,
          orElse: () => audioSections.first,
        );
      }

      final targetPosition = section?.startTimestamp ?? Duration.zero;
      final displayTitle = section != null
          ? section.displayTitle
          : 'Sandhya Vandan Nem';

      if (await downloadService.isFileDownloaded(mainSandhyaVandanUrl)) {
        final localPath = await downloadService.getLocalFilePath(
          mainSandhyaVandanUrl,
        );
        await _handler.loadAsset(
          localPath,
          initialPosition: targetPosition,
          title: displayTitle,
          artist: 'Sandhya Vandan',
          artUri: 'assets/images/app_icon.png',
          isLocalFile: true,
        );
      } else {
        await _handler.loadUrl(
          mainSandhyaVandanUrl,
          initialPosition: targetPosition,
          title: displayTitle,
          artist: 'Sandhya Vandan',
          artUri: 'assets/images/app_icon.png',
        );
      }

      await _handler.seek(targetPosition);

      state = state.copyWith(
        isLoaded: true,
        isLoading: false,
        activeAudioSectionId: sectionId,
        activeAudioUrl: mainSandhyaVandanUrl,
        clearCurrentItem: true,
        title: displayTitle,
        artist: 'Sandhya Vandan',
      );

      if (shouldAutoPlay) {
        await _handler.play();
      } else {
        await _handler.pause();
      }
    } catch (e, st) {
      log('Error playing Sandhya Vandan: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        isLoaded: false,
        isPlaying: false,
        clearCurrentItem: true,
      );
    }
  }

  Future<void> playSection(AudioSection section, {bool? autoPlay}) async {
    await playSandhyaVandan(sectionId: section.id, autoPlay: autoPlay);
  }

  int get currentTrackIndex {
    if (state.currentAudioItem == null || state.playlist.isEmpty) return -1;
    return state.playlist.indexWhere(
      (it) => it.id == state.currentAudioItem!.id,
    );
  }

  bool get hasNextTrack {
    final idx = currentTrackIndex;
    if (idx == -1) return false;
    return idx < state.playlist.length - 1 ||
        state.repeatMode == AudioRepeatMode.all;
  }

  bool get hasPreviousTrack {
    return state.position.inSeconds > 3 ||
        currentTrackIndex > 0 ||
        state.repeatMode == AudioRepeatMode.all;
  }

  void toggleRepeatMode() {
    final next = switch (state.repeatMode) {
      AudioRepeatMode.off => AudioRepeatMode.all,
      AudioRepeatMode.all => AudioRepeatMode.one,
      AudioRepeatMode.one => AudioRepeatMode.off,
    };
    state = state.copyWith(repeatMode: next);
  }

  void setRepeatMode(AudioRepeatMode mode) {
    state = state.copyWith(repeatMode: mode);
  }

  void setSleepTimer(Duration? duration, {bool endOfTrack = false}) {
    _sleepTimer?.cancel();
    _sleepTimer = null;

    if (duration == null && !endOfTrack) {
      state = state.copyWith(
        sleepTimerRemaining: null,
        sleepTimerEndOfTrack: false,
        clearSleepTimer: true,
      );
      return;
    }

    if (endOfTrack) {
      state = state.copyWith(
        sleepTimerRemaining: null,
        sleepTimerEndOfTrack: true,
      );
      return;
    }

    state = state.copyWith(
      sleepTimerRemaining: duration,
      sleepTimerEndOfTrack: false,
    );

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = state.sleepTimerRemaining;
      if (current == null || current.inSeconds <= 1) {
        timer.cancel();
        _sleepTimer = null;
        pause();
        state = state.copyWith(
          sleepTimerRemaining: null,
          sleepTimerEndOfTrack: false,
          clearSleepTimer: true,
        );
      } else {
        state = state.copyWith(
          sleepTimerRemaining: current - const Duration(seconds: 1),
        );
      }
    });
  }

  Future<void> playNextTrack({bool userInitiated = true}) async {
    final idx = currentTrackIndex;
    if (idx != -1 && idx < state.playlist.length - 1) {
      await playAudioItem(state.playlist[idx + 1], playlist: state.playlist);
    } else if (state.playlist.isNotEmpty &&
        state.repeatMode == AudioRepeatMode.all) {
      await playAudioItem(state.playlist.first, playlist: state.playlist);
    } else if (!userInitiated) {
      await pause();
      await seek(Duration.zero);
    }
  }

  Future<void> playPreviousTrack() async {
    // Standard practice (Spotify, Apple Music, Isha Foundation):
    // If audio has played for > 3 seconds, restart current track from beginning
    if (state.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    final idx = currentTrackIndex;
    if (idx > 0) {
      await playAudioItem(state.playlist[idx - 1], playlist: state.playlist);
    } else if (state.playlist.isNotEmpty &&
        state.repeatMode == AudioRepeatMode.all) {
      await playAudioItem(state.playlist.last, playlist: state.playlist);
    } else {
      await seek(Duration.zero);
    }
  }

  void setPlaylist(List<AudioItem> list) {
    final directList = list
        .where(
          (item) =>
              !item.audioUrl.contains('youtu') && item.audioUrl.isNotEmpty,
        )
        .toList();
    state = state.copyWith(playlist: directList);
  }

  Future<void> playAudioItem(
    AudioItem item, {
    List<AudioItem>? playlist,
  }) async {
    if (item.audioUrl.isEmpty || item.audioUrl.contains('youtu')) return;

    List<AudioItem> activePlaylist = (playlist ?? state.playlist)
        .where((t) => !t.audioUrl.contains('youtu') && t.audioUrl.isNotEmpty)
        .toList();
    if (activePlaylist.isEmpty) {
      try {
        final allTracks = await ref.read(allAudioTracksProvider.future);
        if (allTracks.isNotEmpty) {
          activePlaylist = allTracks
              .where(
                (t) => !t.audioUrl.contains('youtu') && t.audioUrl.isNotEmpty,
              )
              .toList();
        }
      } catch (_) {}
    }

    final String finalAudioUrl = item.audioUrl;
    final String coverArt = item.coverImage;

    state = state.copyWith(
      activeAudioSectionId: 'item_${item.id}',
      isLoading: true,
      isLoaded: false,
      activeAudioUrl: item.audioUrl,
      currentAudioItem: item,
      playlist: activePlaylist,
      title: item.title,
      artist: item.artist,
      coverImage: coverArt.isNotEmpty ? coverArt : null,
    );

    try {
      final downloadService = ref.read(downloadServiceProvider);
      if (await downloadService.isFileDownloaded(item.audioUrl)) {
        final localPath = await downloadService.getLocalFilePath(item.audioUrl);
        await _handler.loadAsset(
          localPath,
          title: item.title,
          artist: item.artist,
          artUri: coverArt.isNotEmpty ? coverArt : null,
          isLocalFile: true,
        );
      } else {
        await _handler.loadUrl(
          finalAudioUrl,
          title: item.title,
          artist: item.artist,
          artUri: coverArt.isNotEmpty ? coverArt : null,
        );
      }
      state = state.copyWith(
        isLoaded: true,
        isLoading: false,
        currentAudioItem: item,
        playlist: activePlaylist,
        title: item.title,
        artist: item.artist,
        coverImage: coverArt.isNotEmpty ? coverArt : null,
      );
      await _handler.play();
    } catch (e) {
      state = state.copyWith(
        activeAudioSectionId: 'none',
        isLoading: false,
        isLoaded: false,
        isPlaying: false,
        clearCurrentItem: true,
      );
    }
  }

  Future<void> play() async {
    if (!state.isLoaded) {
      if (state.currentAudioItem != null) {
        await playAudioItem(state.currentAudioItem!);
        return;
      }
      await prepareAudio();
    }
    await _handler.play();
  }

  Future<void> pause() async {
    await _handler.pause();
  }

  Future<void> stop() async {
    await _handler.stop();
    await _handler.seek(Duration.zero);
    state = state.copyWith(
      isLoaded: false,
      isPlaying: false,
      activeAudioSectionId: 'none',
      clearCurrentItem: true,
    );
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    await _handler.seek(position);
  }

  Future<void> skipForward() async {
    await _handler.fastForward();
  }

  Future<void> skipBackward() async {
    await _handler.rewind();
  }

  Future<void> setSpeed(double speed) async {
    await _handler.setSpeed(speed);
  }
}

final audioProvider = NotifierProvider<AudioProviderNotifier, AudioState>(
  AudioProviderNotifier.new,
);
