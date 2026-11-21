// Vendored from BubbleBuffer/BubbleBufferDesign@6ef16db0e7ebefb6c17a3d680ca875ecfd100667 with: node plugins/bubblebuffer-design/skills/bubblebuffer-design-system/scripts/generate-design-tokens.mjs --dart <this file>
// GENERATED CODE, DO NOT EDIT.
//
// Source: plugins/bubblebuffer-design/assets/design-system/tokens.json and plugins/bubblebuffer-design/assets/design-system/product-profiles.json.
// Regenerate: npm run design:generate in BubbleBuffer/BubbleBufferDesign (plugins/bubblebuffer-design/skills/bubblebuffer-design-system/scripts/generate-design-tokens.mjs).

// dart format off

import 'package:flutter/widgets.dart';

/// The resolved light or dark palette of a profile with `roles`.
///
/// Role names are the profile's. Shadow roles are lists of [BoxShadow];
/// every other role is a [Color], translucent where the profile says so.
@immutable
class ProfileColors {
  const ProfileColors({
    required this.desk,
    required this.raised,
    required this.paper,
    required this.surface,
    required this.surface2,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.disabled,
    required this.icon,
    required this.iconFaint,
    required this.accent,
    required this.accentHover,
    required this.accentText,
    required this.accentInk,
    required this.focus,
    required this.focusKeyline,
    required this.seam,
    required this.seamSubtle,
    required this.seamStrong,
    required this.thread,
    required this.threadStrong,
    required this.hover,
    required this.pressed,
    required this.selected,
    required this.selection,
    required this.constructive,
    required this.information,
    required this.attention,
    required this.danger,
    required this.pawTint,
    required this.constructiveInk,
    required this.informationInk,
    required this.attentionInk,
    required this.dangerInk,
    required this.diffAdd,
    required this.diffAddInk,
    required this.diffDel,
    required this.diffDelInk,
    required this.codeBg,
    required this.codeInk,
    required this.scrim,
    required this.lift,
    required this.thumb,
    required this.switchOff,
    required this.knob,
    required this.shadow,
    required this.shadowHover,
    required this.shadowStack,
    required this.statusNeedsYouBg,
    required this.statusNeedsYouInk,
    required this.statusNeedsYouLine,
    required this.statusNeedsYouMark,
    required this.statusRunningBg,
    required this.statusRunningInk,
    required this.statusRunningLine,
    required this.statusRunningMark,
    required this.statusFailedBg,
    required this.statusFailedInk,
    required this.statusFailedLine,
    required this.statusFailedMark,
    required this.statusDoneBg,
    required this.statusDoneInk,
    required this.statusDoneLine,
    required this.statusDoneMark,
    required this.statusIdleBg,
    required this.statusIdleInk,
    required this.statusIdleLine,
    required this.statusIdleMark,
    required this.statusInterruptedBg,
    required this.statusInterruptedInk,
    required this.statusInterruptedLine,
    required this.statusInterruptedMark,
    required this.statusAskingParentBg,
    required this.statusAskingParentInk,
    required this.statusAskingParentLine,
    required this.statusAskingParentMark,
    required this.ctxOpening,
    required this.ctxSummary,
    required this.ctxLive,
    required this.spaceApricot,
    required this.spacePaw,
    required this.spaceMoss,
    required this.spaceDuvet,
    required this.spaceSun,
    required this.spaceSky,
    required this.black,
    required this.onSpaceTile,
    required this.liftStrong,
    required this.selectedIcon,
    required this.spacePatchApricotFill,
    required this.spacePatchApricotDeep,
    required this.spacePatchApricotInk,
    required this.spacePatchPawFill,
    required this.spacePatchPawDeep,
    required this.spacePatchPawInk,
    required this.spacePatchMossFill,
    required this.spacePatchMossDeep,
    required this.spacePatchMossInk,
    required this.spacePatchDuvetFill,
    required this.spacePatchDuvetDeep,
    required this.spacePatchDuvetInk,
    required this.spacePatchSunFill,
    required this.spacePatchSunDeep,
    required this.spacePatchSunInk,
    required this.spacePatchSkyFill,
    required this.spacePatchSkyDeep,
    required this.spacePatchSkyInk,
    required this.scratchRail,
    required this.scratchRail2,
    required this.scratchRailInk,
    required this.scratchRailMuted,
    required this.scratchRailLine,
  });

