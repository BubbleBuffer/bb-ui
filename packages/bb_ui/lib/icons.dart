// The app's icons: Lucide glyphs (lucide.dart) behind the app's own names.
// New UI uses these enums (Ico here, Ix in icon_x.dart), never another set.

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'lucide.dart';

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
};

class Icon20 extends StatelessWidget {
  const Icon20(
    this.icon, {
    super.key,
    this.size = 20,
    required this.color,
    this.stroke = 1.5,
  });
  final Ico icon;
  final double size;
  final Color color;

  /// Line weight in px; picks the nearest Lucide weight.
  final double stroke;

  @override
  Widget build(BuildContext context) => LucideIcon(
    lucideWeight(icoGlyphs[icon]!, size, stroke),
    size: size,
    color: color,
  );
}

/// Paints [icon] into [rect] (square) on [canvas], as [Icon20] does.
void paintIco(
  Canvas canvas,
  Ico icon,
  Rect rect,
  Color color, {
  double stroke = 1.5,
}) => paintLucide(
  canvas,
  lucideWeight(icoGlyphs[icon]!, rect.height, stroke),
  rect,
  color,
);
