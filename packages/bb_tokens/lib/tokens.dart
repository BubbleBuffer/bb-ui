// Approved Stacks tokens plus the app-wide type scale and bundled fonts.
// Every colour comes from `src/colors.g.dart`, generated from the agent-kit
// profile of the BubbleBuffer design repository (packages/bb_tokens/README.md).
// No Material anywhere: this is the only theme the widgets read.

import 'package:flutter/widgets.dart';

import 'src/colors.g.dart';

export 'src/colors.g.dart';

/// Bundled fonts used identically on every platform and in golden tests.
String sansFamily = 'Atkinson Hyperlegible Next';
String monoFamily = 'Fragment Mono';
String displayFamily = 'Bricolage Grotesque';
const monoFallback = ['monospace'];

/// Fully transparent. `Colors.transparent` is Material, which the kit avoids.
const kTransparent = Color(0x00000000);

/// An opaque colour for alpha masks, where only the alpha channel matters.
const kMaskOpaque = Color(0xFF000000);

/// Quiet space colours shared by the tree, agenda and checklist progress.
const spaceColorNames = ['apricot', 'paw', 'moss', 'duvet', 'sun', 'sky'];
Color? spaceColor(String? name, Brightness brightness) {
  final p = brightness == Brightness.dark
      ? ProfileColors.dark
      : ProfileColors.light;
  return switch (name) {
    'apricot' => p.spaceApricot,
    'paw' => p.spacePaw,
    'moss' => p.spaceMoss,
    'duvet' => p.spaceDuvet,
    'sun' => p.spaceSun,
    'sky' => p.spaceSky,
    _ => null,
  };
}

/// Opaque edge/tile colours; the quiet dot/pill palette above stays separate.
class SpacePatch {
  const SpacePatch(this.fill, this.deep, this.ink);
  final Color fill, deep, ink;

  Color get hover => Color.alphaBlend(ink.withValues(alpha: .12), fill);

  /// Moss keeps its original backing behind title/glyphs on hover.
  Color get hoverTextBacking =>
      fill == ProfileColors.light.spacePatchMossFill ? fill : hover;
}

SpacePatch? spacePatch(
  String? name,
  Brightness brightness, {
  bool rail = false,
}) {
  final dark = brightness == Brightness.dark || (rail && name == 'duvet');
  final p = dark ? ProfileColors.dark : ProfileColors.light;
  return switch (name) {
    'apricot' => SpacePatch(
      p.spacePatchApricotFill,
      p.spacePatchApricotDeep,
      p.spacePatchApricotInk,
    ),
    'paw' => SpacePatch(
      p.spacePatchPawFill,
      p.spacePatchPawDeep,
      p.spacePatchPawInk,
    ),
    'moss' => SpacePatch(
      p.spacePatchMossFill,
      p.spacePatchMossDeep,
      p.spacePatchMossInk,
    ),
    'duvet' => SpacePatch(
      p.spacePatchDuvetFill,
      p.spacePatchDuvetDeep,
      p.spacePatchDuvetInk,
    ),
    'sun' => SpacePatch(
      p.spacePatchSunFill,
      p.spacePatchSunDeep,
      p.spacePatchSunInk,
    ),
    'sky' => SpacePatch(
      p.spacePatchSkyFill,
      p.spacePatchSkyDeep,
      p.spacePatchSkyInk,
    ),
    _ => null,
  };
}

class AppColors {
  const AppColors({
    required this.dark,
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgTertiary,
    required this.bgElevated,
    required this.bgHover,
    required this.bgPressed,
    required this.bgSelectedBlock,
    required this.textSelection,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.iconPrimary,
    required this.iconSecondary,
    required this.iconTertiary,
    required this.border,
    required this.borderSubtle,
    required this.borderStrong,
    required this.borderTranslucent,
    required this.divider,
    required this.accent,
    required this.accentHover,
    required this.inlineCodeBg,
    required this.inlineCodeText,
    required this.overlay,
    required this.desk,
    required this.accentText,
    required this.onAccent,
    required this.focus,
    required this.thread,
    required this.threadStrong,
    required this.okBg,
    required this.infoBg,
    required this.attnBg,
    required this.dangerBg,
    required this.pawBg,
    required this.rail,
    required this.rail2,
    required this.railInk,
    required this.railMuted,
    required this.railLine,
    required this.seam,
    required this.seamHover,
    required this.stack,
    ProfileColors? palette,
  }) : palette = palette ?? (dark ? ProfileColors.dark : ProfileColors.light);

