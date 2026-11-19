import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Wraps the whole app (via `MaterialApp.builder`) so every screen is laid out
/// for a phone-width column no matter what device it runs on:
///
/// * **Wide screens** (tablets, a foldable opened flat, landscape): the app is
///   centred in a column at most [maxContentWidth] wide, with plain gutters on
///   either side, instead of stretching phone layouts across 1000+ pixels.
///   Descendants see that column width through `MediaQuery`, so anything that
///   reads `MediaQuery.of(context).size.width` stays consistent.
/// * **Large text**: the system font-size setting is honoured up to
///   [maxTextScale]. Beyond that, fixed-height controls (tab bars, chips,
///   badges, buttons) and dense rows cannot fit their text, so the scale is
///   capped rather than letting layouts break.
/// * **Very narrow screens** (a folded foldable's cover display is about
///   280 dp): nothing here changes the width; the screens themselves are written
///   to shrink (see `test/layout`).
class AppFrame extends StatelessWidget {
  const AppFrame({super.key, required this.child});

  final Widget child;

  static const double maxContentWidth = 600;
  static const double minTextScale = 0.85;
  static const double maxTextScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = math.min(media.size.width, maxContentWidth);
    final column = MediaQuery(
      data: media.copyWith(
        size: Size(width, media.size.height),
        textScaler: media.textScaler.clamp(minScaleFactor: minTextScale, maxScaleFactor: maxTextScale),
      ),
      child: child,
    );

    if (media.size.width <= maxContentWidth) return column;

    return ColoredBox(
      color: AppColors.surfaceVariant,
      child: Center(
        child: SizedBox(
          width: width,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.symmetric(vertical: BorderSide(color: AppColors.border)),
            ),
            child: ClipRect(child: column),
          ),
        ),
      ),
    );
  }
}
