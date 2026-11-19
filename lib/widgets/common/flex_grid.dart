import 'package:flutter/material.dart';

/// A grid whose rows are as tall as their tallest card, instead of a fixed
/// aspect ratio. `GridView.count(childAspectRatio: …)` gives every cell the
/// same height whatever is inside, so larger text, a narrow screen or a longer
/// translation overflows the cell. Here the card decides its own height and the
/// cards in a row are stretched to match.
///
/// The number of columns drops automatically when the screen is too narrow for
/// [columns] cells of at least [minColumnWidth] (a folded phone's cover screen
/// gets two columns instead of three, and so on).
class FlexGrid extends StatelessWidget {
  const FlexGrid({
    super.key,
    required this.children,
    this.columns = 2,
    this.spacing = 10,
    this.minColumnWidth = 100,
  });

  final List<Widget> children;
  final int columns;
  final double spacing;
  final double minColumnWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var cols = columns;
        if (constraints.hasBoundedWidth) {
          final fit = ((constraints.maxWidth + spacing) / (minColumnWidth + spacing)).floor();
          cols = fit.clamp(1, columns);
        }

        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += cols) {
          final cells = <Widget>[];
          for (var c = 0; c < cols; c++) {
            if (c > 0) cells.add(SizedBox(width: spacing));
            final index = i + c;
            cells.add(Expanded(child: index < children.length ? children[index] : const SizedBox.shrink()));
          }
          if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
          rows.add(IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: cells)));
        }
        return Column(mainAxisSize: MainAxisSize.min, children: rows);
      },
    );
  }
}
