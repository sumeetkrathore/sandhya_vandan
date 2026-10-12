import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../widgets/sandesh_share_dialog.dart';

import '../models/sandesh.dart';
import '../services/sandesh_service.dart';
import '../theme/app_theme.dart';

class SandeshDetailScreen extends StatefulWidget {
  final Sandesh sandesh;

  const SandeshDetailScreen({super.key, required this.sandesh});

  @override
  State<SandeshDetailScreen> createState() => _SandeshDetailScreenState();
}

class _SandeshDetailScreenState extends State<SandeshDetailScreen> {
  late Sandesh _currentSandesh;
  bool _isLoadingFullContent = false;

  @override
  void initState() {
    super.initState();
    _currentSandesh = widget.sandesh;
    // Set initial loading state safely without calling setState in initState
    _isLoadingFullContent = _currentSandesh.content.length < 200;

    // If opened from a notification or partial payload, fetch the full article in background
    if (_currentSandesh.id > 0) {
      _loadFullSandesh();
    }
  }

  Future<void> _loadFullSandesh() async {
    try {
      final fresh = await SandeshService().fetchSandeshById(_currentSandesh.id);
      if (fresh != null && mounted) {
        setState(() {
          _currentSandesh = fresh;
          _isLoadingFullContent = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoadingFullContent = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingFullContent = false;
        });
      }
    }
  }

  void _shareSandesh() {
    SandeshShareDialog.show(context, _currentSandesh);
  }

  void _openFullscreenImage(BuildContext context, String url) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.black.withValues(alpha: 0.92),
            body: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                      memCacheWidth: 1080,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE5D5C5),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.broken_image,
                        color: Colors.white70,
                        size: 48,
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 30,
                        ),
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark
        ? AppTheme.darkBackground
        : AppTheme.backgroundIvory;
    final appBarBg = isDark ? AppTheme.elevatedBurgundy : AppTheme.deepBurgundy;
    final darkBrown = AppTheme.cardTextColor(context);
    final cardBg = isDark
        ? Theme.of(context).colorScheme.surface
        : const Color(0xFFFAF7F2);
    final borderColor = AppTheme.cardBorder(context);

    final imageUrl = _currentSandesh.imageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Sandesh - ${DateFormat('MMM d, yyyy').format(_currentSandesh.date)}',
          style: AppTheme.appBarTitle.copyWith(
            color: AppTheme.primaryIvory,
            fontSize: 18.0,
          ),
        ),
        centerTitle: true,
        backgroundColor: appBarBg,
        foregroundColor: AppTheme.primaryIvory,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Share Sandesh',
              onPressed: _shareSandesh,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasImage)
                      GestureDetector(
                        onTap: () => _openFullscreenImage(context, imageUrl),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: 800,
                                memCacheHeight: 450,
                                placeholder: (context, url) =>
                                    Shimmer.fromColors(
                                  baseColor: isDark
                                      ? Colors.grey[800]!
                                      : Colors.grey[300]!,
                                  highlightColor: isDark
                                      ? Colors.grey[700]!
                                      : Colors.grey[100]!,
                                  child: Container(color: Colors.white),
                                ),
                                errorWidget: (context, url, error) =>
                                    const SizedBox.shrink(),
                              ),
                              Positioned(
                                right: 10,
                                bottom: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.zoom_in_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: hasImage ? 22 : 26,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!hasImage) ...[
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '“',
                                style: TextStyle(
                                  fontFamily: AppTheme.serifFontFamily,
                                  fontSize: 48.0,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondarySaffron,
                                  height: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          Text(
                            _currentSandesh.content.trim(),
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontFamily: AppTheme.serifFontFamily,
                              fontSize: 18.5,
                              height: 1.65,
                              letterSpacing: 0.15,
                              color: darkBrown,
                            ),
                          ),
                          if (_currentSandesh.hasEventTitle) ...[
                            const SizedBox(height: 14),
                            Text(
                              _currentSandesh.title.trim(),
                              style: TextStyle(
                                fontFamily: AppTheme.serifFontFamily,
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFFF0C060)
                                    : AppTheme.secondarySaffron,
                                height: 1.35,
                              ),
                            ),
                          ],
                          if (_isLoadingFullContent) ...[
                            const SizedBox(height: 12),
                            const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.secondarySaffron,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
