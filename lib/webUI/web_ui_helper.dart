import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class WebUIHelper {
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 900;
  }

  static bool isMobileDevice() {
    if (kIsWeb) return false;
    // Note: If you need to detect Android/iOS on mobile, 
    // consider using targetPlatform directly or a plugin like device_info_plus.
    // For this context, checking if NOT web is sufficient as per original intent.
    return true; 
  }

  static double getResponsiveWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 1200;
    return width;
  }
}

class FormResponsiveWrapper extends StatelessWidget {
  final Widget child;
  const FormResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return child;

    return Container(
      color: Colors.black.withAlpha(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 20,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
