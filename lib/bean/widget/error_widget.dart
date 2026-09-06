import 'package:flutter/material.dart';
import 'package:material_new_shapes/material_new_shapes.dart';

/// Shrink-wraps in slivers and scrolls within bounded page or media surfaces.
class GeneralErrorWidget extends StatelessWidget {
  const GeneralErrorWidget({
    required this.errMsg,
    this.title = '出了点问题',
    this.icon = Icons.error_outline_rounded,
    this.onRetry,
    this.retryText = '重试',
    this.actions = const [],
    this.compact = false,
    super.key,
  });

  final String title;
  final String errMsg;
  final IconData icon;
  final VoidCallback? onRetry;
  final String retryText;
  final List<Widget> actions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final errorActions = [
      if (onRetry != null)
        GeneralErrorButton(
          onPressed: onRetry,
          text: retryText,
          icon: Icons.refresh_rounded,
        ),
      ...actions,
    ];

    return Center(
      child: SingleChildScrollView(
        primary: false,
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: ClipPath(
                  clipper: const _ErrorShapeClipper(),
                  child: ColoredBox(
                    color: colors.errorContainer,
                    child: SizedBox.square(
                      dimension: compact ? 48 : 80,
                      child: Icon(icon,
                          size: compact ? 24 : 36,
                          color: colors.onErrorContainer),
                    ),
                  ),
                ),
              ),
              SizedBox(height: compact ? 16 : 24),
              Semantics(
                liveRegion: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: (compact
                                ? theme.textTheme.titleMedium
                                : theme.textTheme.headlineSmall)
                            ?.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (errMsg.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        errMsg,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              if (errorActions.isNotEmpty) ...[
                SizedBox(height: compact ? 16 : 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: errorActions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorShapeClipper extends CustomClipper<Path> {
  const _ErrorShapeClipper();

  static final _path = MaterialShapes.cookie4Sided.toPath();

  @override
  Path getClip(Size size) => _path
      .transform(Matrix4.diagonal3Values(size.width, size.height, 1).storage);

  @override
  bool shouldReclip(_ErrorShapeClipper oldClipper) => false;
}

class GeneralErrorButton extends StatelessWidget {
  const GeneralErrorButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
  }) : _tonal = false;

  const GeneralErrorButton.tonal({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
  }) : _tonal = true;

  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final bool _tonal;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(64, 48)),
      padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
      shape: WidgetStateProperty.resolveWith((states) => RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                states.contains(WidgetState.pressed) ? 16 : 28),
          )),
      animationDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 200),
    );
    final button = _tonal ? FilledButton.tonalIcon : FilledButton.icon;
    return button(
      onPressed: onPressed,
      style: style,
      icon: icon == null ? null : Icon(icon, size: 20),
      label: Text(text, textAlign: TextAlign.center),
    );
  }
}
