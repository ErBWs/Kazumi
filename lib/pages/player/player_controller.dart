import 'dart:io';
import 'dart:async';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:video_player/video_player.dart';
import 'package:kazumi/modules/danmaku/danmaku_module.dart';
import 'package:mobx/mobx.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:kazumi/request/damaku.dart';
import 'package:kazumi/pages/video/video_controller.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:hive/hive.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:logger/logger.dart';
import 'package:kazumi/utils/logger.dart';
import 'package:kazumi/utils/utils.dart';

part 'player_controller.g.dart';

class PlayerController = _PlayerController with _$PlayerController;

abstract class _PlayerController with Store {
  final VideoPageController videoPageController =
      Modular.get<VideoPageController>();

  // 弹幕控制
  late DanmakuController danmakuController;
  @observable
  Map<int, List<Danmaku>> danDanmakus = {};
  @observable
  bool danmakuOn = false;

  /// 视频比例类型
  /// 1. AUTO
  /// 2. COVER
  /// 3. FILL
  @observable
  int aspectRatioType = 1;

  /// 视频超分
  /// 1. OFF
  /// 2. Anime4K
  @observable
  int superResolutionType = 1;

  // 视频音量/亮度
  @observable
  double volume = -1;
  @observable
  double brightness = 0;

  // 播放器界面控制
  @observable
  bool lockPanel = false;
  @observable
  bool showVideoController = true;
  @observable
  bool showSeekTime = false;
  @observable
  bool showBrightness = false;
  @observable
  bool showVolume = false;
  @observable
  bool showPlaySpeed = false;
  @observable
  bool brightnessSeeking = false;
  @observable
  bool volumeSeeking = false;
  @observable
  bool canHidePlayerPanel = true;

  // 视频地址
  String videoUrl = '';

  // DanDanPlay 弹幕ID
  int bangumiID = 0;

  // 播放器实体
  late VideoPlayerController mediaPlayer;

  // 播放器面板状态
  @observable
  bool loading = true;
  @observable
  bool playing = false;
  @observable
  bool isBuffering = true;
  @observable
  bool completed = false;
  @observable
  Duration currentPosition = Duration.zero;
  @observable
  Duration buffer = Duration.zero;
  @observable
  Duration duration = Duration.zero;
  @observable
  double playerSpeed = 1.0;

  Box setting = GStorage.setting;
  bool hAenable = true;
  late String hardwareDecoder;
  bool lowMemoryMode = false;
  bool autoPlay = true;
  bool playerDebugMode = false;
  int forwardTime = 80;

  // 播放器实时状态
  bool get playerPlaying => mediaPlayer.value.isPlaying;

  bool get playerBuffering => mediaPlayer.value.isBuffering;

  bool get playerCompleted =>
      mediaPlayer.value.position >= mediaPlayer.value.duration;

  double get playerVolume => mediaPlayer.value.volume;

  Duration get playerPosition => mediaPlayer.value.position;

  Duration get playerBuffer => mediaPlayer.value.buffered.isEmpty
      ? Duration.zero
      : mediaPlayer.value.buffered[0].end;

  Duration get playerDuration => mediaPlayer.value.duration;

  /// 播放器内部日志
  List<String> playerLog = ['暂不支持'];

  Future<void> init(String url, {int offset = 0}) async {
    videoUrl = url;
    playing = false;
    loading = true;
    isBuffering = true;
    currentPosition = Duration.zero;
    buffer = Duration.zero;
    duration = Duration.zero;
    completed = false;
    try {
      await dispose();
    } catch (_) {}
    int episodeFromTitle = 0;
    try {
      episodeFromTitle = Utils.extractEpisodeNumber(videoPageController
          .roadList[videoPageController.currentRoad]
          .identifier[videoPageController.currentEpisode - 1]);
    } catch (e) {
      KazumiLogger().log(Level.error, '从标题解析集数错误 ${e.toString()}');
    }
    if (episodeFromTitle == 0) {
      episodeFromTitle = videoPageController.currentEpisode;
    }
    getDanDanmaku(videoPageController.title, episodeFromTitle);
    mediaPlayer = await createVideoController();
    bool autoPlay = setting.get(SettingBoxKey.autoPlay, defaultValue: true);
    playerSpeed =
        setting.get(SettingBoxKey.defaultPlaySpeed, defaultValue: 1.0);
    if (offset != 0) {
      await mediaPlayer.seekTo(Duration(seconds: offset));
    }
    if (autoPlay) {
      await mediaPlayer.play();
    }
    if (Utils.isDesktop()) {
      volume = volume != -1 ? volume : 100;
    } else {
      volume = volume != -1 ? volume : 100;
    }
    await setVolume(volume);
    setPlaybackSpeed(playerSpeed);
    KazumiLogger().log(Level.info, 'VideoURL初始化完成');
    loading = false;
  }

