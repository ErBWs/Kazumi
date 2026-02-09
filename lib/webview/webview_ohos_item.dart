import 'package:flutter/material.dart';
import 'package:kazumi/utils/utils.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:kazumi/webview/webview_controller_impel/webview_ohos_controller_impel.dart';

class WebviewOhosItem extends StatefulWidget {
  final WebviewOhosItemControllerImpel webviewOhosItemController;
  const WebviewOhosItem({super.key, required this.webviewOhosItemController});

  @override
  State<WebviewOhosItem> createState() => _WebviewOhosItemState();
}

class _WebviewOhosItemState extends State<WebviewOhosItem> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    widget.webviewOhosItemController.dispose();
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
        widget.webviewOhosItemController.webviewController = controller;
        widget.webviewOhosItemController.initEventController.add(true);
      },
      onLoadStart: (controller, url) async {
        widget.webviewOhosItemController.logEventController
            .add('started loading: $url');
      },
      onLoadStop: (controller, url) {
        widget.webviewOhosItemController.logEventController
            .add('loading completed: $url');
      },
    )).build(context);
  }
}