  /// Every role of the agent-kit profile, including the ones below that
  /// have no field of their own (status, diff, context and control colours).
  final ProfileColors palette;
  final bool dark;
  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgTertiary;
  final Color bgElevated;
  final Color bgHover;
  final Color bgPressed;
  final Color bgSelectedBlock;
  final Color textSelection;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color iconPrimary;
  final Color iconSecondary;
  final Color iconTertiary;
  final Color border;
  final Color borderSubtle;
  final Color borderStrong;
  final Color borderTranslucent;
  final Color divider;
  final Color accent;
  final Color accentHover;
  final Color inlineCodeBg;
  final Color inlineCodeText;
  final Color overlay;
  final Color desk;
  final Color accentText;
  final Color onAccent;
  final Color focus;
  final Color thread;
  final Color threadStrong;
  final Color okBg;
  final Color infoBg;
  final Color attnBg;
  final Color dangerBg;
  final Color pawBg;
  final Color rail;
  final Color rail2;
  final Color railInk;
  final Color railMuted;
  final Color railLine;
  final List<BoxShadow> seam, seamHover, stack;
  // Compatibility for screens that still refer to the old shadow names.
  List<BoxShadow> get shadowMenu => seamHover;
  List<BoxShadow> get shadowSmall => seam;

  static final light = _appColors(ProfileColors.light, dark: false);

  static final darkTheme = _appColors(ProfileColors.dark, dark: true);
}

/// Scratch's field names over the generated palette.
AppColors _appColors(ProfileColors p, {required bool dark}) => AppColors(
  dark: dark,
  palette: p,
  bgPrimary: p.surface,
  bgSecondary: p.surface2,
  bgTertiary: p.desk,
  bgElevated: p.raised,
  bgHover: p.hover,
  bgPressed: p.pressed,
  bgSelectedBlock: p.selected,
  textSelection: p.selection,
  textPrimary: p.ink,
  textSecondary: p.muted,
  textTertiary: p.faint,
  textDisabled: p.disabled,
  iconPrimary: p.ink,
  iconSecondary: p.icon,
  iconTertiary: p.iconFaint,
  border: p.seam,
  borderSubtle: p.seamSubtle,
  borderStrong: p.seamStrong,
  borderTranslucent: p.seam,
  divider: p.seam,
  accent: p.accent,
  accentHover: p.accentHover,
  inlineCodeBg: p.codeBg,
  inlineCodeText: p.codeInk,
  overlay: p.scrim,
  desk: p.desk,
  accentText: p.accentInk,
  onAccent: p.onAccent,
  focus: p.focus,
  thread: p.thread,
  threadStrong: p.threadStrong,
  okBg: p.constructive,
  infoBg: p.information,
  attnBg: p.attention,
  dangerBg: p.danger,
  pawBg: p.pawTint,
  rail: p.scratchRail,
  rail2: p.scratchRail2,
  railInk: p.scratchRailInk,
  railMuted: p.scratchRailMuted,
  railLine: p.scratchRailLine,
  seam: p.shadow,
  seamHover: p.shadowHover,
  stack: p.shadowStack,
);

// ---------------------------------------------------------------------------
// Scales. Widgets never write a number for spacing, size, type, stroke,
// opacity or timing: they pick a step from one of these. The bb_lints
// analyzer plugin enforces it (packages/bb_lints).
// ---------------------------------------------------------------------------

/// The spacing scale: every gap, padding, margin and inset is one step.
///
/// Gaps between siblings use `Row`/`Column` `spacing:` or bb_ui's `Gap`.
abstract final class Space {
  static const double hair = 2;
  static const double xxs = 4;
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Every step, smallest first.
  static const steps = [hair, xxs, xs, sm, md, lg, xl, xxl, xxxl];
}

