// The app's icons: Lucide glyphs (lucide.dart) behind the app's own names.
// New UI uses these enums (Ico here, Ix in icon_x.dart), never another set.

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'lucide.dart';
import 'tokens.dart';

enum Ico {
  plus,
  grip,
  chevronLeft,
  chevronRight,
  chevronDown,
  search,
  page,
  compose,
  home,
  inbox,
  more,
  trash,
  arrowUp,
  arrowDown,
  turnInto,
  duplicate,
  link,
  indent,
  outdent,
  keyboardHide,
  undo,
  bullets,
  numbers,
  todo,
  quote,
  code,
  divider,
  text,
  check,
  comment,
  star,
  clock,
  settings,
  sidebar,
  close,
  sendHorizontal,
  hourglass,
  terminal,
  folder,
  chevronUp,
  monitor,
  monitorPlay,
  laptop,
  server,
  copy,
  pencil,
  refresh,
  info,
  circleCheck,
  circleAlert,
  triangleAlert,
  pointer,
  pointerClick,
  activity,
  gauge,
  volume,
  logOut,
  gamepad,
  qrCode,
  globe,
  radio,
  arrowRight,
  lock,
  userCheck,
  keyboard,
  minus,
  maximize,
  eye,
  eyeOff,
  square,
  circle,
  hand,
  slash,
  pentagon,
  redo,
  folderOpen,
  save,
  sun,
  moon,
  upload,
  download,
  fileCode,
  rotateCw,
  rotateCcw,
  flipHorizontal,
  flipVertical,
  grid,
  group,
  ungroup,
  magnet,
  crop,
  zoomIn,
  zoomOut,
  gitCommit,
  rectangleHorizontal,
  layers,
  panelRight,
  timerReset,
  shapes,
  library,
  smartphone,
  spline,
  filePlus,
  link2,
  unlink2,
  scissors,
  squareDashed,
  play,
  pause,
}

