import 'package:flutter/material.dart';
import 'package:kazumi/pages/onboarding/onboarding_step_layout.dart';
import 'package:kazumi/pages/plugin_editor/plugin_catalog_view.dart';
import 'package:kazumi/plugins/plugins_controller.dart';

class PluginShopStep extends StatelessWidget {
  const PluginShopStep({
    super.key,
    required this.controller,
  });

  final PluginsController controller;

  @override
  Widget build(BuildContext context) => PluginCatalogView.onboarding(
        controller: controller,
        builder: (context, slivers) => OnboardingStepLayout.slivers(
          leading: const OnboardingStepIcon(
            icon: Icons.extension_rounded,
            shape: OnboardingIconShape.flower,
          ),
          title: '发现更多番剧来源',
          subtitle: '添加喜欢的规则，拓展搜索来源。也可以先开始使用，稍后在规则管理中添加。',
          slivers: slivers,
        ),
      );
}
