// The gallery's own layout values: page widths and specimen frames. Shared
// design values come from bb_tokens; only what is particular to these
// specimen pages lives here.

/// How wide a specimen page's column grows.
abstract final class PageWidths {
  static const double narrow = 640;
  static const double standard = 880;
  static const double wide = 960;
}

/// Fixed frames that hold a specimen at a readable size.
abstract final class Specimen {
  /// A button shown at a fixed width to show how it fills it.
  static const double buttonWidth = 120;

  /// A swatch of a semantic colour.
  static const double swatchWidth = 128;

  /// A larger checkbox, to show the box scales.
  static const double checkbox = 32;

  /// A smaller QR frame.
  static const double qr = 168;

  /// A column of device or pairing specimens.
  static const double column = 400;

  /// Stage heights for the palette, search and session specimens.
  static const double palette = 440,
      paletteShort = 160,
      paletteTiny = 120,
      search = 460,
      strip = 140;

  /// Toast and notice widths in the session specimens.
  static const double toast = 440;

  /// The device list takes three parts of the row, the detail two.
  static const listFlex = 3, detailFlex = 2;

  /// A one-time code is two groups of four characters.
  static const codeGroups = [4, 4];

  /// The flat search list shows this many samples.
  static const flatSamples = 3;

  /// A toast's progress in the still specimen.
  static const toastProgress = .6;
}
