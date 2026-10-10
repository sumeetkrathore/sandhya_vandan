import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_theme.dart';

enum TipnoShareFormat {
  story, // 9:16 (1080 x 1920) - Instagram Stories, WhatsApp Status, Facebook Stories
  post, // 4:5 (1080 x 1350) - Instagram Feed, Facebook Post, WhatsApp Chat
}

class TipnoShareDialog extends StatefulWidget {
  final String title;
  final List<Map<String, String>> events;
  final Map<String, String>? singleEvent;

  const TipnoShareDialog({
    super.key,
    required this.title,
    required this.events,
    this.singleEvent,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<Map<String, String>> events,
    Map<String, String>? singleEvent,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TipnoShareDialog(
        title: title,
        events: events,
        singleEvent: singleEvent,
      ),
    );
  }

  @override
  State<TipnoShareDialog> createState() => _TipnoShareDialogState();
}

class _TipnoShareDialogState extends State<TipnoShareDialog> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isExporting = false;
  TipnoShareFormat _selectedFormat = TipnoShareFormat.story;

  Future<void> _exportAndShare() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      // 1. Wait for render boundary to be fully drawn
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Render boundary not found');
      }

      // 2. High-res capture: scale pixelRatio so output image is standard 1080px wide
      // Story: 360 x 640 -> 1080 x 1920 (Exact 9:16 Instagram Story / WhatsApp Status)
      // Post:  360 x 450 -> 1080 x 1350 (Exact 4:5 Instagram Feed / Facebook Post)
      final double targetPixelRatio = (1080.0 / boundary.size.width).clamp(
        2.0,
        4.0,
      );
      final ui.Image image = await boundary.toImage(
        pixelRatio: targetPixelRatio,
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to generate image bytes');
      }
      final pngBytes = byteData.buffer.asUint8List();

      // 3. Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final String fileName =
          'tipno_${_selectedFormat == TipnoShareFormat.story ? "story" : "post"}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      // 4. Share image via native share sheet
      final String headerTitle = widget.title.isNotEmpty
          ? widget.title
          : 'Monthly Dharmic Tipno';

      final StringBuffer shareText = StringBuffer();
      shareText.writeln('$headerTitle • Dharmic Tipno');
      shareText.writeln();

      for (final event in widget.events) {
        final date = (event['date'] ?? '').trim();
        final name = (event['name'] ?? '').trim();
        if (date.isNotEmpty && name.isNotEmpty) {
          shareText.writeln('• $date: $name');
        } else if (name.isNotEmpty) {
          shareText.writeln('• $name');
        }
      }

      shareText.writeln();
      shareText.write('Shared via Sandhya Vandan App');

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: shareText.toString(),
          subject: '$headerTitle - Dharmic Tipno',
        ),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share image: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isStory = _selectedFormat == TipnoShareFormat.story;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.cardBorder(context), width: 1),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Dialog Title & Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Share Dharmic Tipno',
                style: TextStyle(
                  fontFamily: AppTheme.serifFontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppTheme.primaryIvory
                      : AppTheme.darkBackground,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // FORMAT SELECTOR TABS
          Row(
            children: [
              Expanded(
                child: _buildFormatTab(
                  label: 'Story / Status',
                  icon: Icons.smartphone_rounded,
                  isSelected: isStory,
                  onTap: () {
                    if (!isStory) {
                      setState(() => _selectedFormat = TipnoShareFormat.story);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFormatTab(
                  label: 'Post / Feed',
                  icon: Icons.crop_portrait_rounded,
                  isSelected: !isStory,
                  onTap: () {
                    if (isStory) {
                      setState(() => _selectedFormat = TipnoShareFormat.post);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // PREVIEW CARD (FittedBox ensures it scales cleanly in dialog without cropping)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.44,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: RepaintBoundary(
                  key: _cardKey,
                  child: _buildCardCanvas(isStory),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // SHARE BUTTON
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportAndShare,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: AppTheme.darkBackground,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.darkBackground,
                      ),
                    )
                  : const Icon(Icons.share_rounded, size: 22),
              label: Text(
                _isExporting
                    ? 'Preparing Image...'
                    : (isStory
                          ? 'Share to Stories & Status'
                          : 'Share to Posts & Feed'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryGold.withValues(alpha: 0.15)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryGold
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1)),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? AppTheme.primaryGold
                    : (isDark
                          ? AppTheme.primaryIvory
                          : AppTheme.darkBackground),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? AppTheme.primaryGold
                      : (isDark
                            ? AppTheme.primaryIvory
                            : AppTheme.darkBackground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the exact-aspect-ratio canvas that is exported to image
  /// - Story: 360 x 640 (9:16) -> Renders to 1080 x 1920 px at 3.0x pixel ratio
  /// - Post:  360 x 450 (4:5)  -> Renders to 1080 x 1350 px at 3.0x pixel ratio
  Widget _buildCardCanvas(bool isStory) {
    // Exact standard dimensions
    final double canvasWidth = 360;
    final double canvasHeight = isStory ? 640 : 450;

    // Safe padding: Story format requires top & bottom margins for status/story UI
    final EdgeInsets padding = isStory
        ? const EdgeInsets.fromLTRB(22, 42, 22, 42)
        : const EdgeInsets.fromLTRB(20, 18, 20, 18);

    return Container(
      width: canvasWidth,
      height: canvasHeight,
      decoration: BoxDecoration(
        color: Colors.white, // Pure White Canvas
        borderRadius: BorderRadius.circular(isStory ? 22 : 18),
        border: Border.all(
          color: AppTheme.secondarySaffron.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Header: Diya + Title + Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: AppTheme.secondarySaffron,
                    size: 17,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'DHARMIC TIPNO',
                    style: TextStyle(
                      fontFamily: AppTheme.currentFontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.4,
                      color: AppTheme.secondarySaffron,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.secondarySaffron.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.secondarySaffron.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: const Text(
                  'JAI SAMADHA',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondarySaffron,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isStory ? 12 : 8),

          // 2. Main Title
          Text(
            widget.title.isNotEmpty ? widget.title : 'Monthly Dharmic Tipno',
            style: TextStyle(
              fontFamily: AppTheme.serifFontFamily,
              fontWeight: FontWeight.bold,
              fontSize: isStory ? 19 : 17,
              height: 1.25,
              color: const Color(0xFF4A0F16),
            ),
          ),
          SizedBox(height: isStory ? 12 : 8),

          // 3. Events Section: Fits all events cleanly within available space
          Expanded(child: _buildEventsLayout(isStory)),

          // 4. Divider Line
          Container(
            height: 1,
            margin: EdgeInsets.symmetric(vertical: isStory ? 10 : 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.secondarySaffron.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // 5. Footer Row: Type Left, App Branding Right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dharmic Tipno',
                style: TextStyle(
                  fontFamily: AppTheme.currentFontFamily,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: AppTheme.secondarySaffron,
                ),
              ),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 15,
                      height: 15,
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.auto_awesome,
                          color: AppTheme.secondarySaffron,
                          size: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Sandhya Vandan',
                    style: TextStyle(
                      fontFamily: AppTheme.serifFontFamily,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A0F16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds events layout optimized for the format:
  /// - In Post mode (4:5): Uses 2 columns if events > 7 so all events fit without overflow
  /// - In Story mode (9:16): Uses a balanced single column (or 2 columns if > 13)
  Widget _buildEventsLayout(bool isStory) {
    final events = widget.events;
    if (events.isEmpty) {
      return const Center(
        child: Text(
          'No events listed',
          style: TextStyle(color: Color(0xFF4A0F16)),
        ),
      );
    }

    // In Post mode (4:5), 2 columns ensure all events fit perfectly
    final bool useTwoColumns =
        (!isStory && events.length > 7) || (isStory && events.length > 13);

    if (useTwoColumns) {
      final int half = (events.length + 1) ~/ 2;
      final leftList = events.sublist(0, half);
      final rightList = events.sublist(half);

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: leftList
                  .map((e) => _buildCompactEventItem(e, isDense: true))
                  .toList(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: rightList
                  .map((e) => _buildCompactEventItem(e, isDense: true))
                  .toList(),
            ),
          ),
        ],
      );
    }

    // Single column layout
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: events
          .map((e) => _buildCompactEventItem(e, isDense: false))
          .toList(),
    );
  }

  Widget _buildCompactEventItem(
    Map<String, String> event, {
    required bool isDense,
  }) {
    final date = (event['date'] ?? '').trim();
    final name = (event['name'] ?? '').trim();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isDense ? 2.5 : 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (date.isNotEmpty) ...[
            Container(
              width: isDense ? 46 : 56,
              padding: EdgeInsets.symmetric(
                horizontal: 4,
                vertical: isDense ? 2.5 : 3.5,
              ),
              decoration: BoxDecoration(
                color: AppTheme.secondarySaffron.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                date,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  color: AppTheme.secondarySaffron,
                  fontSize: isDense ? 9.5 : 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: isDense ? 6 : 8),
          ],
          Expanded(
            child: Text(
              name,
              maxLines: isDense ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF2C1E16),
                fontSize: isDense ? 10.5 : 12.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
