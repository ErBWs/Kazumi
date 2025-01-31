import 'package:card_settings_ui/card_settings_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/appbar/sys_app_bar.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/pages/menu/menu.dart';
import 'package:kazumi/pages/menu/side_menu.dart';
import 'package:kazumi/utils/storage.dart';
import 'package:kazumi/utils/utils.dart';
import 'package:provider/provider.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final exitBehaviorTitles = <String>['退出 Kazumi', '最小化至托盘', '每次都询问'];

  final setting = GStorage.setting;

  late int exitBehavior =
      setting.get(SettingBoxKey.exitBehavior, defaultValue: 2);

  dynamic navigationBarState;

  void onBackPressed(BuildContext context) {
    navigationBarState.updateSelectedIndex(0);
    Modular.to.navigate('/tab/popular/');
  }

  @override
  void initState() {
    super.initState();
    if (Utils.isCompact()) {
      navigationBarState =
          Provider.of<NavigationBarState>(context, listen: false);
    } else {
      navigationBarState =
          Provider.of<SideNavigationBarState>(context, listen: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        onBackPressed(context);
      },
      child: Scaffold(
        appBar: const SysAppBar(title: Text('我的')),
        body: Center(
          child: SizedBox(
            width: (MediaQuery.of(context).size.width > 1000) ? 1000 : null,
            child: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('播放历史与视频源'),
                  tiles: [
                    SettingsTile.navigation(
                      onPressed: (_) {
                        Modular.to.pushNamed('/settings/history/');
                      },
                      leading: const Icon(Icons.history_rounded),
                      title: const Text('历史记录'),
                      description: const Text('查看播放历史记录'),
                    ),
                    SettingsTile.navigation(
                      onPressed: (_) {
                        Modular.to.pushNamed('/settings/plugin/');
                      },
                      leading: const Icon(Icons.extension),
                      title: const Text('规则管理'),
                      description: const Text('管理番剧资源规则'),
                    ),
                  ],
                ),
                SettingsSection(
                  title: const Text('播放器设置'),
                  tiles: [
                    SettingsTile.navigation(
                      onPressed: (_) {
                        Modular.to.pushNamed('/settings/player');
                      },
                      leading: const Icon(Icons.display_settings_rounded),
                      title: const Text('播放设置'),
                      description: const Text('设置播放器相关参数'),
                    ),
                    SettingsTile.navigation(
                      onPressed: (_) {
                        Modular.to.pushNamed('/settings/danmaku/');
                      },
                      leading: const Icon(Icons.subtitles_rounded),
                      title: const Text('弹幕设置'),
                      description: const Text('设置弹幕相关参数'),
                    ),
                  ],
                ),
                SettingsSection(
                  title: const Text('应用与外观'),
                  tiles: [
                    SettingsTile.navigation(
                      onPressed: (_) {
                        Modular.to.pushNamed('/settings/theme');
                      },
                      leading: const Icon(Icons.palette_rounded),
                      title: const Text('外观设置'),
                      description: const Text('设置应用主题和刷新率'),
                    ),
                    SettingsTile.navigation(
                      onPressed: (_) {
                        Modular.to.pushNamed('/settings/webdav/');
                      },
                      leading: const Icon(Icons.cloud),
                      title: const Text('同步设置'),
                      description: const Text('设置同步参数'),
                    ),
                  ],
                ),
                SettingsSection(
                  title: const Text('其他'),
                  tiles: [
                    SettingsTile.navigation(
                      leading: const Icon(Icons.exit_to_app),
                      title: const Text('退出设置'),
                      description: const Text('设置退出默认行为'),
                      value: Text(exitBehaviorTitles[exitBehavior]),
                      onPressed: (_) {
                        KazumiDialog.show(builder: (context) {
                          return SimpleDialog(
                            title: const Text('退出行为'),
                            children: [
                              for (int i = 0; i < 3; i++)
                                RadioListTile(
                                  value: i,
                                  groupValue: exitBehavior,
                                  onChanged: (int? value) {
                                    exitBehavior = value!;
                                    setting.put(
                                        SettingBoxKey.exitBehavior, value);
                                    Navigator.pop(context);
                                    setState(() {});
                                  },
                                  title: Text(exitBehaviorTitles[i]),
                                ),
                            ],
                          );
                        });
                      },
                    ),
                    SettingsTile.navigation(
                      onPressed: (_) {
                        Modular.to.pushNamed('/settings/about/');
                      },
                      leading: const Icon(Icons.info_outline_rounded),
                      title: const Text('关于'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
