import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/sandesh.dart';
import '../theme/app_theme.dart';

class SandeshShareDialog {
  /// Direct 1-Tap Instant Share: Captures the master-crafted quote card offscreen & opens native OS share sheet directly
  static Future<void> show(BuildContext context, Sandesh sandesh) {
    return shareDirectly(context, sandesh);
  }

  static Future<void> shareDirectly(BuildContext context, Sandesh sandesh) async {
    final overlayState = Overlay.of(context);
    final cardKey = GlobalKey();

    final dateStr = DateFormat('MMMM d, yyyy').format(sandesh.date);
    final bool hasImage =
        sandesh.imageUrl != null && sandesh.imageUrl!.isNotEmpty;

    // Show floating progress SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Preparing Sandesh image...'),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: -2000,
          top: -2000,
          child: Material(
            type: MaterialType.transparency,
            child: RepaintBoundary(
              key: cardKey,
              child: build1x1CardCanvas(sandesh, hasImage, dateStr),
            ),
          ),
        );
      },
    );

    overlayState.insert(overlayEntry);

    try {
      // Allow widget tree rasterization & image pre-cache
      await Future.delayed(const Duration(milliseconds: 250));

      final boundary =
          cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Render boundary not found');
      }

      // 2. Memory-safe high-res capture (2.0x pixel ratio prevents Android OOM crashes)
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to generate image bytes');
      }
      final pngBytes = byteData.buffer.asUint8List();

      // 3. Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final String fileName =
          'sandesh_1x1_${sandesh.id}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      // 4. Share image via native share sheet
      final String formattedDate = DateFormat('MMM dd, yyyy').format(sandesh.date);
      final String shareText =
          'Daily Sandesh | $formattedDate\nShared from Sandhya Vandan App';

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: shareText,
          subject: sandesh.title.isNotEmpty ? sandesh.title : 'Daily Sandesh',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share image: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      overlayEntry.remove();
    }
  }

  /// Builds a master-crafted quote picture canvas
  /// Contains a pristine inner quote box and a clean 'Shared from Sandhya Vandan' footer outside the box
  /// Exported at high-res pixel ratio for WhatsApp/Instagram sharing
  static Widget build1x1CardCanvas(Sandesh sandesh, bool hasImage, String dateStr) {
    final String text = sandesh.content.trim();

    // Picture Canvas dimensions: 360 x 400 (or 360 x 460 with image)
    const double canvasWidth = 360;
    final double canvasHeight = hasImage ? 460 : 400;

    // Master font scaling for optimal typography hierarchy
    final double dynamicFontSize = hasImage
        ? (text.length > 200 ? 13.5 : (text.length > 100 ? 14.5 : 15.5))
        : (text.length < 90
            ? 20.0
            : (text.length < 160
                ? 18.0
                : (text.length < 260 ? 16.0 : 14.5)));

    final String formattedDate =
        DateFormat('MMM dd, yyyy').format(sandesh.date);

    return Container(
      width: canvasWidth,
      height: canvasHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2), // Elegant Warm Ivory Canvas
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.secondarySaffron.withValues(alpha: 0.20),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. INNER QUOTE CARD BOX
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, // Pure White Card Box
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.secondarySaffron.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Centered JAI SAMADHA Badge at Top Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondarySaffron.withValues(alpha: 0.10),
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
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Banner Image (if present)
                  if (hasImage) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 135,
                        child: CachedNetworkImage(
                          imageUrl: sandesh.imageUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth: 800,
                          memCacheHeight: 400,
                          placeholder: (context, url) =>
                              Container(color: const Color(0xFFEFE8DE)),
                          errorWidget: (context, url, error) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Top-Center Serif Opening Double Quotation Mark ('“') in Saffron Orange
                  const Center(
                    child: Text(
                      '“',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.serifFontFamily,
                        fontSize: 52.0,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondarySaffron,
                        height: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Quote Content (Lifted up: top-aligned below quote mark)
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Sandesh Body Text
                            Text(
                              text,
                              maxLines: hasImage ? 5 : 8,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTheme.serifFontFamily,
                                fontSize: dynamicFontSize,
                                height: 1.55,
                                letterSpacing: 0.25,
                                color: const Color(0xFF2C1E16),
                              ),
                            ),

                            // Sandesh Heading / Title (Shown BELOW Sandesh text in Fedra Sans Pro font)
                            if (sandesh.title.trim().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                sandesh.title.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: AppTheme.currentFontFamily,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  letterSpacing: 0.4,
                                  color: AppTheme.secondarySaffron,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Simple Clean Date Text (No container box)
                  Center(
                    child: Text(
                      formattedDate,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: AppTheme.currentFontFamily,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: AppTheme.secondarySaffron,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 2. FOOTER BRANDING (Outside inner quote box, inside captured picture canvas)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.auto_awesome,
                      color: AppTheme.secondarySaffron,
                      size: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Shared from Sandhya Vandan',
                style: TextStyle(
                  fontFamily: AppTheme.serifFontFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A0F16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