/// The Lucide glyph behind each [Ico].
const icoGlyphs = <Ico, LucideGlyph>{
  Ico.plus: (
    LucideIcons.plus300,
    LucideIcons.plus,
    LucideIcons.plus500,
  ), // plus
  Ico.grip: (
    LucideIcons.gripVertical300,
    LucideIcons.gripVertical,
    LucideIcons.gripVertical500,
  ), // grip-vertical
  Ico.chevronLeft: (
    LucideIcons.chevronLeft300,
    LucideIcons.chevronLeft,
    LucideIcons.chevronLeft500,
  ), // chevron-left
  Ico.chevronRight: (
    LucideIcons.chevronRight300,
    LucideIcons.chevronRight,
    LucideIcons.chevronRight500,
  ), // chevron-right
  Ico.chevronDown: (
    LucideIcons.chevronDown300,
    LucideIcons.chevronDown,
    LucideIcons.chevronDown500,
  ), // chevron-down
  Ico.search: (
    LucideIcons.search300,
    LucideIcons.search,
    LucideIcons.search500,
  ), // search
  Ico.page: (
    LucideIcons.fileText300,
    LucideIcons.fileText,
    LucideIcons.fileText500,
  ), // file-text
  Ico.compose: (
    LucideIcons.squarePen300,
    LucideIcons.squarePen,
    LucideIcons.squarePen500,
  ), // square-pen
  Ico.home: (
    LucideIcons.house300,
    LucideIcons.house,
    LucideIcons.house500,
  ), // house
  Ico.inbox: (
    LucideIcons.inbox300,
    LucideIcons.inbox,
    LucideIcons.inbox500,
  ), // inbox
  Ico.more: (
    LucideIcons.ellipsis300,
    LucideIcons.ellipsis,
    LucideIcons.ellipsis500,
  ), // ellipsis
  Ico.trash: (
    LucideIcons.trash2300,
    LucideIcons.trash2,
    LucideIcons.trash2500,
  ), // trash-2
  Ico.arrowUp: (
    LucideIcons.arrowUp300,
    LucideIcons.arrowUp,
    LucideIcons.arrowUp500,
  ), // arrow-up
  Ico.arrowDown: (
    LucideIcons.arrowDown300,
    LucideIcons.arrowDown,
    LucideIcons.arrowDown500,
  ), // arrow-down
  Ico.turnInto: (
    LucideIcons.refreshCw300,
    LucideIcons.refreshCw,
    LucideIcons.refreshCw500,
  ), // refresh-cw
  Ico.duplicate: (
    LucideIcons.copy300,
    LucideIcons.copy,
    LucideIcons.copy500,
  ), // copy
  Ico.link: (
    LucideIcons.link300,
    LucideIcons.link,
    LucideIcons.link500,
  ), // link
  Ico.indent: (
    LucideIcons.listIndentIncrease300,
    LucideIcons.listIndentIncrease,
    LucideIcons.listIndentIncrease500,
  ), // list-indent-increase
  Ico.outdent: (
    LucideIcons.listIndentDecrease300,
    LucideIcons.listIndentDecrease,
    LucideIcons.listIndentDecrease500,
  ), // list-indent-decrease
  Ico.keyboardHide: (
    LucideIcons.keyboardOff300,
    LucideIcons.keyboardOff,
    LucideIcons.keyboardOff500,
  ), // keyboard-off
  Ico.undo: (
    LucideIcons.undo2300,
    LucideIcons.undo2,
    LucideIcons.undo2500,
  ), // undo-2
  Ico.bullets: (
    LucideIcons.list300,
    LucideIcons.list,
    LucideIcons.list500,
  ), // list
  Ico.numbers: (
    LucideIcons.listOrdered300,
    LucideIcons.listOrdered,
    LucideIcons.listOrdered500,
  ), // list-ordered
  Ico.todo: (
    LucideIcons.squareCheck300,
    LucideIcons.squareCheck,
    LucideIcons.squareCheck500,
  ), // square-check
  Ico.quote: (
    LucideIcons.textQuote300,
    LucideIcons.textQuote,
    LucideIcons.textQuote500,
  ), // text-quote
  Ico.code: (
    LucideIcons.code300,
    LucideIcons.code,
    LucideIcons.code500,
  ), // code
  Ico.divider: (
    LucideIcons.separatorHorizontal300,
    LucideIcons.separatorHorizontal,
    LucideIcons.separatorHorizontal500,
  ), // separator-horizontal
  Ico.text: (
    LucideIcons.type300,
    LucideIcons.type,
    LucideIcons.type500,
  ), // type
  Ico.check: (
    LucideIcons.check300,
    LucideIcons.check,
    LucideIcons.check500,
  ), // check
  Ico.comment: (
    LucideIcons.messageSquare300,
    LucideIcons.messageSquare,
    LucideIcons.messageSquare500,
  ), // message-square
  Ico.star: (
    LucideIcons.star300,
    LucideIcons.star,
    LucideIcons.star500,
  ), // star
  Ico.clock: (
    LucideIcons.clock300,
    LucideIcons.clock,
    LucideIcons.clock500,
  ), // clock
  Ico.settings: (
    LucideIcons.settings300,
    LucideIcons.settings,
    LucideIcons.settings500,
  ), // settings
  Ico.sidebar: (
    LucideIcons.panelLeft300,
    LucideIcons.panelLeft,
    LucideIcons.panelLeft500,
  ), // panel-left
  Ico.close: (LucideIcons.x300, LucideIcons.x, LucideIcons.x500), // x
  Ico.sendHorizontal: (
    LucideIcons.sendHorizontal300,
    LucideIcons.sendHorizontal,
    LucideIcons.sendHorizontal500,
  ), // send-horizontal
  Ico.hourglass: (
    LucideIcons.hourglass300,
    LucideIcons.hourglass,
    LucideIcons.hourglass500,
  ), // hourglass
  Ico.terminal: (
    LucideIcons.terminal300,
    LucideIcons.terminal,
    LucideIcons.terminal500,
  ), // terminal
  Ico.folder: (
    LucideIcons.folder300,
    LucideIcons.folder,
    LucideIcons.folder500,
  ), // folder
  Ico.chevronUp: (
    LucideIcons.chevronUp300,
    LucideIcons.chevronUp,
    LucideIcons.chevronUp500,
  ), // chevronUp
  Ico.monitor: (
    LucideIcons.monitor300,
    LucideIcons.monitor,
    LucideIcons.monitor500,
  ), // monitor
  Ico.monitorPlay: (
    LucideIcons.monitorPlay300,
    LucideIcons.monitorPlay,
    LucideIcons.monitorPlay500,
  ), // monitorPlay
  Ico.laptop: (
    LucideIcons.laptop300,
    LucideIcons.laptop,
    LucideIcons.laptop500,
  ), // laptop
  Ico.server: (
    LucideIcons.server300,
    LucideIcons.server,
    LucideIcons.server500,
  ), // server
  Ico.copy: (
    LucideIcons.copy300,
    LucideIcons.copy,
    LucideIcons.copy500,
  ), // copy
  Ico.pencil: (
    LucideIcons.pencil300,
    LucideIcons.pencil,
    LucideIcons.pencil500,
  ), // pencil
  Ico.refresh: (
    LucideIcons.refreshCw300,
    LucideIcons.refreshCw,
    LucideIcons.refreshCw500,
  ), // refreshCw
  Ico.info: (
    LucideIcons.info300,
    LucideIcons.info,
    LucideIcons.info500,
  ), // info
  Ico.circleCheck: (
    LucideIcons.circleCheck300,
    LucideIcons.circleCheck,
    LucideIcons.circleCheck500,
  ), // circleCheck
  Ico.circleAlert: (
    LucideIcons.circleAlert300,
    LucideIcons.circleAlert,
    LucideIcons.circleAlert500,
  ), // circleAlert
  Ico.triangleAlert: (
    LucideIcons.triangleAlert300,
    LucideIcons.triangleAlert,
    LucideIcons.triangleAlert500,
  ), // triangleAlert
  Ico.pointer: (
    LucideIcons.mousePointer2300,
    LucideIcons.mousePointer2,
    LucideIcons.mousePointer2500,
  ), // mousePointer2
  Ico.pointerClick: (
    LucideIcons.mousePointerClick300,
    LucideIcons.mousePointerClick,
    LucideIcons.mousePointerClick500,
  ), // mousePointerClick
  Ico.activity: (
    LucideIcons.activity300,
    LucideIcons.activity,
    LucideIcons.activity500,
  ), // activity
  Ico.gauge: (
    LucideIcons.gauge300,
    LucideIcons.gauge,
    LucideIcons.gauge500,
  ), // gauge
  Ico.volume: (
    LucideIcons.volume2300,
    LucideIcons.volume2,
    LucideIcons.volume2500,
  ), // volume2
  Ico.logOut: (
    LucideIcons.logOut300,
    LucideIcons.logOut,
    LucideIcons.logOut500,
  ), // logOut
  Ico.gamepad: (
    LucideIcons.gamepad2300,
    LucideIcons.gamepad2,
    LucideIcons.gamepad2500,
  ), // gamepad2
  Ico.qrCode: (
    LucideIcons.qrCode300,
    LucideIcons.qrCode,
    LucideIcons.qrCode500,
  ), // qrCode
  Ico.globe: (
    LucideIcons.globe300,
    LucideIcons.globe,
    LucideIcons.globe500,
  ), // globe
  Ico.radio: (
    LucideIcons.radio300,
    LucideIcons.radio,
    LucideIcons.radio500,
  ), // radio
  Ico.arrowRight: (
    LucideIcons.arrowRight300,
    LucideIcons.arrowRight,
    LucideIcons.arrowRight500,
  ), // arrowRight
  Ico.lock: (
    LucideIcons.lock300,
    LucideIcons.lock,
    LucideIcons.lock500,
  ), // lock
  Ico.userCheck: (
    LucideIcons.userCheck300,
    LucideIcons.userCheck,
    LucideIcons.userCheck500,
  ), // userCheck
  Ico.keyboard: (
    LucideIcons.keyboard300,
    LucideIcons.keyboard,
    LucideIcons.keyboard500,
  ), // keyboard
  Ico.minus: (
    LucideIcons.minus300,
    LucideIcons.minus,
    LucideIcons.minus500,
  ), // minus
  Ico.maximize: (
    LucideIcons.maximize2300,
    LucideIcons.maximize2,
    LucideIcons.maximize2500,
  ), // maximize-2
  Ico.eye: (LucideIcons.eye300, LucideIcons.eye, LucideIcons.eye500), // eye
  Ico.eyeOff: (
    LucideIcons.eyeOff300,
    LucideIcons.eyeOff,
    LucideIcons.eyeOff500,
  ), // eye-off
  Ico.square: (
    LucideIcons.square300,
    LucideIcons.square,
    LucideIcons.square500,
  ), // square
  Ico.circle: (
    LucideIcons.circle300,
    LucideIcons.circle,
    LucideIcons.circle500,
  ), // circle
  Ico.hand: (
    LucideIcons.hand300,
    LucideIcons.hand,
    LucideIcons.hand500,
  ), // hand
  Ico.slash: (
    LucideIcons.slash300,
    LucideIcons.slash,
    LucideIcons.slash500,
  ), // slash
  Ico.pentagon: (
    LucideIcons.pentagon300,
    LucideIcons.pentagon,
    LucideIcons.pentagon500,
  ), // pentagon
  Ico.redo: (
    LucideIcons.redo2300,
    LucideIcons.redo2,
    LucideIcons.redo2500,
  ), // redo-2
  Ico.folderOpen: (
    LucideIcons.folderOpen300,
    LucideIcons.folderOpen,
    LucideIcons.folderOpen500,
  ), // folder-open
  Ico.save: (
    LucideIcons.save300,
    LucideIcons.save,
    LucideIcons.save500,
  ), // save
  Ico.sun: (LucideIcons.sun300, LucideIcons.sun, LucideIcons.sun500), // sun
  Ico.moon: (
    LucideIcons.moon300,
    LucideIcons.moon,
    LucideIcons.moon500,
  ), // moon
  Ico.upload: (
    LucideIcons.upload300,
    LucideIcons.upload,
    LucideIcons.upload500,
  ), // upload
  Ico.download: (
    LucideIcons.download300,
    LucideIcons.download,
    LucideIcons.download500,
  ), // download
  Ico.fileCode: (
    LucideIcons.fileCode300,
    LucideIcons.fileCode,
    LucideIcons.fileCode500,
  ), // file-code
  Ico.rotateCw: (
    LucideIcons.rotateCw300,
    LucideIcons.rotateCw,
    LucideIcons.rotateCw500,
  ), // rotate-cw
  Ico.rotateCcw: (
    LucideIcons.rotateCcw300,
    LucideIcons.rotateCcw,
    LucideIcons.rotateCcw500,
  ), // rotate-ccw
  Ico.flipHorizontal: (
    LucideIcons.flipHorizontal300,
    LucideIcons.flipHorizontal,
    LucideIcons.flipHorizontal500,
  ), // flip-horizontal
  Ico.flipVertical: (
    LucideIcons.flipVertical300,
    LucideIcons.flipVertical,
    LucideIcons.flipVertical500,
  ), // flip-vertical
  Ico.grid: (
    LucideIcons.grid3x3300,
    LucideIcons.grid3x3,
    LucideIcons.grid3x3500,
  ), // grid-3x3
  Ico.group: (
    LucideIcons.group300,
    LucideIcons.group,
    LucideIcons.group500,
  ), // group
  Ico.ungroup: (
    LucideIcons.ungroup300,
    LucideIcons.ungroup,
    LucideIcons.ungroup500,
  ), // ungroup
  Ico.magnet: (
    LucideIcons.magnet300,
    LucideIcons.magnet,
    LucideIcons.magnet500,
  ), // magnet
  Ico.crop: (
    LucideIcons.crop300,
    LucideIcons.crop,
    LucideIcons.crop500,
  ), // crop
  Ico.zoomIn: (
    LucideIcons.zoomIn300,
    LucideIcons.zoomIn,
    LucideIcons.zoomIn500,
  ), // zoom-in
  Ico.zoomOut: (
    LucideIcons.zoomOut300,
    LucideIcons.zoomOut,
    LucideIcons.zoomOut500,
  ), // zoom-out
  Ico.gitCommit: (
    LucideIcons.gitCommit300,
    LucideIcons.gitCommit,
    LucideIcons.gitCommit500,
  ), // git-commit-horizontal
  Ico.rectangleHorizontal: (
    LucideIcons.rectangleHorizontal300,
    LucideIcons.rectangleHorizontal,
    LucideIcons.rectangleHorizontal500,
  ), // rectangle-horizontal
  Ico.layers: (
    LucideIcons.layers300,
    LucideIcons.layers,
    LucideIcons.layers500,
  ), // layers
  Ico.panelRight: (
    LucideIcons.panelRight300,
    LucideIcons.panelRight,
    LucideIcons.panelRight500,
  ), // panel-right
  Ico.timerReset: (
    LucideIcons.timerReset300,
    LucideIcons.timerReset,
    LucideIcons.timerReset500,
  ), // timer-reset
  Ico.shapes: (
    LucideIcons.shapes300,
    LucideIcons.shapes,
    LucideIcons.shapes500,
  ), // shapes
  Ico.library: (
    LucideIcons.library300,
    LucideIcons.library,
    LucideIcons.library500,
  ), // library
  Ico.smartphone: (
    LucideIcons.smartphone300,
    LucideIcons.smartphone,
    LucideIcons.smartphone500,
  ), // smartphone
  Ico.filePlus: (
    LucideIcons.filePlus300,
    LucideIcons.filePlus,
    LucideIcons.filePlus500,
  ), // filePlus
  Ico.spline: (
    LucideIcons.spline300,
    LucideIcons.spline,
    LucideIcons.spline500,
  ), // spline
  Ico.link2: (
    LucideIcons.link2300,
    LucideIcons.link2,
    LucideIcons.link2500,
  ), // link-2
  Ico.unlink2: (
    LucideIcons.unlink2300,
    LucideIcons.unlink2,
    LucideIcons.unlink2500,
  ), // unlink-2
  Ico.scissors: (
    LucideIcons.scissors300,
    LucideIcons.scissors,
    LucideIcons.scissors500,
  ), // scissors
  Ico.squareDashed: (
    LucideIcons.squareDashed300,
    LucideIcons.squareDashed,
    LucideIcons.squareDashed500,
  ), // square-dashed
  Ico.play: (
    LucideIcons.play300,
    LucideIcons.play,
    LucideIcons.play500,
  ), // play
  Ico.pause: (
    LucideIcons.pause300,
    LucideIcons.pause,
    LucideIcons.pause500,
  ), // pause
};

class Icon20 extends StatelessWidget {
  const Icon20(
    this.icon, {
    super.key,
    this.size = IconSize.lg,
    required this.color,
    this.stroke = Stroke.regular,
  });
  final Ico icon;
  final IconSize size;
  final Color color;

  /// Line weight in px; picks the nearest Lucide weight.
  final double stroke;

  @override
  Widget build(BuildContext context) => LucideIcon(
    lucideWeight(icoGlyphs[icon]!, size.px, stroke),
    size: size.px,
    color: color,
  );
}

/// Paints [icon] into [rect] (square) on [canvas], as [Icon20] does.
void paintIco(
  Canvas canvas,
  Ico icon,
  Rect rect,
  Color color, {
  double stroke = Stroke.regular,
}) => paintLucide(
  canvas,
  lucideWeight(icoGlyphs[icon]!, rect.height, stroke),
  rect,
  color,
);