  final Color desk;
  final Color raised;
  final Color paper;
  final Color surface;
  final Color surface2;
  final Color ink;
  final Color muted;
  final Color faint;
  final Color disabled;
  final Color icon;
  final Color iconFaint;
  final Color accent;
  final Color accentHover;
  final Color accentText;
  final Color accentInk;
  final Color focus;
  final Color focusKeyline;
  final Color seam;
  final Color seamSubtle;
  final Color seamStrong;
  final Color thread;
  final Color threadStrong;
  final Color hover;
  final Color pressed;
  final Color selected;
  final Color selection;
  final Color constructive;
  final Color information;
  final Color attention;
  final Color danger;
  final Color pawTint;
  final Color constructiveInk;
  final Color informationInk;
  final Color attentionInk;
  final Color dangerInk;
  final Color diffAdd;
  final Color diffAddInk;
  final Color diffDel;
  final Color diffDelInk;
  final Color codeBg;
  final Color codeInk;
  final Color scrim;
  final Color lift;
  final Color thumb;
  final Color switchOff;
  final Color knob;
  final List<BoxShadow> shadow;
  final List<BoxShadow> shadowHover;
  final List<BoxShadow> shadowStack;
  final Color statusNeedsYouBg;
  final Color statusNeedsYouInk;
  final Color statusNeedsYouLine;
  final Color statusNeedsYouMark;
  final Color statusRunningBg;
  final Color statusRunningInk;
  final Color statusRunningLine;
  final Color statusRunningMark;
  final Color statusFailedBg;
  final Color statusFailedInk;
  final Color statusFailedLine;
  final Color statusFailedMark;
  final Color statusDoneBg;
  final Color statusDoneInk;
  final Color statusDoneLine;
  final Color statusDoneMark;
  final Color statusIdleBg;
  final Color statusIdleInk;
  final Color statusIdleLine;
  final Color statusIdleMark;
  final Color statusInterruptedBg;
  final Color statusInterruptedInk;
  final Color statusInterruptedLine;
  final Color statusInterruptedMark;
  final Color statusAskingParentBg;
  final Color statusAskingParentInk;
  final Color statusAskingParentLine;
  final Color statusAskingParentMark;
  final Color ctxOpening;
  final Color ctxSummary;
  final Color ctxLive;
  final Color spaceApricot;
  final Color spacePaw;
  final Color spaceMoss;
  final Color spaceDuvet;
  final Color spaceSun;
  final Color spaceSky;
  final Color black;
  final Color onSpaceTile;
  final Color liftStrong;
  final Color selectedIcon;
  final Color spacePatchApricotFill;
  final Color spacePatchApricotDeep;
  final Color spacePatchApricotInk;
  final Color spacePatchPawFill;
  final Color spacePatchPawDeep;
  final Color spacePatchPawInk;
  final Color spacePatchMossFill;
  final Color spacePatchMossDeep;
  final Color spacePatchMossInk;
  final Color spacePatchDuvetFill;
  final Color spacePatchDuvetDeep;
  final Color spacePatchDuvetInk;
  final Color spacePatchSunFill;
  final Color spacePatchSunDeep;
  final Color spacePatchSunInk;
  final Color spacePatchSkyFill;
  final Color spacePatchSkyDeep;
  final Color spacePatchSkyInk;
  final Color scratchRail;
  final Color scratchRail2;
  final Color scratchRailInk;
  final Color scratchRailMuted;
  final Color scratchRailLine;

