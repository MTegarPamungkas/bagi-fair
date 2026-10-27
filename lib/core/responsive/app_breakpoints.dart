import 'package:flutter/widgets.dart';

enum AppWindowClass { compact, medium, expanded }

abstract final class AppBreakpoints {
  static const double medium = 720;
  static const double expanded = 1040;
  static const double wide = 1440;
  static const double contentMaxWidth = 1240;

  static AppWindowClass windowClassFor(double width) {
    if (width >= expanded) return AppWindowClass.expanded;
    if (width >= medium) return AppWindowClass.medium;
    return AppWindowClass.compact;
  }

  static double pagePaddingFor(double width) {
    if (width >= wide) return 48;
    if (width >= expanded) return 36;
    if (width >= medium) return 28;
    return 18;
  }

  static double contentInsetFor(
    double width, {
    double maxWidth = contentMaxWidth,
    double? padding,
  }) {
    final edgePadding = padding ?? pagePaddingFor(width);
    final available = width - edgePadding * 2;
    return available > maxWidth ? (width - maxWidth) / 2 : edgePadding;
  }
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  AppWindowClass get windowClass => AppBreakpoints.windowClassFor(screenWidth);

  bool get isCompact => windowClass == AppWindowClass.compact;

  bool get isMedium => windowClass == AppWindowClass.medium;

  bool get isExpanded => windowClass == AppWindowClass.expanded;

  bool get usesSideNavigation => isExpanded;

  double get pagePadding => AppBreakpoints.pagePaddingFor(screenWidth);

  double get sectionGap => isCompact ? 22 : 30;

  T responsive<T>({required T compact, required T expanded, T? medium}) {
    return switch (windowClass) {
      AppWindowClass.compact => compact,
      AppWindowClass.medium => medium ?? compact,
      AppWindowClass.expanded => expanded,
    };
  }
}
