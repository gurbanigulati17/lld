import 'package:flutter/widgets.dart';

/// Lets the app turn expensive backdrop blur off on weak devices or when the
/// platform asks for reduced motion. Glass widgets read this and fall back to
/// a flat tinted surface with the same geometry.
class GlassPerformance extends InheritedWidget {
  const GlassPerformance({
    super.key,
    required this.reducedEffects,
    required super.child,
  });

  final bool reducedEffects;

  static bool reducedOf(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<GlassPerformance>();
    if (w != null) return w.reducedEffects;
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  @override
  bool updateShouldNotify(GlassPerformance oldWidget) =>
      oldWidget.reducedEffects != reducedEffects;
}
