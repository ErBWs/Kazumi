# Kazumi 2.3.9 鸿蒙构建与验证

本次集成从 `ErBWs/Kazumi:feat-ohos` 的
`80eac7aa3a6e1680bdf74c1045f2657022f7dd68` 开始，合并上游正式标签
`2.3.9`（`025dcb5c2f62db881382c72f191d08b49a9feb41`），规则 API 为 9。
复用已验证的鸿蒙实现，并保留原 `feat-ohos` 的仓库配置、正式包名
`com.predidit.kazumi`、应用名和 ErBWs 的更新渠道。

## 工具链与原生依赖

- Flutter-OH `3.41.9+ohos-1.0.2`，固定提交
  `62357a93d653bf844f730bb1f4b7cc9e2139d14e`，Dart 3.11.5。
- HarmonyOS CLI `26.0.0.821` / SDK `26.0.0.105`，JDK 17，Python >=3.12，
  CMake、Ninja 和 C++ 编译器。工程最低 API 保持 20，当前真机验证为 API 26。
- `media_kit` 与 `media_kit_video` 均使用 `Predidit/media-kit` 的
  `9c31fe57c5c4492835dcd6fea968920f3b01bcb1`（上游 PR #43）。
  hook 识别 Flutter-OH 提供的 OHOS 编译器，打包鸿蒙 `libmpv.so` 和 C++ 运行库，
  并以 OHOS triple/sysroot 编译 C 事件循环。不再使用 `media_kit_libs_*`。
- `ech_http` 使用 `ech-research/ech_http` 的
  `2c58622b3596593b1c6818ddca7cdd0a0631aa15`（上游 PR #1）。
  hook 下载组织仓库 `ech-research/libechhttp-ohos-build` 的固定 SDK 并校验
  SHA-256，本地编译 C++ 桥接代码。
- 鸿蒙插件均固定到已验证的 Git 提交，解析结果保存在 `pubspec.lock`。
  无需相邻的本地 media-kit 或 ech_http 仓库。

当前完整播放器构建支持 arm64 真机；其他架构和模拟器尚不在本次支持范围。
Flutter-OH 3.41 的兼容处理包括版本号编译参数、旧版重排回调及索引调整，
以及移除尚不可用的 `MenuAnchor.animated` 参数。

## 构建与检查

安装上述工具链，将 Flutter-OH、Java、CMake、Ninja 和 hdc 加入 PATH。
`HOS_SDK_HOME`、`DEVECO_SDK_HOME` 指向 CLI 的 `sdk` 目录，
`DEVECO_NODE_HOME` 指向 CLI 的 `tool/node` 目录，`JAVA_HOME` 指向 JDK 17。
若 SDK 无法自动定位，可设置 `OHOS_NDK_HOME` 为 `sdk/default/openharmony/native`。

```sh
export GIT_LFS_SKIP_SMUDGE=1
flutter pub get --enforce-lockfile
dart analyze lib tool test
flutter test --no-pub
flutter build hap --release --no-codesign --no-pub \
  --dart-define=KAZUMI_VERSION=2.3.9
python3 tool/verify_ohos_hap.py build/ohos/hap/entry-default-unsigned.hap
```

校验脚本检查正式包名、版本、Release AOT、arm64 ELF，以及 ECH、mpv、
C 事件循环和 C++ 运行库的 Native Assets 映射。
公开构建产物未签名，安装前需使用自己的设备证书和 Profile 签名。
不要将私钥、证书、Profile 或本机签名配置提交到仓库。

Apple Silicon 上，当前 Flutter-OH 的 Release snapshot 编译器为 x86_64，
需要 Rosetta。精简 Flutter-OH SDK 可使用 `dart analyze` 完成静态分析。

保留现有 `.github/workflows/build.yaml` 与 `release.yaml` 的触发条件、产物命名
和发布方式，只更新所需工具链、锁定依赖解析，并增加测试和 HAP 校验。
未引入 fork 测试版专用的发布工作流。

## 真机自检

`tool/ohos_smoke.dart` 是单独的测试入口，正常构建仍使用 `lib/main.dart`。
该入口会将 Bangumi 网络模式设为 ECH，应在专用测试安装中运行。
构建使用正式包名时，安装会替换同包名应用，请先保留需要的数据。

生成 8 秒本地视频，在另一个终端启动 HTTP 服务：

