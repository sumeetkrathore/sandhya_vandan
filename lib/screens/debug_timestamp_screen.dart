import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../providers/audio_provider.dart';

class DebugTimestampScreen extends ConsumerStatefulWidget {
  const DebugTimestampScreen({super.key});

  @override
  ConsumerState<DebugTimestampScreen> createState() =>
      _DebugTimestampScreenState();
}

class _DebugTimestampScreenState extends ConsumerState<DebugTimestampScreen> {
  final Map<String, Duration?> _startTimes = {};
  final Map<String, Duration?> _endTimes = {};

  final List<String> _sections = [
    'Mangla Charan',
    'Ustati',
    'Amrit Vani',
    'Aarti Sahib - Satguru Baba Roop Bhajan Sahib',
    'Aarti Sahib - Satguru Baba Shiv Bhajan Sahib',
    'Aarti - Om Jai Jagdish Hare',
    'Dhyan / Shanti Simran',
    'Prarthana',
  ];

  String _formatDuration(Duration? d) {
    if (d == null) return '--:--.---';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String threeDigits(int n) => n.toString().padLeft(3, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    final milliseconds = threeDigits(d.inMilliseconds.remainder(1000));
    return '$minutes:$seconds.$milliseconds';
  }

  String _generateReport() {
    final buffer = StringBuffer();
    for (var sec in _sections) {
      buffer.writeln('$sec:');
      buffer.writeln('start ${_formatDuration(_startTimes[sec])}');
      buffer.writeln('end ${_formatDuration(_endTimes[sec])}');
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioProvider);
    final audioNotifier = ref.read(audioProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DEBUG Timestamp Mapper'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _generateReport()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report copied to clipboard!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Current Position Display
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                const Text(
                  'Current Master Position',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDuration(audioState.position),
                  style: const TextStyle(fontSize: 32, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10),
                      onPressed: () => audioNotifier.skipBackward(), // -10s
                    ),
                    IconButton(
                      icon: const Icon(Icons.exposure_minus_1),
                      onPressed: () => audioNotifier.seek(
                        audioState.position - const Duration(seconds: 1),
                      ),
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
                      icon: const Icon(Icons.exposure_plus_1),
                      onPressed: () => audioNotifier.seek(
                        audioState.position + const Duration(seconds: 1),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_10),
                      onPressed: () => audioNotifier.skipForward(), // +10s
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Marker Buttons
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sections.length,
              itemBuilder: (context, index) {
                final sec = _sections[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sec,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _startTimes[sec] = audioState.position;
                                  });
                                },
                                child: const Text('MARK START'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _endTimes[sec] = audioState.position;
                                  });
                                },
                                child: const Text('MARK END'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Start: ${_formatDuration(_startTimes[sec])}'),
                            Text('End: ${_formatDuration(_endTimes[sec])}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