/// Heights of controls: buttons, fields, rows and chips.
enum ControlSize {
  xs(24),
  sm(28),
  md(32),
  lg(36),
  xl(44),
  xxl(48);

  const ControlSize(this.height);

  /// The control's height in logical pixels.
  final double height;
}

/// Icon sizes. Lucide picks a stroke weight per size, so line weight stays
/// even across steps.
enum IconSize {
  xs(14),
  sm(16),
  md(18),
  lg(20),
  xl(24),

  /// The mark of an empty state.
  xxl(28);

  const IconSize(this.px);

  /// The glyph box in logical pixels.
  final double px;
}

/// Line widths for borders, rules and painted strokes.
abstract final class Stroke {
  static const double hair = 1;
  static const double regular = 1.5;
  static const double bold = 2;
  static const double seam = 3;
}

/// Opacity steps for a colour laid over another.
abstract final class Alpha {
  /// A faint wash, for example a hover tint over a patch.
  static const double tint = .12;

  /// A visible but quiet ring or fill.
  static const double wash = .35;

  /// Half strength, for example a disabled or danger border.
  static const double muted = .5;

  /// Nearly opaque, for example a pressed fill.
  static const double strong = .9;
}

/// Widths of floating, side and centred surfaces.
abstract final class Widths {
  static const double popover = 220;
  static const double menu = 260;
  static const double tooltip = 280;
  static const double panel = 280;
  static const double dialog = 320;
  static const double picker = 340;
  static const double notice = 360;
  static const double form = 420;
  static const double sheet = 480;
  static const double palette = 560;
  static const double content = 720;
}

/// Heights of bounded surfaces.
abstract final class Heights {
  /// A scrolling list inside a sheet or popover.
  static const double list = 360;

  /// A centred dialog's largest height.
  static const double dialog = 640;

  /// The shortest a centred dialog gets on a small screen.
  static const double dialogMin = 200;
}

/// Fixed sizes of small components: marks, tiles, handles and frames.
abstract final class Sizes {
  /// A status or legend dot.
  static const double dot = 8;

  /// A marker bullet in a list, and the bar-shaped marker beside it.
  static const double bullet = 8, barWidth = 4, barHeight = 12;

  /// A card's coloured leading edge.
  static const double edge = 4;

  /// The task checkbox.
  static const double checkbox = 22;

  /// A square icon tile at the start of a row.
  static const double tile = 40;

  /// A small icon tile, such as a notice's icon.
  static const double tileSmall = 36;

  /// The round mark above an empty state.
  static const double emptyMark = 56;

  /// A pill-shaped label's height.
  static const double pill = 20;

  /// The switch track and its thumb.
  static const double switchWidth = 30, switchHeight = 18, switchThumb = 14;

  /// The grab handle at the top of a bottom sheet.
  static const double grabWidth = 36, grabHeight = 4;

  /// The label column of a key/value row.
  static const double labelColumn = 88;

  /// The frame a QR code sits in, and the quiet margin a QR code needs
  /// around its modules as a share of the frame.
  static const double qr = 200, qrQuietZone = 1 / 12;

  /// A sparkline's height.
  static const double sparkline = 24;

  /// A short vertical rule between toolbar items.
  static const double rule = 20;

  /// A text selection handle's radius.
  static const double selectionHandle = 7;

  /// How far a focus ring sits outside its control.
  static const double focusGap = 3;

  /// A display picker's preview of the screen arrangement.
  static const double displayMap = 124;
}

/// A font weight from the type ramp.
enum Weight {
  regular(FontWeight.w400, 400),
  medium(FontWeight.w500, 500),
  semibold(FontWeight.w600, 600),

  /// The display face's condensed title weight.
  display(FontWeight.w600, 640),
  bold(FontWeight.w700, 700);

  const Weight(this.fontWeight, this.axis);

  /// The nearest static weight, for faces without a weight axis.
  final FontWeight fontWeight;

  /// The value of a variable font's `wght` axis.
  final double axis;
}

/// One entry of the type scale: size and line height in logical px, weight.
/// Only [TypeScale] makes them; widgets pick a role from `context.type`.
class TypeSpec {
  const TypeSpec._(this.size, this.line, this.weight);
  final double size, line;
  final Weight weight;
}