  static const light = ProfileColors(
    desk: Color(0xFFECE6DB),
    raised: Color(0xFFFFFAF1),
    paper: Color(0x00000000),
    surface: Color(0xFFFFFAF1),
    surface2: Color(0xFFF3EFE7),
    ink: Color(0xFF282A2F),
    muted: Color(0xFF625C55),
    faint: Color(0xFF6C645D),
    disabled: Color(0xFFB8ADA1),
    icon: Color(0xFF625C55),
    iconFaint: Color(0xFF6C645D),
    accent: Color(0xFFDE945F),
    accentHover: Color(0xFFC97F4A),
    accentText: Color(0xFF874016),
    accentInk: Color(0xFF282A2F),
    focus: Color(0xFF7AB7FF),
    focusKeyline: Color(0xFF282A2F),
    seam: Color(0xFFE4DCCF),
    seamSubtle: Color(0xFFEDE6DA),
    seamStrong: Color(0xFFB8ADA1),
    thread: Color(0xFFB8ADA1),
    threadStrong: Color(0xFF6C645D),
    hover: Color(0x0D282A2F),
    pressed: Color(0x14282A2F),
    selected: Color(0x24DE945F),
    selection: Color(0x4DDE945F),
    constructive: Color(0xFFCAD8CD),
    information: Color(0xFFCBD5DF),
    attention: Color(0xFFF0D29C),
    danger: Color(0xFFE5B1AA),
    pawTint: Color(0xFFEFD3CF),
    constructiveInk: Color(0xFF397748),
    informationInk: Color(0xFF625C55),
    attentionInk: Color(0xFF874016),
    dangerInk: Color(0xFFAD4B4B),
    diffAdd: Color(0xFFCAD8CD),
    diffAddInk: Color(0xFF397748),
    diffDel: Color(0xFFE5B1AA),
    diffDelInk: Color(0xFFAD4B4B),
    codeBg: Color(0xFFF3EFE7),
    codeInk: Color(0xFF874016),
    scrim: Color(0x73282A2F),
    lift: Color(0x1A000000),
    thumb: Color(0x26000000),
    switchOff: Color(0x29000000),
    knob: Color(0xFFFFFFFF),
    shadow: [BoxShadow(color: Color(0x1A282A2F), offset: Offset(0, 4), blurRadius: 12)],
    shadowHover: [BoxShadow(color: Color(0x24282A2F), offset: Offset(0, 8), blurRadius: 20)],
    shadowStack: [BoxShadow(color: Color(0x57282A2F), offset: Offset(-14, 0), blurRadius: 28, spreadRadius: -14), BoxShadow(color: Color(0x0F282A2F), spreadRadius: 1)],
    statusNeedsYouBg: Color(0xFFF0D29C),
    statusNeedsYouInk: Color(0xFF874016),
    statusNeedsYouLine: Color(0x59874016),
    statusNeedsYouMark: Color(0xFFDE945F),
    statusRunningBg: Color(0x00000000),
    statusRunningInk: Color(0xFF625C55),
    statusRunningLine: Color(0x00000000),
    statusRunningMark: Color(0xFF282A2F),
    statusFailedBg: Color(0x00000000),
    statusFailedInk: Color(0xFFAD4B4B),
    statusFailedLine: Color(0x00000000),
    statusFailedMark: Color(0xFFAD4B4B),
    statusDoneBg: Color(0x00000000),
    statusDoneInk: Color(0xFF397748),
    statusDoneLine: Color(0x00000000),
    statusDoneMark: Color(0xFF397748),
    statusIdleBg: Color(0x00000000),
    statusIdleInk: Color(0xFF625C55),
    statusIdleLine: Color(0x00000000),
    statusIdleMark: Color(0xFF6C645D),
    statusInterruptedBg: Color(0x00000000),
    statusInterruptedInk: Color(0xFF625C55),
    statusInterruptedLine: Color(0x00000000),
    statusInterruptedMark: Color(0xFF6C645D),
    statusAskingParentBg: Color(0x00000000),
    statusAskingParentInk: Color(0xFF625C55),
    statusAskingParentLine: Color(0x00000000),
    statusAskingParentMark: Color(0xFF625C55),
    ctxOpening: Color(0xFFB8ADA1),
    ctxSummary: Color(0xFF8EA3BB),
    ctxLive: Color(0xFF6C645D),
    spaceApricot: Color(0xFFDE945F),
    spacePaw: Color(0xFFDDA39D),
    spaceMoss: Color(0xFF697A6B),
    spaceDuvet: Color(0xFF2F3138),
    spaceSun: Color(0xFFF0D29C),
    spaceSky: Color(0xFFCBD5DF),
    black: Color(0xFF000000),
    onSpaceTile: Color(0xFF282A2F),
    liftStrong: Color(0x2A000000),
    selectedIcon: Color(0xFF5F7894),
    spacePatchApricotFill: Color(0xFFDE945F),
    spacePatchApricotDeep: Color(0xFFBF6F3C),
    spacePatchApricotInk: Color(0xFF282A2F),
    spacePatchPawFill: Color(0xFFDDA39D),
    spacePatchPawDeep: Color(0xFFBC7C75),
    spacePatchPawInk: Color(0xFF282A2F),
    spacePatchMossFill: Color(0xFF5F7062),
    spacePatchMossDeep: Color(0xFF495A4C),
    spacePatchMossInk: Color(0xFFFFFAF1),
    spacePatchDuvetFill: Color(0xFF2F3138),
    spacePatchDuvetDeep: Color(0xFF4C505A),
    spacePatchDuvetInk: Color(0xFFF3EFE7),
    spacePatchSunFill: Color(0xFFF0D29C),
    spacePatchSunDeep: Color(0xFFCDA663),
    spacePatchSunInk: Color(0xFF282A2F),
    spacePatchSkyFill: Color(0xFFCBD5DF),
    spacePatchSkyDeep: Color(0xFFA3B3C4),
    spacePatchSkyInk: Color(0xFF282A2F),
    scratchRail: Color(0xFF2F3138),
    scratchRail2: Color(0xFF3B3E45),
    scratchRailInk: Color(0xFFF3EFE7),
    scratchRailMuted: Color(0xFFC6BAAC),
    scratchRailLine: Color(0xFF41444C),
  );

