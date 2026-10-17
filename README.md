# Kazumi

该分支为使用 [CPF-Flutter / flutter_flutter](https://gitcode.com/CPF-Flutter/flutter_flutter) 进行适配的 Kazumi
ohos (HarmonyOS NEXT) 版本。

> [!IMPORTANT]
>
> 该分支仅考虑 ohos 平台的适配，若使用该分支构建其他平台会导致各种问题。

## 支持情况

- 目标 API 版本：26（SDK 26.0.0.105）
- 兼容 API 版本：6.0.0(20)
- Flutter 版本：3.41.9+ohos-1.0.2
- Kazumi 版本：2.3.9（规则 API 9）
- 当前新版原生依赖支持 arm64 真机

构建、依赖和验证范围见 [鸿蒙构建说明](static/doc/OHOS_BUILD.md)。

## 功能适配情况

以下为现有适配功能；本次验证范围及尚待回归的场景见构建说明。

- [x] 视频解析器
- [x] 手势亮度调节
- [x] 手势系统音量调节
- [x] 智慧多窗
- [x] 鸿蒙 PC
- [x] 基于 mpv 的视频播放器
- [x] 硬件解码
- [x] 外部播放器

## 下载与安装

通过本页面 [releases](https://github.com/ErBWs/Kazumi/releases) 选项卡下载：

<a href="https://github.com/ErBWs/Kazumi/releases">
  <img src="static/svg/get_it_on_github.svg" alt="Get it on Github" width="200"/>
</a>

使用[小白调试助手](https://github.com/likuai2010/auto-installer)进行安装

## 开源协议

GNU 通用公共许可证第 3 版 (GPL-3.0)
