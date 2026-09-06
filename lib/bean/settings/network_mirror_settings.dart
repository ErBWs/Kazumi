import 'package:flutter/material.dart';
import 'package:kazumi/bean/settings/settings_list.dart';

class NetworkMirrorSettings extends StatelessWidget {
  const NetworkMirrorSettings({
    super.key,
    required this.enableBangumiProxy,
    required this.enableGitProxy,
    required this.onBangumiChanged,
    required this.onGitChanged,
    this.margin,
  });

  final bool enableBangumiProxy;
  final bool enableGitProxy;
  final ValueChanged<bool> onBangumiChanged;
  final ValueChanged<bool> onGitChanged;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) => SettingsSection(
        title: const Text('访问加速'),
        margin: margin,
        tiles: [
          SettingsTile.switchTile(
            leading: Icons.travel_explore_rounded,
            title: const Text('Bangumi 镜像'),
            description: const Text('加速番剧信息、热门与时间表加载'),
            initialValue: enableBangumiProxy,
            onToggle: (value) => onBangumiChanged(value ?? !enableBangumiProxy),
          ),
          SettingsTile.switchTile(
            leading: Icons.extension_rounded,
            title: const Text('规则仓库镜像'),
            description: const Text('加速规则的下载与更新'),
            initialValue: enableGitProxy,
            onToggle: (value) => onGitChanged(value ?? !enableGitProxy),
          ),
        ],
      );
}
