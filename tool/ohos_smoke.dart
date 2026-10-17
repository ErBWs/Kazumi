// An integration entry point that runs the application and checks its OHOS
// integrations. Normal builds continue to use lib/main.dart.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ech_http/ech_http.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kazumi/main.dart' as app;
import 'package:kazumi/navigation.dart';
import 'package:kazumi/request/core/dio_factory.dart';
import 'package:kazumi/services/network/bangumi_ech_image_service.dart';
import 'package:kazumi/services/network/bangumi_ech_resolver.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

Future<void> main() async {
  await app.main();
  const release = bool.fromEnvironment('dart.vm.product');
  debugPrint('KAZUMI_OHOS_SMOKE mode=${release ? 'release' : 'debug'}');
  // Use the ECH route in this dedicated smoke installation, including the UI.
  await GStorage.putSetting(SettingsKeys.bangumiAcceleration, 'ech');
  DioFactory.reset();
  await _check('network', _network);
  const video = String.fromEnvironment('OHOS_SMOKE_VIDEO');
  if (video.isNotEmpty) await _check('playback', () => _playback(video));
}

Future<void> _check(String name, Future<void> Function() test) async {
  try {
    await test();
    debugPrint('KAZUMI_OHOS_SMOKE $name PASS');
  } catch (error, stack) {
    debugPrint('KAZUMI_OHOS_SMOKE $name FAIL: $error\n$stack');
  }
}

Future<void> _network() async {
  final bootstrap = EchClient();
  final client = EchClient(resolver: BangumiEchResolver.create(bootstrap));
  final images = BangumiEchImageService(proxyForUrl: (_) => null);
  try {
    final uri = Uri.https('api.bgm.tv', '/v0/subjects/2');
    final response = await client.send(http.Request('GET', uri));
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200 || response.echAccepted != true) {
      throw StateError(
        'Bangumi HTTP ${response.statusCode}, ECH ${response.echAccepted}',
      );
    }
    debugPrint('KAZUMI_OHOS_SMOKE Bangumi HTTP 200, ECH accepted: true');
    final data = jsonDecode(body) as Map<String, dynamic>;
    final dio = await DioFactory.bangumiDio.get(uri.toString());
    if (dio.statusCode != 200 || dio.data['id'] != 2) {
      throw StateError('Bangumi Dio adapter response is invalid');
    }
    debugPrint('KAZUMI_OHOS_SMOKE Bangumi Dio adapter HTTP 200, JSON id=2');
    final image = await images.get(data['images']['small'] as String);
    final length = await image.content.fold<int>(
      0,
      (n, bytes) => n + bytes.length,
    );
    if (image.statusCode != 200 || length == 0) {
      throw StateError('Bangumi image HTTP ${image.statusCode}, bytes=$length');
    }
    debugPrint('KAZUMI_OHOS_SMOKE Bangumi ECH image HTTP 200, bytes=$length');
  } finally {
    images.close();
    client.close();
    bootstrap.close();
  }
}

Future<void> _playback(String url) async {
  OverlayState? overlay;
  for (var i = 0; i < 100 && overlay == null; i++) {
    overlay = rootNavigatorKey.currentState?.overlay;
    if (overlay == null) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
  if (overlay == null) {
    throw StateError('Application navigator did not initialize');
  }
  final directory = await Directory.systemTemp.createTemp('kazumi-mpv-');
  final source = File('${directory.path}/player.mp4');
  final response = await http
      .get(Uri.parse(url))
      .timeout(const Duration(seconds: 20));
  if (response.statusCode != 200) {
    throw StateError('Test video HTTP ${response.statusCode}');
  }
  await source.writeAsBytes(response.bodyBytes);
  var cycles = 0;
  try {
    for (final hardware in [false, true]) {
      for (final asynchronous in [false, true]) {
        for (var iteration = 0; iteration < 3; iteration++) {
          final player = Player(
            configuration: PlayerConfiguration(async: asynchronous),
          );
          final native = player.platform! as NativePlayer;
          final controller = VideoController(
            player,
            configuration: VideoControllerConfiguration(
              enableHardwareAcceleration: hardware,
            ),
          );
          final entry = OverlayEntry(
            builder: (_) => Positioned(
              right: 16,
              bottom: 100,
              width: 320,
              height: 180,
              child: IgnorePointer(
                child: Video(controller: controller, controls: NoVideoControls),
              ),
            ),
          );
          overlay.insert(entry);
          final errors = <String>[];
          final subscription = player.stream.error.listen(errors.add);
          try {
            await player.setVolume(0).timeout(const Duration(seconds: 15));
            await player
                .open(Media(source.path))
                .timeout(const Duration(seconds: 15));
            await controller.waitUntilFirstFrameRendered.timeout(
              const Duration(seconds: 20),
            );
            await player.stream.position
                .firstWhere((p) => p >= const Duration(seconds: 1))
                .timeout(const Duration(seconds: 20));
            if (errors.isNotEmpty) throw StateError(errors.join('; '));
            if (controller.id.value == null ||
                player.state.duration.inSeconds != 8) {
              throw StateError('Missing texture or unexpected video duration');
            }
            final decoder = await native.getProperty('hwdec-current');
            debugPrint(
              'KAZUMI_OHOS_SMOKE frame cycle=${cycles + 1}, '
              'hardware=$hardware, async=$asynchronous, hwdec=$decoder, '
              'position=${player.state.position}',
            );
          } finally {
            entry.remove();
            // Unmount the Texture before disposing its notifiers and surface.
            await WidgetsBinding.instance.endOfFrame;
            final watch = Stopwatch()..start();
            final first = native.dispose();
            if (!identical(first, native.dispose())) {
              throw StateError('Concurrent disposal did not reuse its Future');
            }
            await first.timeout(const Duration(seconds: 15));
            await native.dispose().timeout(const Duration(seconds: 2));
            await subscription.cancel();
            if (native.ctx.address != 0) {
              throw StateError('Disposed player retained its mpv handle');
            }
            debugPrint(
              'KAZUMI_OHOS_SMOKE dispose cycle=${cycles + 1}, '
              'handle=0, elapsed=${watch.elapsedMilliseconds}ms',
            );
          }
          cycles++;
        }
      }
    }
    for (var i = 0; i < 3; i++) {
      final player = Player();
      await player.dispose().timeout(const Duration(seconds: 15));
      if ((player.platform! as NativePlayer).ctx.address != 0) {
        throw StateError('Early disposal retained its mpv handle');
      }
    }
    debugPrint(
      'KAZUMI_OHOS_SMOKE lifecycle $cycles render/dispose cycles, '
      '3 early disposals PASS',
    );
  } finally {
    await directory.delete(recursive: true);
  }
}
