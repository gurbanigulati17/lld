/// Liquid-glass design system for TaxOS.
///
/// Surfaces are translucent, refract the animated backdrop behind them,
/// carry a soft specular highlight along the top edge and a gradient hairline
/// border. Every control degrades to a flat tinted surface when
/// [GlassPerformance.reducedEffects] is set, so low-end Android devices keep
/// 60fps.
library;

export 'src/glass_amount_field.dart';
export 'src/glass_button.dart';
export 'src/glass_chip.dart';
export 'src/glass_nav_bar.dart';
export 'src/glass_panel.dart';
export 'src/glass_performance.dart';
export 'src/glass_scaffold.dart';
export 'src/glass_segmented.dart';
export 'src/glass_stat.dart';
export 'src/glass_text_field.dart';
export 'src/glass_theme.dart';
export 'src/liquid_background.dart';
