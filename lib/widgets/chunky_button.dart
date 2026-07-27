import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Prototipdagi 3D "chunky" tugma: radius + pastki qalin jant (darker shade).
/// CSS `border-bottom: Npx solid dark` → zero-blur BoxShadow(0, N).
/// Bosilganda tana pastga tushadi, jant yig'iladi.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.child,
    this.onPressed,
    this.color,
    this.darkColor,
    this.gradient,
    this.borderRadius = 22,
    this.ledge = 5,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
    this.minHeight,
    this.enabled = true,
    this.dimmed = false,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? darkColor;
  final Gradient? gradient;
  final double borderRadius;
  final double ledge;
  final EdgeInsets padding;
  final double? minHeight;
  final bool enabled;

  /// Boshqa javob tanlanganda opacity .55 holati.
  final bool dimmed;

  /// Screen reader uchun nom. Tugma mazmuni chizilgan shakl yoki ikonka
  /// bo'lsa (matn emas) MAJBURIY — aks holda TalkBack «tugma» deb o'qiydi.
  final String? semanticLabel;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.darkColor ??
        _darker(widget.color ?? widget.gradient?.colors.last ?? Colors.grey);
    final down = _pressed && widget.enabled && widget.onPressed != null;
    final shift = down ? widget.ledge : 0.0;

    final Widget button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled ? (_) => _setPressed(true) : null,
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.enabled
          ? () {
              HapticFeedback.lightImpact();
              widget.onPressed?.call();
            }
          : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: widget.dimmed ? 0.55 : 1,
        child: Padding(
          // Jant uchun joy — layout balandligi barqaror qoladi.
          padding: EdgeInsets.only(top: shift, bottom: widget.ledge - shift),
          child: Container(
            constraints: widget.minHeight != null
                ? BoxConstraints(minHeight: widget.minHeight!)
                : const BoxConstraints(),
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.gradient == null ? widget.color : null,
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: dark,
                  offset: Offset(0, widget.ledge - shift),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      child: button,
    );
  }

  static Color _darker(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.14).clamp(0.0, 1.0)).toColor();
  }
}
