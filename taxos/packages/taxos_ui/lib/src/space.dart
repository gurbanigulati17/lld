/// One spacing scale for the whole app, so every edge lines up.
///
/// * [gutter]: left and right page margin on every screen.
/// * [card]: inner padding of every card; label bars and figures inside a
///   card share this inset.
/// * [gap]: between sibling cards and rows.
/// * [section]: between a section and the next heading.
abstract final class Space {
  static const double gutter = 20;
  static const double card = 16;
  static const double gap = 12;
  static const double section = 24;
  static const double xs = 4;
  static const double sm = 8;
}
