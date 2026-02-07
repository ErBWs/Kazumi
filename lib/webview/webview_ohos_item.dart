import 'package:flutter/material.dart';
import 'package:kazumi/webview/webview_controller.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/webview/webview_controller_impel/webview_ohos_controller_impel.dart';
import 'package:kazumi/utils/utils.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';

class WebviewOhosItem extends StatefulWidget {
  const WebviewOhosItem({super.key});

  @override
  State<WebviewOhosItem> createState() => _WebviewOhosItemState();
}

class _WebviewOhosItemState extends State<WebviewOhosItem> {
  final webviewOhosItemController =
      Modular.get<WebviewItemController>() as WebviewOhosItemControllerImpel;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    webviewOhosItemController.dispose();
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
        webviewOhosItemController.webviewController = controller;
        webviewOhosItemController.init();
      },
      onLoadStart: (controller, url) async {
        webviewOhosItemController.logEventController
            .add('started loading: $url');
        if (url.toString() != 'about:blank') {
          await webviewOhosItemController.onLoadStart();
        }
      },
      onLoadStop: (controller, url) {
        webviewOhosItemController.logEventController
            .add('loading completed: $url');
      },
    )).build(context);
  }
}
