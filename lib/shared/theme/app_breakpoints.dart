import 'package:flutter/material.dart';

/// Layout breakpoints — phone-first, with tablet/desktop widening.
class AppBreakpoints {
  AppBreakpoints._();

  /// Below this the layout is a phone: single column, full width.
  static const double tablet = 600.0;

  /// At and above this the layout is desktop-like.
  static const double desktop = 1024.0;

  /// Widest a reading/list column should grow on large screens.
  static const double contentMaxWidth = 720.0;

  /// Widest a single-column form should grow on large screens.
  static const double formMaxWidth = 560.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tablet;

  static bool isTabletOrWider(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;
}

/// Keeps content at a comfortable width on tablets/desktop while
/// staying full-width on phones: top-centered, capped at [maxWidth].
class ResponsiveContent extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const ResponsiveContent({
    super.key,
    this.maxWidth = AppBreakpoints.contentMaxWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
