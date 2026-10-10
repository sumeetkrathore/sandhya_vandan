import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/download_service.dart';
import '../theme/app_theme.dart';

class DownloadButton extends ConsumerStatefulWidget {
  final String url;
  final Color iconColor;
  final bool hideIfDownloaded;
  final bool showOnlyIfDownloaded;
  final bool confirmBeforeDownload;
  final bool showText;

  const DownloadButton({
    super.key,
    required this.url,
    this.iconColor = AppTheme.primaryIvory,
    this.hideIfDownloaded = false,
    this.showOnlyIfDownloaded = false,
    this.confirmBeforeDownload = false,
    this.showText = false,
  });

  @override
  ConsumerState<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends ConsumerState<DownloadButton> {
  bool _isDownloaded = false;
  bool _isDownloading = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  @override
  void didUpdateWidget(DownloadButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _checkStatus();
    }
  }

  Future<void> _checkStatus() async {
    final service = ref.read(downloadServiceProvider);

    // Check if it's currently downloading
    if (service.downloadProgress.containsKey(widget.url)) {
      if (mounted) {
        setState(() {
          _isDownloading = true;
          _progress = service.downloadProgress[widget.url] ?? 0.0;
        });
      }
      return;
    }

    // Check if already downloaded
    final isDownloaded = await service.isFileDownloaded(widget.url);
    if (mounted) {
      setState(() {
        _isDownloaded = isDownloaded;
        _isDownloading = false;
      });
    }
  }

  void _startDownload() async {
    if (_isDownloaded || _isDownloading) return;

    if (widget.confirmBeforeDownload) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Download Audio?'),
          content: const Text(
            'Would you like to download this audio for offline listening?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Download'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    if (!mounted) return;

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
    });

    final service = ref.read(downloadServiceProvider);
    await service.downloadFile(
      widget.url,
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _progress = progress;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isDownloading = false;
        _isDownloaded = true;
      });
    }
  }

  void _removeDownload() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Download?'),
        content: const Text(
          'This will delete the audio from your device. You can always download it again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade400),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final service = ref.read(downloadServiceProvider);
    await service.removeFile(widget.url);

    if (mounted) {
      setState(() {
        _isDownloaded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for changes from other download buttons (e.g., player vs hub)
    ref.listen(downloadSyncProvider, (previous, next) {
      _checkStatus();
    });

    Widget child;

    if (_isDownloaded) {
      if (widget.hideIfDownloaded) {
        child = const SizedBox.shrink(key: ValueKey('hidden'));
      } else if (widget.showText) {
        child = GestureDetector(
          key: const ValueKey('downloaded_text'),
          onTap: _removeDownload,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade400.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.green.shade400.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade400,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Downloaded',
                  style: TextStyle(
                    color: Colors.green.shade400,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        child = IconButton(
          key: const ValueKey('downloaded_icon'),
          icon: Icon(
            Icons.check_circle_rounded,
            color: Colors.green.shade400,
            size: 24,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: _removeDownload,
        );
      }
    } else if (_isDownloading) {
      final progressWidget = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          value: _progress,
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(widget.iconColor),
          backgroundColor: widget.iconColor.withValues(alpha: 0.2),
        ),
      );

      if (widget.showText) {
        child = Container(
          key: const ValueKey('downloading_text'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.iconColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              progressWidget,
              const SizedBox(width: 8),
              Text('Downloading...', style: TextStyle(color: widget.iconColor)),
            ],
          ),
        );
      } else {
        child = KeyedSubtree(
          key: const ValueKey('downloading_icon'),
          child: progressWidget,
        );
      }
    } else {
      if (widget.showOnlyIfDownloaded) {
        child = const SizedBox.shrink(key: ValueKey('hidden_not_downloaded'));
      } else {
        final icon = Icon(
          Icons.download_rounded,
          color: widget.iconColor,
          size: 20,
        );

        if (widget.showText) {
          child = TextButton.icon(
            key: const ValueKey('not_downloaded_text'),
            icon: icon,
            label: Text(
              'Download Offline',
              style: TextStyle(color: widget.iconColor),
            ),
            onPressed: _startDownload,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: widget.iconColor.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: widget.iconColor.withValues(alpha: 0.3),
                ),
              ),
            ),
          );
        } else {
          child = IconButton(
            key: const ValueKey('not_downloaded_icon'),
            icon: Icon(
              Icons.download_rounded,
              color: widget.iconColor,
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _startDownload,
          );
        }
      }
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        );
      },
      child: child,
    );
  }
}
