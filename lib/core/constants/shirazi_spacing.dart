import 'package:flutter/material.dart';

/// Spacing and Sizing constants matching Stitch specifications
class ShiraziSpacing {
  ShiraziSpacing._();

  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 40.0;

  static const double gutter = 24.0;
  static const double gutterMobile = 12.0;
  static const double margin = 40.0;
  static const double marginMobile = 16.0;

  static const double headerHeight = 64.0;
  static const double bottomNavHeight = 80.0;
}

class ShiraziRadius {
  ShiraziRadius._();

  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 24.0;
  static const double full = 9999.0;

  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius roundedXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(full));
}
