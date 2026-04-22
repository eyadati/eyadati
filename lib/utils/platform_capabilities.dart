import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PlatformCapabilities {
  static bool get isWeb => kIsWeb;

  static bool get isMobile => !kIsWeb;

  static bool get supportsNativeCamera => !kIsWeb;

  static bool get supportsNativeLocation => !kIsWeb;

  static bool get supportsNativeCalendar => !kIsWeb;

  static bool get supportsPushNotifications => !kIsWeb;

  static bool get supportsBackgroundLocation => !kIsWeb;

  static Widget getQrWidget({
    required Widget cameraWidget,
    required Widget fallbackWidget,
  }) {
    if (kIsWeb) return fallbackWidget;
    return cameraWidget;
  }

  static Widget getLocationWidget({
    required Widget gpsWidget,
    required Widget manualWidget,
  }) {
    if (kIsWeb) return manualWidget;
    return gpsWidget;
  }

  static Widget getCalendarWidget({
    required Widget nativeWidget,
    required Widget webWidget,
  }) {
    if (kIsWeb) return webWidget;
    return nativeWidget;
  }
}

enum FeatureSupport {
  native, // Only on mobile (native SDK)
  web, // Only on web
  both, // Works on both
  fallback, // Has web fallback
}

extension FeatureExtension on FeatureSupport {
  bool isAvailable() {
    switch (this) {
      case FeatureSupport.native:
        return !kIsWeb;
      case FeatureSupport.web:
        return kIsWeb;
      case FeatureSupport.both:
        return true;
      case FeatureSupport.fallback:
        return true;
    }
  }
}
