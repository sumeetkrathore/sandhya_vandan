import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../widgets/sandesh_share_dialog.dart';

import '../models/sandesh.dart';
import '../services/sandesh_service.dart';
import '../theme/app_theme.dart';
import '../utils/text_utils.dart';

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
    final shimmerBase = isDark
        ? (Colors.grey[800] ?? Colors.black54)
        : (Colors.grey[300] ?? Colors.grey);
    final shimmerHighlight = isDark
        ? (Colors.grey[700] ?? Colors.black45)
        : (Colors.grey[100] ?? Colors.white);

    final imageUrl = _currentSandesh.imageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Daily Sandesh',
          style: AppTheme.appBarTitle.copyWith(color: AppTheme.primaryIvory),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Artwork / Image (if present)
                if (hasImage) ...[
                  GestureDetector(
                    onTap: () => _openFullscreenImage(context, imageUrl),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.cardBorder(context)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
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
                                      baseColor: shimmerBase,
                                      highlightColor: shimmerHighlight,
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
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 2. Sacred Wisdom Card
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF24070D) // Deep Sacred Burgundy
                        : const Color(0xFFFFFDF9), // Warm Spiritual Ivory
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primaryGold.withValues(
                        alpha: isDark ? 0.35 : 0.3,
                      ),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.4 : 0.05,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 18.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Date Badge
                      Builder(
                        builder: (context) {
                          String dateStr;
                          try {
                            dateStr = DateFormat('EEEE, MMMM d, yyyy')
                                .format(_currentSandesh.date);
                          } catch (_) {
                            dateStr =
                                '${_currentSandesh.date.day}/${_currentSandesh.date.month}/${_currentSandesh.date.year}';
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGold.withValues(
                                alpha: isDark ? 0.16 : 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.primaryGold.withValues(
                                  alpha: 0.3,
                                ),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 13,
                                  color: AppTheme.primaryGold,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                    color: AppTheme.primaryGold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // Centered Opening Quote Icon
                      Center(
                        child: Icon(
                          Icons.format_quote_rounded,
                          size: 30,
                          color: AppTheme.primaryGold.withValues(
                            alpha: isDark ? 0.6 : 0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Title (if present)
                      if (_currentSandesh.title.trim().isNotEmpty) ...[
                        Text(
                          TextUtils.preventOrphans(
                            _currentSandesh.title.trim(),
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTheme.serifFontFamily,
                            fontSize: 22.0,
                            color: isDark
                                ? AppTheme.primaryIvory
                                : AppTheme.darkBackground,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Message Body with comfortable spiritual reading typography
                      Text(
                        _currentSandesh.content.trim(),
                        style: TextStyle(
                          fontFamily: AppTheme.serifFontFamily,
                          fontSize: 18.0,
                          height: 1.75,
                          letterSpacing: 0.2,
                          color: isDark
                              ? const Color(0xFFEADBCE)
                              : const Color(0xFF2C2421),
                        ),
                      ),

                      if (_isLoadingFullContent) ...[
                        const SizedBox(height: 12),
                        const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryGold,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Closing Spiritual Flourish
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppTheme.primaryGold.withValues(alpha: 0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.spa_rounded,
                              size: 18,
                              color: AppTheme.primaryGold.withValues(
                                alpha: 0.75,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Jai Samadha',
                              style: TextStyle(
                                fontFamily: AppTheme.serifFontFamily,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                color: AppTheme.primaryGold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