  Future<VideoPlayerController> createVideoController({int offset = 0}) async {
    String userAgent = '';
    playerDebugMode =
        setting.get(SettingBoxKey.playerDebugMode, defaultValue: false);
    if (videoPageController.currentPlugin.userAgent == '') {
      userAgent = Utils.getRandomUA();
    } else {
      userAgent = videoPageController.currentPlugin.userAgent;
    }
    String referer = videoPageController.currentPlugin.referer;
    var httpHeaders = {
      'user-agent': userAgent,
      if (referer.isNotEmpty) 'referer': referer,
    };
    mediaPlayer = VideoPlayerController.networkUrl(Uri.parse(videoUrl),
        httpHeaders: httpHeaders);
    // error handle
    bool showPlayerError =
        setting.get(SettingBoxKey.showPlayerError, defaultValue: true);
    mediaPlayer.addListener(() {
      if (mediaPlayer.value.hasError &&
          mediaPlayer.value.position < mediaPlayer.value.duration) {
        if (showPlayerError) {
          KazumiDialog.showToast(
              message:
                  '播放器内部错误 ${mediaPlayer.value.errorDescription} $videoUrl',
              duration: const Duration(seconds: 5),
              showUndoButton: true);
        }
        KazumiLogger().log(Level.error,
            'Player inent error. ${mediaPlayer.value.errorDescription} $videoUrl');
      }
    });
    await mediaPlayer.initialize();
    return mediaPlayer;
  }

  Future<void> setPlaybackSpeed(double playerSpeed) async {
    this.playerSpeed = playerSpeed;
    try {
      mediaPlayer.setPlaybackSpeed(playerSpeed);
    } catch (e) {
      KazumiLogger().log(Level.error, '设置播放速度失败 ${e.toString()}');
    }
  }

  Future<void> setVolume(double value) async {
    value = value.clamp(0.0, 100.0);
    volume = value;
    try {
      if (Utils.isDesktop()) {
        await mediaPlayer.setVolume(value);
      } else {
        await mediaPlayer.setVolume(volume / 100);
      }
    } catch (_) {}
  }

  Future<void> playOrPause() async {
    if (mediaPlayer.value.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration duration) async {
    currentPosition = duration;
    danmakuController.clear();
    await mediaPlayer.seekTo(duration);
  }

  Future<void> pause() async {
    danmakuController.pause();
    await mediaPlayer.pause();
    playing = false;
  }

  Future<void> play() async {
    danmakuController.resume();
    await mediaPlayer.play();
    playing = true;
  }

  Future<void> dispose() async {
    try {
      await mediaPlayer.dispose();
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await mediaPlayer.pause();
      loading = true;
    } catch (_) {}
  }

  // Future<Uint8List?> screenshot({String format = 'image/jpeg'}) async {
  //   return await mediaPlayer.screenshot(format: format);
  // }

  void setForwardTime(int time) {
    forwardTime = time;
  }

  Future<void> getDanDanmaku(String title, int episode) async {
    KazumiLogger().log(Level.info, '尝试获取弹幕 $title');
    try {
      danDanmakus.clear();
      bangumiID = await DanmakuRequest.getBangumiID(title);
      var res = await DanmakuRequest.getDanDanmaku(bangumiID, episode);
      addDanmakus(res);
    } catch (e) {
      KazumiLogger().log(Level.warning, '获取弹幕错误 ${e.toString()}');
    }
  }

  Future<void> getDanDanmakuByEpisodeID(int episodeID) async {
    KazumiLogger().log(Level.info, '尝试获取弹幕 $episodeID');
    try {
      danDanmakus.clear();
      var res = await DanmakuRequest.getDanDanmakuByEpisodeID(episodeID);
      addDanmakus(res);
    } catch (e) {
      KazumiLogger().log(Level.warning, '获取弹幕错误 ${e.toString()}');
    }
  }

  void addDanmakus(List<Danmaku> danmakus) {
    for (var element in danmakus) {
      var danmakuList =
          danDanmakus[element.time.toInt()] ?? List.empty(growable: true);
      danmakuList.add(element);
      danDanmakus[element.time.toInt()] = danmakuList;
    }
  }
}