  static const dark = ProfileColors(
    desk: Color(0xFF222428),
    raised: Color(0xFF30333A),
    paper: Color(0x00000000),
    surface: Color(0xFF30333A),
    surface2: Color(0xFF2A2D33),
    ink: Color(0xFFF3EFE7),
    muted: Color(0xFFC6BAAC),
    faint: Color(0xFF999DA6),
    disabled: Color(0xFF575B64),
    icon: Color(0xFFC6BAAC),
    iconFaint: Color(0xFF999DA6),
    accent: Color(0xFFF0A064),
    accentHover: Color(0xFFF5B47F),
    accentText: Color(0xFFF0A064),
    accentInk: Color(0xFF282A2F),
    focus: Color(0xFF7AB7FF),
    focusKeyline: Color(0x00282A2F),
    seam: Color(0xFF41444C),
    seamSubtle: Color(0xFF363940),
    seamStrong: Color(0xFF575B64),
    thread: Color(0xFF575B64),
    threadStrong: Color(0xFF999DA6),
    hover: Color(0x0FFFFFFF),
    pressed: Color(0x17FFFFFF),
    selected: Color(0x2EF0A064),
    selection: Color(0x57F0A064),
    constructive: Color(0x38CAD8CD),
    information: Color(0x33CBD5DF),
    attention: Color(0x33F0D29C),
    danger: Color(0x42E5B1AA),
    pawTint: Color(0x38DDA39D),
    constructiveInk: Color(0xFF93BD9B),
    informationInk: Color(0xFFC6BAAC),
    attentionInk: Color(0xFFF0D29C),
    dangerInk: Color(0xFFE0A3A3),
    diffAdd: Color(0x38CAD8CD),
    diffAddInk: Color(0xFF93BD9B),
    diffDel: Color(0x42E5B1AA),
    diffDelInk: Color(0xFFE0A3A3),
    codeBg: Color(0xFF2A2D33),
    codeInk: Color(0xFFF0A064),
    scrim: Color(0x99000000),
    lift: Color(0x1A000000),
    thumb: Color(0x33FFFFFF),
    switchOff: Color(0x33FFFFFF),
    knob: Color(0xFFFFFFFF),
    shadow: [BoxShadow(color: Color(0x52000000), offset: Offset(0, 4), blurRadius: 12)],
    shadowHover: [BoxShadow(color: Color(0x6B000000), offset: Offset(0, 8), blurRadius: 20)],
    shadowStack: [BoxShadow(color: Color(0x99000000), offset: Offset(-16, 0), blurRadius: 30, spreadRadius: -12), BoxShadow(color: Color(0x0DFFFFFF), spreadRadius: 1)],
    statusNeedsYouBg: Color(0x33F0D29C),
    statusNeedsYouInk: Color(0xFFF0D29C),
    statusNeedsYouLine: Color(0x59F0D29C),
    statusNeedsYouMark: Color(0xFFF0A064),
    statusRunningBg: Color(0x00000000),
    statusRunningInk: Color(0xFFC6BAAC),
    statusRunningLine: Color(0x00000000),
    statusRunningMark: Color(0xFFF3EFE7),
    statusFailedBg: Color(0x00000000),
    statusFailedInk: Color(0xFFE0A3A3),
    statusFailedLine: Color(0x00000000),
    statusFailedMark: Color(0xFFE0A3A3),
    statusDoneBg: Color(0x00000000),
    statusDoneInk: Color(0xFF93BD9B),
    statusDoneLine: Color(0x00000000),
    statusDoneMark: Color(0xFF93BD9B),
    statusIdleBg: Color(0x00000000),
    statusIdleInk: Color(0xFFC6BAAC),
    statusIdleLine: Color(0x00000000),
    statusIdleMark: Color(0xFF999DA6),
    statusInterruptedBg: Color(0x00000000),
    statusInterruptedInk: Color(0xFFC6BAAC),
    statusInterruptedLine: Color(0x00000000),
    statusInterruptedMark: Color(0xFF999DA6),
    statusAskingParentBg: Color(0x00000000),
    statusAskingParentInk: Color(0xFFC6BAAC),
    statusAskingParentLine: Color(0x00000000),
    statusAskingParentMark: Color(0xFFC6BAAC),
    ctxOpening: Color(0xFF575B64),
    ctxSummary: Color(0xFF7B91AB),
    ctxLive: Color(0xFF999DA6),
    spaceApricot: Color(0xFFDE945F),
    spacePaw: Color(0xFFDDA39D),
    spaceMoss: Color(0xFF5F7062),
    spaceDuvet: Color(0xFF999DA6),
    spaceSun: Color(0xFFF0D29C),
    spaceSky: Color(0xFFCBD5DF),
    black: Color(0xFF000000),
    onSpaceTile: Color(0xFF282A2F),
    liftStrong: Color(0x2A000000),
    selectedIcon: Color(0xFF5F7894),
    spacePatchApricotFill: Color(0xFFDB8C56),
    spacePatchApricotDeep: Color(0xFFB0673A),
    spacePatchApricotInk: Color(0xFF1E2024),
    spacePatchPawFill: Color(0xFFD29891),
    spacePatchPawDeep: Color(0xFFAC736D),
    spacePatchPawInk: Color(0xFF1E2024),
    spacePatchMossFill: Color(0xFF5F7062),
    spacePatchMossDeep: Color(0xFF4A5A4D),
    spacePatchMossInk: Color(0xFFFFFAF1),
    spacePatchDuvetFill: Color(0xFFDCD4C8),
    spacePatchDuvetDeep: Color(0xFFB5AA9C),
    spacePatchDuvetInk: Color(0xFF282A2F),
    spacePatchSunFill: Color(0xFFE3C48B),
    spacePatchSunDeep: Color(0xFFBC9A58),
    spacePatchSunInk: Color(0xFF1E2024),
    spacePatchSkyFill: Color(0xFFB9C6D3),
    spacePatchSkyDeep: Color(0xFF93A5B8),
    spacePatchSkyInk: Color(0xFF1E2024),
    scratchRail: Color(0xFF141618),
    scratchRail2: Color(0xFF24262B),
    scratchRailInk: Color(0xFFF3EFE7),
    scratchRailMuted: Color(0xFFC6BAAC),
    scratchRailLine: Color(0xFF2B2E33),
  );
}

