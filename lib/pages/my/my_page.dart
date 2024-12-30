import 'package:card_settings_ui/card_settings_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/appbar/sys_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:kazumi/pages/menu/menu.dart';
import 'package:kazumi/pages/menu/side_menu.dart';
import 'package:kazumi/utils/utils.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
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
      onPopInvoked: (bool didPop) {
        if (didPop) {
          return;
        }
        onBackPressed(context);
      },
      child: Scaffold(
        appBar: const SysAppBar(title: Text('我的')),
        body: Center(
          child: SizedBox(
            width: (MediaQuery.of(context).size.width > 800) ? 800 : null,
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
                    ),
                    SettingsTile.navigation(
                      onPressed: (_) {
                        Modular.to.pushNamed('/settings/plugin/');
                      },
                      leading: const Icon(Icons.rule_folder_rounded),
                      title: const Text('规则管理'),
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
                    ),
                    SettingsTile.navigation(
                      onPressed: (_) {
                        Modular.to.pushNamed('/settings/danmaku/');
                      },
                      leading: const Icon(Icons.subtitles_rounded),
                      title: const Text('弹幕设置'),
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
                      // trailing: const Icon(Icons.navigate_next),
                    ),
                    SettingsTile.navigation(
                      onPressed: (_) {
                        Modular.to.pushNamed('/settings/webdav/');
                      },
                      leading: const Icon(Icons.cloud_circle_rounded),
                      title: const Text('同步设置'),
                    ),
                  ],
                ),
                SettingsSection(
                  title: const Text('其他'),
                  tiles: [
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
