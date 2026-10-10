import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/audio_provider.dart';
import '../models/audio_timeline.dart';

class TimestampCaptureScreen extends ConsumerStatefulWidget {
  const TimestampCaptureScreen({super.key});

  @override
  ConsumerState<TimestampCaptureScreen> createState() =>
      _TimestampCaptureScreenState();
}

class _TimestampCaptureScreenState
    extends ConsumerState<TimestampCaptureScreen> {
  AudioSegment? _selectedSegment;
  int? _capturedStartMs;
  int? _capturedEndMs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioProvider.notifier).prepareAudio();
    });
  }

  String _formatDetailed(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String threeDigits(int n) => n.toString().padLeft(3, "0");

    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    String milliseconds = threeDigits(duration.inMilliseconds.remainder(1000));

    return "$hours:$minutes:$seconds.$milliseconds";
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioProvider);
    final audioNotifier = ref.read(audioProvider.notifier);
    final timeline = audioState.timeline;

    return Scaffold(
      appBar: AppBar(title: const Text('DEV: Timestamp Capture')),
      body: SafeArea(
        child: timeline == null
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Current Position',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDetailed(audioState.position),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      '${audioState.position.inMilliseconds} ms',
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.replay_10),
                          onPressed: () => audioNotifier.skipBackward(),
                        ),
                        IconButton(
                          iconSize: 48,
                          icon: Icon(
                            audioState.isPlaying
                                ? Icons.pause_circle
                                : Icons.play_circle,
                          ),
                          onPressed: () => audioNotifier.togglePlayPause(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.forward_10),
                          onPressed: () => audioNotifier.skipForward(),
                        ),
                      ],
                    ),

                    Slider(
                      min: 0.0,
                      max: audioState.duration.inMilliseconds.toDouble() > 0
                          ? audioState.duration.inMilliseconds.toDouble()
                          : 1.0,
                      value: audioState.position.inMilliseconds
                          .toDouble()
                          .clamp(
                            0.0,
                            audioState.duration.inMilliseconds.toDouble() > 0
                                ? audioState.duration.inMilliseconds.toDouble()
                                : 1.0,
                          ),
                      onChanged: (value) {
                        audioNotifier.seek(
                          Duration(milliseconds: value.toInt()),
                        );
                      },
                    ),

                    const Divider(height: 48),

                    Text(
                      'Select Segment',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<AudioSegment>(
                      isExpanded: true,
                      value: _selectedSegment,
                      hint: const Text('Select segment to map'),
                      items: timeline.segments.map((s) {
                        return DropdownMenuItem(value: s, child: Text(s.title));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedSegment = val;
                          _capturedStartMs = val?.audioStartMs;
                          _capturedEndMs = val?.audioEndMs;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _selectedSegment == null
                                ? null
                                : () {
                                    setState(() {
                                      _capturedStartMs =
                                          audioState.position.inMilliseconds;
                                    });
                                  },
                            child: const Text('Mark Start'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _selectedSegment == null
                                ? null
                                : () {
                                    setState(() {
                                      _capturedEndMs =
                                          audioState.position.inMilliseconds;
                                    });
                                  },
                            child: const Text('Mark End'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    if (_selectedSegment != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.grey.withValues(alpha: 0.1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'JSON Snippet for ${_selectedSegment!.id}:',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              '"audioStartMs": ${_capturedStartMs ?? "null"},\n"audioEndMs": ${_capturedEndMs ?? "null"}',
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
