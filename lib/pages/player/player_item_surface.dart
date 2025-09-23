import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/pages/player/player_controller.dart';

class PlayerItemSurface extends StatefulWidget {
  const PlayerItemSurface({super.key});

  @override
  State<PlayerItemSurface> createState() => _PlayerItemSurfaceState();
}

class _PlayerItemSurfaceState extends State<PlayerItemSurface> {
  final PlayerController playerController = Modular.get<PlayerController>();

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        return AspectRatio(
          aspectRatio: playerController.mediaPlayer!.value.aspectRatio,
          child: VideoPlayer(
            playerController.mediaPlayer!,
          ),
        );
      },
    );
  }
}
