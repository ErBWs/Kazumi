import 'package:flutter/material.dart';
import 'package:kazumi/utils/utils.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:kazumi/webview/video/video_webview_controller.dart';

class VideoWebviewItem extends StatefulWidget {
  final VideoWebviewController videoWebviewController;

  const VideoWebviewItem({super.key, required this.videoWebviewController});

  @override
  State<VideoWebviewItem> createState() => _VideoWebviewItemState();
}

class _VideoWebviewItemState extends State<VideoWebviewItem> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    widget.videoWebviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformInAppWebViewWidget(PlatformInAppWebViewWidgetCreationParams(
      initialSettings: InAppWebViewSettings(
        userAgent: Utils.getRandomUA(),
        mediaPlaybackRequiresUserGesture: true,
        cacheEnabled: false,
        blockNetworkImage: true,
        loadsImagesAutomatically: false,
        upgradeKnownHostsToHTTPS: false,
        safeBrowsingEnabled: false,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
        geolocationEnabled: false,
      ),
      onWebViewCreated: (controller) {
        debugPrint('[WebView] Created');
        widget.videoWebviewController.webviewController = controller;
        widget.videoWebviewController.initEventController.add(true);
      },
      onLoadStart: (controller, url) async {
        widget.videoWebviewController.logEventController
            .add('started loading: $url');
      },
      onLoadStop: (controller, url) {
        widget.videoWebviewController.logEventController
            .add('loading completed: $url');
      },
    )).build(context);
  }
}
