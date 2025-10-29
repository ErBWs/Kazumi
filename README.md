# Kazumi

该分支为使用 [OpenHarmony-TPC / flutter_flutter](https://gitcode.com/openharmony-tpc/flutter_flutter) 进行适配的 Kazumi
ohos (HarmonyOS NEXT) 版本。

> [!IMPORTANT]
>
> 该分支仅考虑 ohos 平台的适配，若使用该分支构建其他平台会导致各种问题。

## 支持情况

- 目标 API 版本：6.0.0(20)
- 兼容 API 版本：5.0.3(15)
- Flutter 版本：3.32.4-ohos

## 功能适配情况

- [x] 视频解析器
- [x] 原生视频播放器
- [x] 手势亮度调节
- [x] 智慧多窗
- [x] 鸿蒙 PC (见[关于鸿蒙PC](#关于鸿蒙-PC))
- [x] ~~外部播放器~~(目前没有软件支持外部网络视频链接拉起)
- [ ] 基于 mpv 的视频播放器 (见 https://github.com/ErBWs/Kazumi/issues/13)
- [ ] ~~手势系统音量调节~~(架构不支持)

## 下载与安装

通过本页面 [releases](https://github.com/ErBWs/Kazumi/releases) 选项卡下载：

<a href="https://github.com/ErBWs/Kazumi/releases">
  <img src="static/svg/get_it_on_github.svg" alt="Get it on Github" width="200"/>
</a>

使用[小白调试助手](https://github.com/likuai2010/auto-installer)进行安装

## 关于鸿蒙 PC

看到 DevEco 可以创建鸿蒙 PC 模拟器，心血来潮做了点适配。
和 ohos 的手机端功能基本相同，只支持电脑端的操作，不支持触摸操作

沉浸式标题栏其实也挺好做，[官网](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-multi-window#section337674919110)有详细适配流程，
我做好适配给 window_manager 插件提个 PR 就可以了。但我懒得写那么多东西（

鸿蒙 PC 平台的 bug 有也不一定会修，很费劲

## 开源协议

GNU 通用公共许可证第 3 版 (GPL-3.0)