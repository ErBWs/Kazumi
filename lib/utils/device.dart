import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

bool isOhosDesktop = false;

Future<bool> isLowResolution() async {
  if (Platform.isMacOS) {
    return false;
  }
  final screenInfo = await getScreenInfo();
  return screenInfo['height']! / screenInfo['ratio']! < 900;
}

Future<Map<String, double>> getScreenInfo() async {
  final mediaQuery = MediaQueryData.fromView(
    WidgetsBinding.instance.platformDispatcher.views.first,
  );
  final screenSize =
      WidgetsBinding.instance.platformDispatcher.displays.first.size;
  return {
    'width': screenSize.width,
    'height': screenSize.height,
    'ratio': mediaQuery.devicePixelRatio,
  };
}

bool isDesktop() {
  return Platform.isWindows || Platform.isMacOS || Platform.isLinux || isOhosDesktop;
}

Future<void> checkOhosDesktop() async {
  if (Platform.isOhos) {
    const platform = MethodChannel('com.predidit.kazumi/intent');
    try {
      isOhosDesktop = await platform.invokeMethod('checkOhosIsDesktop');
    } on PlatformException catch (e) {
      debugPrint("Failed to check device type: '${e.message}'.");
      isOhosDesktop = false;
    }
    debugPrint("ohos 桌面: $isOhosDesktop");
  }
}

bool isWideScreen() {
  final mediaQuery = MediaQueryData.fromView(
    WidgetsBinding.instance.platformDispatcher.views.first,
  );
  return mediaQuery.size.shortestSide >= 600 &&
      mediaQuery.size.shortestSide / mediaQuery.size.longestSide >= 9 / 16;
}

bool isTablet() {
  return isWideScreen() && !isDesktop();
}

bool isCompact() {
  return !isDesktop() && !isWideScreen();
}