/// The family palette of tokens.json for one theme.
@immutable
class FamilyColors {
  const FamilyColors({
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.ink,
    required this.muted,
    required this.boundary,
    required this.boundaryStrong,
    required this.accent,
    required this.accentText,
    required this.accentInk,
    required this.focus,
    required this.focusKeyline,
    required this.desk,
    required this.inset,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceMuted;
  final Color ink;
  final Color muted;
  final Color boundary;
  final Color boundaryStrong;
  final Color accent;
  final Color accentText;
  final Color accentInk;
  final Color focus;
  final Color focusKeyline;
  final Color desk;
  final Color inset;

  static const light = FamilyColors(
    canvas: Color(0xFFF3EFE7),
    surface: Color(0xFFFFFAF1),
    surfaceMuted: Color(0xFFDCD4C8),
    ink: Color(0xFF282A2F),
    muted: Color(0xFF625C55),
    boundary: Color(0xFFB8ADA1),
    boundaryStrong: Color(0xFF6C645D),
    accent: Color(0xFFDE945F),
    accentText: Color(0xFF874016),
    accentInk: Color(0xFF282A2F),
    focus: Color(0xFF7AB7FF),
    focusKeyline: Color(0xFF282A2F),
    desk: Color(0xFFECE6DB),
    inset: Color(0xFFF3EFE7),
  );

  static const dark = FamilyColors(
    canvas: Color(0xFF24262C),
    surface: Color(0xFF30333A),
    surfaceMuted: Color(0xFF3B3E45),
    ink: Color(0xFFF3EFE7),
    muted: Color(0xFFC6BAAC),
    boundary: Color(0xFF575B64),
    boundaryStrong: Color(0xFF999DA6),
    accent: Color(0xFFF0A064),
    accentText: Color(0xFFF0A064),
    accentInk: Color(0xFF282A2F),
    focus: Color(0xFF7AB7FF),
    focusKeyline: Color(0x00282A2F),
    desk: Color(0xFF222428),
    inset: Color(0xFF2A2D33),
  );
}

/// The theme-independent semantic colours of tokens.json.
abstract final class SemanticColors {
  static const Color constructive = Color(0xFFCAD8CD);
  static const Color information = Color(0xFFCBD5DF);
  static const Color attention = Color(0xFFF0D29C);
  static const Color danger = Color(0xFFE5B1AA);
  static const Color creative = Color(0xFFDDA39D);
  static const Color bubbleplay = Color(0xFFF0A064);
}

/// The theme-independent muse colours of tokens.json.
abstract final class MuseColors {
  static const Color milk = Color(0xFFF3EFE7);
  static const Color apricot = Color(0xFFDE945F);
  static const Color paw = Color(0xFFDDA39D);
  static const Color calicoBlack = Color(0xFF101214);
  static const Color duvet = Color(0xFF2F3138);
  static const Color eye = Color(0xFF697A6B);
}

/// Every non-colour token of tokens.json, named by its path: `radius.control`
/// is [radiusControl], `typography.ui.weightStrong` is [typographyUiWeightStrong].
abstract final class Contract {
  static const String typographyUiFamily = 'Atkinson Hyperlegible Next Variable';
  static const double typographyUiWeightRegular = 450;
  static const double typographyUiWeightStrong = 720;
  static const String typographyDisplayFamily = 'Bricolage Grotesque Variable';
  static const double typographyDisplayWeightRegular = 620;
  static const double typographyDisplayWeightStrong = 760;
  static const String typographyCodeFamily = 'Fragment Mono';
  static const double typographyCodeWeightRegular = 400;
  static const double typographyCodeWeightStrong = 600;
  static const double spacing1 = 4;
  static const double spacing2 = 8;
  static const double spacing3 = 12;
  static const double spacing4 = 16;
  static const double spacing6 = 24;
  static const double spacing8 = 32;
  static const double spacing12 = 48;
  static const double spacing16 = 64;
  static const BorderRadius radiusControl = BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(11), bottomRight: Radius.circular(6), bottomLeft: Radius.circular(9));
  static const BorderRadius radiusField = BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(10), bottomRight: Radius.circular(6), bottomLeft: Radius.circular(8));
  static const BorderRadius radiusNested = BorderRadius.all(Radius.circular(11));
  static const BorderRadius radiusPanel = BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(18), bottomRight: Radius.circular(10), bottomLeft: Radius.circular(16));
  static const double borderQuiet = 1;
  static const double borderFocus = 2;
  static const double borderKeyline = 1;
  static const List<BoxShadow> shadowLightSeam = [BoxShadow(color: Color(0x1A282A2F), offset: Offset(0, 4), blurRadius: 12)];
  static const List<BoxShadow> shadowLightSeamHover = [BoxShadow(color: Color(0x24282A2F), offset: Offset(0, 8), blurRadius: 20)];
  static const List<BoxShadow> shadowDarkSeam = [BoxShadow(color: Color(0x52000000), offset: Offset(0, 4), blurRadius: 12)];
  static const List<BoxShadow> shadowDarkSeamHover = [BoxShadow(color: Color(0x6B000000), offset: Offset(0, 8), blurRadius: 20)];
  static const Duration motionFast = Duration(milliseconds: 140);
  static const Duration motionFunctional = Duration(milliseconds: 220);
  static const Duration motionSheet = Duration(milliseconds: 250);
  static const Cubic motionEasing = Cubic(0.2, 0.8, 0.2, 1);
  static const double controlHeightDefault = 46;
  static const double controlHeightDense = 34;
  static const double controlHeightMobile = 48;
  static const double controlHeightFloor = 24;
}

