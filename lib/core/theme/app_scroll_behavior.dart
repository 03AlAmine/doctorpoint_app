import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class AppScrollBehavior extends ScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context, 
    Widget child, 
    ScrollableDetails details
  ) {
    return child; // Pas d'indicateur de dépassement
  }

  @override
  Widget buildScrollbar(
    BuildContext context, 
    Widget child, 
    ScrollableDetails details
  ) {
    return child; // Pas de barre de défilement
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.unknown,
  };

  @override
  TargetPlatform getPlatform(BuildContext context) {
    return TargetPlatform.android;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}