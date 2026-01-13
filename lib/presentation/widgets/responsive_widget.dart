import 'package:flutter/material.dart';

class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= 1200) {
      return desktop;
    } else if (width >= 600 && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}

class ResponsivePadding extends EdgeInsets {
  const ResponsivePadding({
    double mobile = 16,
    double tablet = 24,
    double desktop = 32,
  }) : super.all(0);

  factory ResponsivePadding.symmetric({
    double horizontal = 16,
    double vertical = 16,
  }) {
    return const ResponsivePadding();
  }

  static EdgeInsets fromContext(
    BuildContext context, {
    double mobile = 16,
    double tablet = 24,
    double desktop = 32,
  }) {
    if (ResponsiveWidget.isDesktop(context)) {
      return EdgeInsets.all(desktop);
    } else if (ResponsiveWidget.isTablet(context)) {
      return EdgeInsets.all(tablet);
    } else {
      return EdgeInsets.all(mobile);
    }
  }
}