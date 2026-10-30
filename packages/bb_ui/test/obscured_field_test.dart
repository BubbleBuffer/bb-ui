// The obscured field: typed text is hidden, edits and submit still reach the caller.

import 'package:bb_ui/bb_ui.dart';
import 'package:flutter/services.dart';
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
          child: SizedBox(width: 320, child: child),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('hides the text and shows the placeholder until typing', (
    t,
  ) async {
    final controller = TextEditingController();
    final changes = <String>[];
    String? submitted;
    await _pump(
      t,
      ObscuredField(
        controller: controller,
        placeholder: 'Passphrase',
        onChanged: changes.add,
        onSubmitted: (v) => submitted = v,
      ),
    );
    expect(find.text('Passphrase'), findsOneWidget);

    await t.tap(find.byType(EditableText));
    await t.pump();
    await t.enterText(find.byType(EditableText), 'hunter2');
    await t.pump();
    expect(changes, ['hunter2']);
    expect(find.text('Passphrase'), findsNothing);

    final editable = t.widget<EditableText>(find.byType(EditableText));
    expect(editable.obscureText, isTrue);
    expect(editable.autocorrect, isFalse);
    expect(editable.enableSuggestions, isFalse);
    expect(editable.enableInteractiveSelection, isFalse);

    await t.testTextInput.receiveAction(TextInputAction.done);
    expect(submitted, 'hunter2');
  });

  testWidgets('is announced as an obscured text field', (t) async {
    final handle = t.ensureSemantics();
    await _pump(
      t,
      ObscuredField(
        controller: TextEditingController(),
        semanticLabel: 'Key passphrase',
      ),
    );
    final node = t.getSemantics(find.byType(EditableText));
    expect(node.flagsCollection.isTextField, isTrue);
    expect(node.flagsCollection.isObscured, isTrue);
    expect(node.label, contains('Key passphrase'));
    handle.dispose();
  });
}