/// The type ramp. [pointer] is for mouse and trackpad, [touch] for fingers;
/// `AppTheme` picks one from its [Density].
class TypeScale {
  const TypeScale._({
    required this.pageTitle,
    required this.display,
    required this.h1,
    required this.h2,
    required this.h3,
    required this.title,
    required this.body,
    required this.item,
    required this.ui,
    required this.uiSmall,
    required this.caption,
    required this.micro,
    required this.code,
    required this.codeSmall,
  });

  /// The page's name above everything else.
  final TypeSpec pageTitle;

  /// A large name in the display face, such as a selected item's title.
  final TypeSpec display;

  /// Section headings, largest first.
  final TypeSpec h1, h2, h3;

  /// The name on a row or card.
  final TypeSpec title;

  /// Running text.
  final TypeSpec body;

  /// A row in a menu, list or setting: [ui] with a pointer, [body] by touch.
  final TypeSpec item;

  /// Labels on controls.
  final TypeSpec ui;

  /// Secondary labels and descriptions.
  final TypeSpec uiSmall;

  /// Fine print: metrics, counts and timestamps.
  final TypeSpec caption;

  /// Badges and eyebrows inside small marks.
  final TypeSpec micro;

  /// Monospace for code and identifiers.
  final TypeSpec code, codeSmall;

  static const pointer = TypeScale._(
    pageTitle: TypeSpec._(40, 48, Weight.bold),
    display: TypeSpec._(32, 34, Weight.bold),
    h1: TypeSpec._(30, 39, Weight.semibold),
    h2: TypeSpec._(24, 31.2, Weight.semibold),
    h3: TypeSpec._(20, 26, Weight.semibold),
    title: TypeSpec._(16, 20, Weight.display),
    body: TypeSpec._(16, 24, Weight.regular),
    item: TypeSpec._(14, 20, Weight.medium),
    ui: TypeSpec._(14, 20, Weight.medium),
    uiSmall: TypeSpec._(12, 16, Weight.medium),
    caption: TypeSpec._(11, 15, Weight.regular),
    micro: TypeSpec._(10, 12, Weight.semibold),
    code: TypeSpec._(13.6, 20.4, Weight.regular),
    codeSmall: TypeSpec._(12, 16, Weight.regular),
  );

  static const touch = TypeScale._(
    pageTitle: TypeSpec._(28, 33.6, Weight.bold),
    display: TypeSpec._(28, 32, Weight.bold),
    h1: TypeSpec._(24, 31.2, Weight.semibold),
    h2: TypeSpec._(20, 26, Weight.semibold),
    h3: TypeSpec._(18, 23.4, Weight.semibold),
    title: TypeSpec._(16, 20, Weight.display),
    body: TypeSpec._(16, 22, Weight.regular),
    item: TypeSpec._(16, 22, Weight.medium),
    ui: TypeSpec._(15, 20, Weight.medium),
    uiSmall: TypeSpec._(13, 16, Weight.medium),
    caption: TypeSpec._(11, 15, Weight.regular),
    micro: TypeSpec._(10, 12, Weight.semibold),
    code: TypeSpec._(13.6, 20.4, Weight.regular),
    codeSmall: TypeSpec._(12, 16, Weight.regular),
  );
}

/// Large monospace numerals for codes people type in elsewhere ([md]) or
/// compare at a glance ([lg]).
enum NumeralSize {
  md(TypeSpec._(22, 25.3, Weight.regular)),
  lg(TypeSpec._(44, 50.6, Weight.regular));

  const NumeralSize(this.spec);
  final TypeSpec spec;
}

/// The monospace style for numerals of [size], slightly tracked out.
TextStyle tsNumeral(NumeralSize size, Color color) => ts(
  size.spec,
  color,
  mono: true,
).copyWith(letterSpacing: _numeralTracking * size.spec.size);

const _numeralTracking = .04;