/// One product's dialect: the only settings a product may change.
/// `focusKeyline` is the ink keyline inside the focus ring in light, null
/// where the product has none.
@immutable
class ProductDialect {
  const ProductDialect({
    required this.dark,
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.ink,
    required this.muted,
    required this.boundary,
    required this.accent,
    required this.accentInk,
    required this.accentText,
    required this.focus,
    required this.focusDark,
    required this.stage,
    required this.stageInk,
    required this.constructive,
    required this.information,
    required this.attention,
    required this.danger,
    required this.stateInk,
    this.focusKeyline,
    required this.radiusControl,
    required this.radiusField,
    required this.radiusPanel,
    required this.borderWidth,
    required this.controlHeight,
  });

  final bool dark;
  final Color canvas;
  final Color surface;
  final Color surfaceMuted;
  final Color ink;
  final Color muted;
  final Color boundary;
  final Color accent;
  final Color accentInk;
  final Color accentText;
  final Color focus;
  final Color focusDark;
  final Color stage;
  final Color stageInk;
  final Color constructive;
  final Color information;
  final Color attention;
  final Color danger;
  final Color stateInk;
  final Color? focusKeyline;
  final BorderRadius radiusControl;
  final BorderRadius radiusField;
  final BorderRadius radiusPanel;
  final double borderWidth;
  final double controlHeight;

