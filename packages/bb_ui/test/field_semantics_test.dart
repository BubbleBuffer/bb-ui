// Each text field is one text-field node with its label and the tap and focus
// actions, also while unfocused.

import 'package:bb_ui/bb_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(600, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    AppTheme(
      colors: AppColors.light,
      formFactor: FormFactor.desktop,
      child: WidgetsApp(
        color: const Color(0xFF000000),
        builder: (context, _) => Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 320,
            child: Overlay(
              initialEntries: [OverlayEntry(builder: (_) => child)],
            ),
          ),
        ),
      ),
    ),
  );
}

/// The text-field nodes of the tree.
List<SemanticsNode> _textFields(WidgetTester tester) {
  final found = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    if (node.getSemanticsData().flagsCollection.isTextField) found.add(node);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  var root = tester.getSemantics(find.byType(EditableText));
  while (root.parent != null) {
    root = root.parent!;
  }
  visit(root);
  return found;
}

void _expectOneField(
  WidgetTester tester,
  String label, {
  required FocusNode focus,
}) {
  final fields = _textFields(tester);
  expect(fields, hasLength(1));
  final data = fields.single.getSemanticsData();
  expect(data.label, label);
  expect(data.hasAction(SemanticsAction.tap), isTrue);
  expect(data.hasAction(SemanticsAction.focus), isTrue);
  expect(focus.hasFocus, isFalse);
  fields.single.owner!.performAction(fields.single.id, SemanticsAction.focus);
}

void main() {
  testWidgets('SearchField is one text field with tap and focus', (t) async {
    final handle = t.ensureSemantics();
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    await _pump(
      t,
      SearchField(
        controller: controller,
        focusNode: focus,
        onChanged: (_) {},
        placeholder: 'Filter chats',
      ),
    );
    _expectOneField(t, 'Filter chats', focus: focus);
    await t.pump();
    expect(focus.hasFocus, isTrue);
    handle.dispose();
  });

  testWidgets('PlainField in a FieldFrame is one text field', (t) async {
    final handle = t.ensureSemantics();
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    await _pump(
      t,
      FieldFrame(
        child: PlainField(
          controller: controller,
          focusNode: focus,
          style: const TextStyle(fontSize: 14),
          placeholder: 'Path',
          semanticLabel: 'Folder path',
        ),
      ),
    );
    _expectOneField(t, 'Folder path', focus: focus);
    handle.dispose();
  });

  testWidgets('ObscuredField is one text field with tap and focus', (t) async {
    final handle = t.ensureSemantics();
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    await _pump(t, ObscuredField(controller: controller, focusNode: focus));
    _expectOneField(t, 'Passphrase', focus: focus);
    handle.dispose();
  });
}