/// The body text style for [s] in [color]. [weight] overrides the role's.
TextStyle ts(TypeSpec s, Color color, {Weight? weight, bool mono = false}) =>
    TextStyle(
      inherit: false,
      fontFamily: mono ? monoFamily : sansFamily,
      // Fragment Mono supplies symbols missing from the bundled body font.
      fontFamilyFallback: mono ? monoFallback : [monoFamily],
      fontSize: s.size,
      height: s.line / s.size,
      leadingDistribution: TextLeadingDistribution.even,
      fontWeight: (weight ?? s.weight).fontWeight,
      color: color,
      decoration: TextDecoration.none,
    );

/// Display typography, with the condensed variable axes of the display face.
TextStyle tsDisplay(TypeSpec s, Color color, {Weight weight = Weight.display}) {
  return ts(s, color, weight: weight).copyWith(
    fontFamily: displayFamily,
    fontVariations: [
      FontVariation('opsz', s.size.clamp(_opszMin, _opszMax)),
      const FontVariation('wdth', _displayWidth),
      FontVariation('wght', weight.axis),
    ],
    letterSpacing: _displayTracking * s.size,
  );
}

const _opszMin = 12.0, _opszMax = 96.0, _displayWidth = 90.0;
const _displayTracking = -.03;

class Layout {
  static const contentWidth = Widths.content;
  static const textWidth = 708.0;
  static const blockPaddingX = Space.hair;
  static const blockRowGap = Space.hair;
  static const textBlockHeight = 28.0;
  static const topbarHeight = 44.0;
  static const sidebarWidth = 240.0;
  static const sidebarRowHeight = 30.0;
  static const handleOffset = -44.0;

  /// Side padding of a full-width page or list on a compact screen.
  static const gutter = Space.lg;
  static const keyboardToolbarHeight = 44.0;
  static const minTapTarget = 44.0;
  static const listRowHeight = 44.0;
  static const indent = Space.xl;

  /// Shares of the window a floating surface takes: the command palette's
  /// distance from the top and its largest height, and a bottom sheet's
  /// largest height.
  static const paletteTop = .14, paletteHeight = .6, sheetHeight = .85;
}

class Radii {
  static const sm = 4.0, md = 6.0, lg = 10.0, sheet = 12.0;
  static const ctl = BorderRadius.only(
    topLeft: Radius.circular(7),
    topRight: Radius.circular(11),
    bottomRight: Radius.circular(6),
    bottomLeft: Radius.circular(9),
  );
  static const field = BorderRadius.only(
    topLeft: Radius.circular(6),
    topRight: Radius.circular(10),
    bottomRight: Radius.circular(6),
    bottomLeft: Radius.circular(8),
  );
  static const panel = BorderRadius.only(
    topLeft: Radius.circular(12),
    topRight: Radius.circular(18),
    bottomRight: Radius.circular(10),
    bottomLeft: Radius.circular(16),
  );
  static const pill = BorderRadius.all(Radius.circular(999));

  /// A uniform corner of [sm], [md], [lg] or [sheet].
  static BorderRadius all(double r) => BorderRadius.all(Radius.circular(r));
}

class Motion {
  static const fast = Duration(milliseconds: 150);
  static const standard = Duration(milliseconds: 220);
  static const sheet = Duration(milliseconds: 250);
  static const wiggle = Duration(milliseconds: 200);

  /// How long a pointer rests on a control before its tooltip shows.
  static const hoverDelay = Duration(milliseconds: 500);

  /// How long a tooltip stays after a long press ends.
  static const linger = Duration(milliseconds: 1500);

  /// How long a confirmation such as "Copied" replaces a label.
  static const confirm = Duration(seconds: 2);

  /// How long a toast stays before it dismisses itself.
  static const toast = Duration(seconds: 4);

  /// After a tooltip hides, how long the next one shows without the delay.
  static const warm = Duration(milliseconds: 300);

  /// One turn of a spinner.
  static const spin = Duration(milliseconds: 900);

  static const ease = Cubic(.2, .8, .2, 1);
  static const settle = Cubic(.22, 1.25, .36, 1);
  static const easing = ease;
  static MotionDurations of(BuildContext context) =>
      MotionDurations(MediaQuery.disableAnimationsOf(context));
}

