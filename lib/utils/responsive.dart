import 'package:flutter/widgets.dart';

/// How much the person has scaled text in system settings (1.0 = default),
/// after `AppFrame` has capped it.
double textScaleOf(BuildContext context) => MediaQuery.textScalerOf(context).scale(1.0);

/// A height for an area with a fixed extent (a collapsing app bar, a banner)
/// that contains text. [base] is the height at default text size; it grows with
/// the text-size setting so the text always fits. [textShare] is the fraction
/// of the content that is text and therefore scales (the rest is icons and
/// spacing, which do not).
double scaledExtent(BuildContext context, double base, {double textShare = 0.5}) {
  final scale = textScaleOf(context);
  return base * (1 + (scale - 1) * textShare);
}
