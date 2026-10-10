import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FrostedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;
  final bool isScrolled;

  const FrostedAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.bottom,
    this.isScrolled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isScrolled
        ? (isDark
              ? AppTheme.deepBurgundy.withValues(alpha: 0.80)
              : AppTheme.deepBurgundy.withValues(alpha: 0.88))
        : AppTheme.deepBurgundy;

    final fgColor = isDark ? AppTheme.primaryGold : AppTheme.primaryIvory;

    return AppBar(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      surfaceTintColor: Colors.transparent,
      elevation: isScrolled ? 2 : 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      leading: leading,
      title:
          titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: AppTheme.appBarTitle.copyWith(color: fgColor),
                )
              : null),
      actions: actions,
      bottom: bottom,
      flexibleSpace: isScrolled
          ? ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: (isDark ? AppTheme.primaryGold : Colors.white)
                            .withValues(alpha: 0.15),
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