class MotionDurations {
  const MotionDurations(this.reduced);
  final bool reduced;
  Duration get fast => reduced ? Duration.zero : Motion.fast;
  Duration get standard => reduced ? Duration.zero : Motion.standard;
  Duration get sheet => reduced ? Duration.zero : Motion.sheet;
  Duration get wiggle => reduced ? Duration.zero : Motion.wiggle;
}

// ---------------------------------------------------------------------------
// Adapting. Two independent questions replace the old desktop/mobile switch:
// how the user points (Density, set by the host) and how much room a widget
// has (SizeClass, from the nearest SizeClassScope or else the window).
// ---------------------------------------------------------------------------

/// How the user points. It sets control heights, icon sizes, row padding and
/// the type ramp, not the layout.
enum Density {
  pointer,
  touch;

  /// Touch on phones and tablets, pointer elsewhere.
  static Density forPlatform(TargetPlatform platform) => switch (platform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.fuchsia => touch,
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => pointer,
  };

  Metrics get metrics => this == touch ? Metrics.touch : Metrics.pointer;
  TypeScale get type => this == touch ? TypeScale.touch : TypeScale.pointer;
}

/// Sizes that follow [Density]. Read them with `context.metrics`.
class Metrics {
  const Metrics._({
    required this.row,
    required this.listRow,
    required this.tallRow,
    required this.field,
    required this.control,
    required this.target,
    required this.icon,
    required this.iconSmall,
    required this.iconGap,
    required this.padX,
    required this.insetX,
  });

  static const pointer = Metrics._(
    row: ControlSize.sm,
    listRow: ControlSize.lg,
    tallRow: 64,
    field: ControlSize.md,
    control: ControlSize.md,
    target: ControlSize.xs,
    icon: IconSize.lg,
    iconSmall: IconSize.sm,
    iconGap: Space.sm,
    padX: Space.sm,
    insetX: Space.sm,
  );

  static const touch = Metrics._(
    row: ControlSize.xl,
    listRow: ControlSize.xl,
    tallRow: 72,
    field: ControlSize.xl,
    control: ControlSize.xl,
    target: ControlSize.xl,
    icon: IconSize.xl,
    iconSmall: IconSize.lg,
    iconGap: Space.md,
    padX: Space.md,
    insetX: Space.lg,
  );

  /// A menu row.
  final ControlSize row;

  /// A row in a long list such as the command palette.
  final ControlSize listRow;

  /// A two-line row: a title over a detail line.
  final double tallRow;

  /// A text or search field.
  final ControlSize field;

  /// A button in a dialog or form.
  final ControlSize control;

  /// The smallest hit area of a tappable thing.
  final ControlSize target;

  /// A row's leading icon, and a smaller one for fields and chips.
  final IconSize icon, iconSmall;

  /// Between an icon and its label.
  final double iconGap;

  /// Inside a control, left and right.
  final double padX;

  /// A row's inset from the edge of its list.
  final double insetX;
}

/// How much room there is: compact (phone, narrow pane), medium, expanded.
enum SizeClass {
  compact,
  medium,
  expanded;

  /// The narrowest medium width.
  static const mediumWidth = 600.0;

  /// The narrowest expanded width.
  static const expandedWidth = 1000.0;

  static SizeClass forWidth(double width) => width < mediumWidth
      ? compact
      : width < expandedWidth
      ? medium
      : expanded;

  bool get isCompact => this == compact;

  /// Whether this class is [other] or wider.
  bool atLeast(SizeClass other) => index >= other.index;
}

/// Sets the [SizeClass] below it. The app puts one at the root from the
/// window; a pane can put its own from its constraints (bb_ui's
/// `AdaptiveLayout` does).
class SizeClassScope extends InheritedWidget {
  const SizeClassScope({
    super.key,
    required this.sizeClass,
    required super.child,
  });

  final SizeClass sizeClass;

  /// The nearest scope's class, or the window's when there is none.
  static SizeClass of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SizeClassScope>()?.sizeClass ??
      SizeClass.forWidth(MediaQuery.sizeOf(context).width);

  @override
  bool updateShouldNotify(SizeClassScope old) => old.sizeClass != sizeClass;
}