```sh
mkdir -p build/smoke
ffmpeg -f lavfi -i testsrc2=size=320x180:rate=24 -t 8 \
  -c:v libx264 -pix_fmt yuv420p -movflags +faststart build/smoke/player.mp4
python3 -m http.server 18765 --bind 127.0.0.1 --directory build/smoke
```

```sh
hdc rport tcp:18765 tcp:18765
flutter build hap --release --no-codesign --no-pub \
  --target tool/ohos_smoke.dart \
  --dart-define=KAZUMI_VERSION=2.3.9 \
  --dart-define=OHOS_SMOKE_VIDEO=http://127.0.0.1:18765/player.mp4
python3 tool/verify_ohos_hap.py build/ohos/hap/entry-default-unsigned.hap
# 使用本机证书及设备 Profile 签名为 smoke-signed.hap 后：
hdc install -r smoke-signed.hap
hdc shell aa start -a EntryAbility -b com.predidit.kazumi
hdc shell hilog -x -e KAZUMI_OHOS_SMOKE
```

检查日志中的 `mode=release`、`network PASS` 和 `playback PASS`，并确认没有
`FAIL`。网络检查包含 ECH 握手被接受、Bangumi API、实际 Dio adapter 和封面数据。
播放检查覆盖软解/硬解与同步/异步四种组合，每种 3 次，确认纹理首帧、进度推进、
并发/重复销毁和 mpv 句柄归零，另做 3 次初始化期间销毁。
截图可用于确认 Flutter 纹理实际显示测试画面。

测试完成后重新构建、签名并安装正常入口的 Release 包，停止本地 HTTP 服务，
并执行 `hdc fport rm tcp:18765 tcp:18765` 清理本次转发。

## 集成分支验证记录（2026-10-17）

- `flutter pub get --enforce-lockfile` 成功，无本地路径依赖。
  `dart analyze lib tool test` 无 error/warning，保留 27 条现有 info 级 lint；
  213 项 Flutter 测试全部通过。
- 现有 build/release 工作流通过 actionlint 检查。本轮未运行远程 CI。
- 正常入口及自检入口的 arm64 Release HAP 均构建、原生库校验、签名和验签通过。
  包名为 `com.predidit.kazumi`，版本 `2.3.9` / `20309`，最低 API 为 20，
  编译 SDK 为 `26.0.0.105`。两个包均为 `debug=false`，包含 AOT `libapp.so`，
  无 Debug kernel，ECH、mpv、C 事件循环及 C++ 运行库和映射完整。
- MatePad mini（MLR-AL10，HarmonyOS API 26）完成正式包名应用的首次安装、
  引导和规则安装。原有独立测试应用保留。
- 两轮 Release 自检均记录 `mode=release`、`network PASS`、`playback PASS`。
  ECH 握手被接受，Bangumi 直接请求、实际 Dio adapter、封面请求均 HTTP 200，
  封面接收 6643 字节。
- 每轮软解 `hwdec=no` / 硬解 `hwdec=ohcodec` 与同步/异步四种组合各测试 3 次，
  两轮合计 24 次播放/销毁和 6 次初始化期间销毁通过。每次确认纹理首帧、
  播放进度、并发销毁复用 Future、重复销毁完成及 mpv 句柄归零，
  销毁耗时为 70–189 ms。截图确认实际软解和硬解纹理画面显示。
  未观察到 Dart 未处理异常、进程崩溃或销毁超时，仍有 Flutter-OH 图片方向等平台日志。
- 本机日志和截图保存在 `build/integration/`，包括 `smoke-first.log`、`smoke.log`、
  两轮完整 runtime 日志、`smoke-software.png` 和 `smoke-hardware.png`，不随源码提交。
- 自检后已恢复正常 `lib/main.dart` 入口。使用安装的 `mgnacg` 规则完成搜索、
  来源检索和《游戏人生》第 1 话播放，确认实际画面及进度推进超过 2 分钟，
  横屏全屏进入和返回正常。截图为 `online-playback.png`、`online-progress.png`、
  `online-fullscreen.png`。本地构建未传入弹弹 API 凭据，弹幕接口返回 HTTP 403，
  本轮未验证弹幕加载。CI 继续沿用现有 API Secrets 配置。
- 检查后返回正常入口首页，停止本地 HTTP 服务并删除 USB 反向转发。
  最终首页截图为 `normal-final-home.png`，正常入口日志为 `normal-runtime.log`。
- 尚未覆盖低 API、其他设备、模拟器、后台续播、下载和账号同步；
  工程的最低 API 声明不代表已完成 API 20 真机回归。
