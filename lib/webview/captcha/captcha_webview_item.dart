import 'package:flutter/material.dart';
import 'package:kazumi/utils/utils.dart';
import 'package:kazumi/utils/logger.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:kazumi/webview/captcha/captcha_webview_controller.dart';

class CaptchaWebviewItem extends StatefulWidget {
  final CaptchaWebviewController captchaWebviewController;

  const CaptchaWebviewItem({super.key, required this.captchaWebviewController});

  @override
  State<CaptchaWebviewItem> createState() => _CaptchaWebviewItemState();
}

class _CaptchaWebviewItemState extends State<CaptchaWebviewItem> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    widget.captchaWebviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformInAppWebViewWidget(PlatformInAppWebViewWidgetCreationParams(
      initialSettings: InAppWebViewSettings(
        userAgent: Utils.getRandomUA(),
        mediaPlaybackRequiresUserGesture: true,
        cacheEnabled: true,
        blockNetworkImage: false,
        loadsImagesAutomatically: true,
        upgradeKnownHostsToHTTPS: false,
        safeBrowsingEnabled: false,
      ),
      onWebViewCreated: (controller) {
        widget.captchaWebviewController.logEventController
            .add('[Captcha WebView] Created');
        widget.captchaWebviewController.webviewController = controller;
        widget.captchaWebviewController.initEventController.add(true);
      },
      onLoadStart: (controller, url) {
        widget.captchaWebviewController.logEventController
            .add('[Captcha WebView] Load start: $url');
      },
      onLoadStop: (controller, url) {
        widget.captchaWebviewController.logEventController
            .add('[Captcha WebView] Load stop: $url');
        if (widget.captchaWebviewController.buttonWasClicked &&
            !widget.captchaWebviewController.captchaDisappearedController
                .isClosed) {
          KazumiLogger().i(
              '[Captcha WebView] Button click → page navigated, verification done');
          widget.captchaWebviewController.buttonWasClicked = false;
          widget.captchaWebviewController.captchaDisappearedController
              .add(null);
        }
      },
      onReceivedError: (controller, request, error) {
        widget.captchaWebviewController.logEventController
            .add('[Captcha WebView] Error: ${error.description}');
      },
    )).build(context);
  }
}