class AppTheme extends InheritedWidget {
  const AppTheme({
    super.key,
    required this.colors,
    required this.density,
    required super.child,
  });
  final AppColors colors;
  final Density density;

  TypeScale get type => density.type;
  Metrics get metrics => density.metrics;

  static AppTheme of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppTheme>()!;

  @override
  bool updateShouldNotify(AppTheme old) =>
      old.colors != colors || old.density != density;
}

extension ThemeX on BuildContext {
  AppColors get colors => AppTheme.of(this).colors;
  TypeScale get type => AppTheme.of(this).type;
  Density get density => AppTheme.of(this).density;
  Metrics get metrics => AppTheme.of(this).metrics;
  bool get touch => density == Density.touch;
  SizeClass get sizeClass => SizeClassScope.of(this);

  /// The window's class, whatever pane this context is in. Overlays and app
  /// chrome follow it: whether a menu opens as a sheet or a popover, whether
  /// the command palette fills the screen. Content inside a pane follows
  /// [sizeClass].
  SizeClass get windowSizeClass =>
      SizeClass.forWidth(MediaQuery.sizeOf(this).width);

  /// The value for the current [SizeClass]; a missing class takes the next
  /// narrower one that is given.
  T adaptive<T>({required T compact, T? medium, T? expanded}) =>
      switch (sizeClass) {
        SizeClass.compact => compact,
        SizeClass.medium => medium ?? compact,
        SizeClass.expanded => expanded ?? medium ?? compact,
      };
}

// ---------------------------------------------------------------------------
// Agent kit tokens: the values of the approved Scratch-skin mockup's
// `theme.css` that the shared scales above do not have.
// ---------------------------------------------------------------------------

/// Sizes of the agent kit (`--fit-composer`, `--pane-min-*`, `--edge-tab`,
/// `--ctl-h`, `--row` in `theme.css`). Breakpoints are [SizeClass]'s.
class KitLayout {
  const KitLayout({
    this.fitComposer = 460,
    this.contextSplit = 680,
    this.paneMinWidth = 200,
    this.paneMinHeight = 120,
    this.edgeTab = 28,
    this.controlHeight = 32,
    this.rowHeight = 28,
  });

  /// The values of `theme.css`.
  static const standard = KitLayout();

  /// Composer width below which Stop and Send drop their labels.
  final double fitComposer;

  /// Context pane width from which a summary's detail sits beside the list
  /// instead of replacing it.
  final double contextSplit;

  /// A workspace pane never renders narrower than this.
  final double paneMinWidth;

  /// A workspace pane never renders shorter than this.
  final double paneMinHeight;

  /// Width of a collapsed pane's edge tab.
  final double edgeTab;

  /// Height of the agent's buttons (`--ctl-h`).
  final double controlHeight;

  /// Height of a list row (`--row`).
  final double rowHeight;
}

/// Motion beyond [Motion]'s.
class KitMotion {
  const KitMotion({this.breathe = const Duration(milliseconds: 2400)});

  static const standard = KitMotion();

  /// One cycle of the running mark's breathing loop (`--breathe`).
  final Duration breathe;
}

/// Text colours for the state roles. Scratch has only fills for them
/// (`okBg`, `dangerBg`, ...); these are the inks the mockup chose:
/// constructive and danger from the edit-row counts in Scratch's
/// `agent_turn.dart`, attention from `accentText` (light) or the attention
/// hue at full strength (dark, 5.3:1 on the 20% fill).
class KitInks {
  const KitInks({
    required this.constructive,
    required this.danger,
    required this.attention,
  });

  static final light = KitInks(
    constructive: ProfileColors.light.constructiveInk,
    danger: ProfileColors.light.dangerInk,
    attention: ProfileColors.light.attentionInk,
  );

  static final dark = KitInks(
    constructive: ProfileColors.dark.constructiveInk,
    danger: ProfileColors.dark.dangerInk,
    attention: ProfileColors.dark.attentionInk,
  );

  /// The inks that go with [colors].
  static KitInks of(AppColors colors) => colors.dark ? dark : light;

  final Color constructive, danger, attention;
}