  static const general = ProductDialect(
    dark: false,
    canvas: Color(0xFFF3EFE7),
    surface: Color(0xFFFFFAF1),
    surfaceMuted: Color(0xFFDCD4C8),
    ink: Color(0xFF282A2F),
    muted: Color(0xFF625C55),
    boundary: Color(0xFF6C645D),
    accent: Color(0xFFDE945F),
    accentInk: Color(0xFF282A2F),
    accentText: Color(0xFF874016),
    focus: Color(0xFF7AB7FF),
    focusDark: Color(0xFF7AB7FF),
    stage: Color(0xFFFFFAF1),
    stageInk: Color(0xFF282A2F),
    constructive: Color(0xFFCAD8CD),
    information: Color(0xFFCBD5DF),
    attention: Color(0xFFF0D29C),
    danger: Color(0xFFE5B1AA),
    stateInk: Color(0xFF282A2F),
    focusKeyline: Color(0xFF282A2F),
    radiusControl: BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(11), bottomRight: Radius.circular(6), bottomLeft: Radius.circular(9)),
    radiusField: BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(10), bottomRight: Radius.circular(6), bottomLeft: Radius.circular(8)),
    radiusPanel: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(18), bottomRight: Radius.circular(10), bottomLeft: Radius.circular(16)),
    borderWidth: 1,
    controlHeight: 46,
  );

  static const bubblepaw = ProductDialect(
    dark: false,
    canvas: Color(0xFFF3EFE7),
    surface: Color(0xFFFFFAF1),
    surfaceMuted: Color(0xFFDCD4C8),
    ink: Color(0xFF282A2F),
    muted: Color(0xFF625C55),
    boundary: Color(0xFF6C645D),
    accent: Color(0xFFDE945F),
    accentInk: Color(0xFF282A2F),
    accentText: Color(0xFF874016),
    focus: Color(0xFF7AB7FF),
    focusDark: Color(0xFF7AB7FF),
    stage: Color(0xFFFFFAF1),
    stageInk: Color(0xFF282A2F),
    constructive: Color(0xFFCAD8CD),
    information: Color(0xFFCBD5DF),
    attention: Color(0xFFF0D29C),
    danger: Color(0xFFE5B1AA),
    stateInk: Color(0xFF282A2F),
    focusKeyline: Color(0xFF282A2F),
    radiusControl: BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(11), bottomRight: Radius.circular(6), bottomLeft: Radius.circular(9)),
    radiusField: BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(10), bottomRight: Radius.circular(6), bottomLeft: Radius.circular(8)),
    radiusPanel: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(18), bottomRight: Radius.circular(10), bottomLeft: Radius.circular(16)),
    borderWidth: 1,
    controlHeight: 46,
  );

  static const bubbleplay = ProductDialect(
    dark: true,
    canvas: Color(0xFF24262C),
    surface: Color(0xFF30333A),
    surfaceMuted: Color(0xFF3B3E45),
    ink: Color(0xFFF3EFE7),
    muted: Color(0xFFC6BAAC),
    boundary: Color(0xFF999DA6),
    accent: Color(0xFFF0A064),
    accentInk: Color(0xFF282A2F),
    accentText: Color(0xFFF0A064),
    focus: Color(0xFF7AB7FF),
    focusDark: Color(0xFF7AB7FF),
    stage: Color(0xFF101214),
    stageInk: Color(0xFFF3EFE7),
    constructive: Color(0xFFCAD8CD),
    information: Color(0xFFCBD5DF),
    attention: Color(0xFFF0D29C),
    danger: Color(0xFFE5B1AA),
    stateInk: Color(0xFF282A2F),
    radiusControl: BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(11), bottomRight: Radius.circular(6), bottomLeft: Radius.circular(9)),
    radiusField: BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(10), bottomRight: Radius.circular(6), bottomLeft: Radius.circular(8)),
    radiusPanel: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(12), bottomRight: Radius.circular(7), bottomLeft: Radius.circular(10)),
    borderWidth: 1,
    controlHeight: 36,
  );

  static const needlebub = ProductDialect(
    dark: false,
    canvas: Color(0xFFF3EFE7),
    surface: Color(0xFFFFFAF1),
    surfaceMuted: Color(0xFFDCD4C8),
    ink: Color(0xFF282A2F),
    muted: Color(0xFF625C55),
    boundary: Color(0xFF6C645D),
    accent: Color(0xFFDE945F),
    accentInk: Color(0xFF282A2F),
    accentText: Color(0xFF874016),
    focus: Color(0xFF7AB7FF),
    focusDark: Color(0xFF7AB7FF),
    stage: Color(0xFF2F3138),
    stageInk: Color(0xFFF3EFE7),
    constructive: Color(0xFFCAD8CD),
    information: Color(0xFFCBD5DF),
    attention: Color(0xFFF0D29C),
    danger: Color(0xFFE5B1AA),
    stateInk: Color(0xFF282A2F),
    focusKeyline: Color(0xFF282A2F),
    radiusControl: BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(11), bottomRight: Radius.circular(6), bottomLeft: Radius.circular(9)),
    radiusField: BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(10), bottomRight: Radius.circular(6), bottomLeft: Radius.circular(8)),
    radiusPanel: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(18), bottomRight: Radius.circular(10), bottomLeft: Radius.circular(16)),
    borderWidth: 1,
    controlHeight: 48,
  );

  static const pawth = ProductDialect(
    dark: false,
    canvas: Color(0xFFF3EFE7),
    surface: Color(0xFFFFFAF1),
    surfaceMuted: Color(0xFFDCD4C8),
    ink: Color(0xFF282A2F),
    muted: Color(0xFF625C55),
    boundary: Color(0xFF6C645D),
    accent: Color(0xFFDE945F),
    accentInk: Color(0xFF282A2F),
    accentText: Color(0xFF874016),
    focus: Color(0xFF7AB7FF),
    focusDark: Color(0xFF7AB7FF),
    stage: Color(0xFFE6E0D6),
    stageInk: Color(0xFF282A2F),
    constructive: Color(0xFFCAD8CD),
    information: Color(0xFFCBD5DF),
    attention: Color(0xFFF0D29C),
    danger: Color(0xFFE5B1AA),
    stateInk: Color(0xFF282A2F),
    focusKeyline: Color(0xFF282A2F),
    radiusControl: BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(8), bottomRight: Radius.circular(5), bottomLeft: Radius.circular(7)),
    radiusField: BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(7), bottomRight: Radius.circular(5), bottomLeft: Radius.circular(6)),
    radiusPanel: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(12), bottomRight: Radius.circular(7), bottomLeft: Radius.circular(10)),
    borderWidth: 1,
    controlHeight: 32,
  );

  static const pawthDark = ProductDialect(
    dark: true,
    canvas: Color(0xFF24262C),
    surface: Color(0xFF30333A),
    surfaceMuted: Color(0xFF3B3E45),
    ink: Color(0xFFF3EFE7),
    muted: Color(0xFFC6BAAC),
    boundary: Color(0xFF999DA6),
    accent: Color(0xFFF0A064),
    accentInk: Color(0xFF282A2F),
    accentText: Color(0xFFF0A064),
    focus: Color(0xFF7AB7FF),
    focusDark: Color(0xFF7AB7FF),
    stage: Color(0xFF191B1F),
    stageInk: Color(0xFFF3EFE7),
    constructive: Color(0xFFCAD8CD),
    information: Color(0xFFCBD5DF),
    attention: Color(0xFFF0D29C),
    danger: Color(0xFFE5B1AA),
    stateInk: Color(0xFF282A2F),
    radiusControl: BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(8), bottomRight: Radius.circular(5), bottomLeft: Radius.circular(7)),
    radiusField: BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(7), bottomRight: Radius.circular(5), bottomLeft: Radius.circular(6)),
    radiusPanel: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(12), bottomRight: Radius.circular(7), bottomLeft: Radius.circular(10)),
    borderWidth: 1,
    controlHeight: 32,
  );

  static const agentKit = ProductDialect(
    dark: false,
    canvas: Color(0xFFECE6DB),
    surface: Color(0xFFFFFAF1),
    surfaceMuted: Color(0xFFF3EFE7),
    ink: Color(0xFF282A2F),
    muted: Color(0xFF625C55),
    boundary: Color(0xFF6C645D),
    accent: Color(0xFFDE945F),
    accentInk: Color(0xFF282A2F),
    accentText: Color(0xFF874016),
    focus: Color(0xFF7AB7FF),
    focusDark: Color(0xFF7AB7FF),
    stage: Color(0xFFFFFAF1),
    stageInk: Color(0xFF282A2F),
    constructive: Color(0xFFCAD8CD),
    information: Color(0xFFCBD5DF),
    attention: Color(0xFFF0D29C),
    danger: Color(0xFFE5B1AA),
    stateInk: Color(0xFF282A2F),
    focusKeyline: Color(0xFF282A2F),
    radiusControl: BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(11), bottomRight: Radius.circular(6), bottomLeft: Radius.circular(9)),
    radiusField: BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(10), bottomRight: Radius.circular(6), bottomLeft: Radius.circular(8)),
    radiusPanel: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(18), bottomRight: Radius.circular(10), bottomLeft: Radius.circular(16)),
    borderWidth: 1,
    controlHeight: 46,
  );
}
