// Code entry: the pure grouping functions, the formatter's caret handling and
// the field typing and pasting through the real text input.

import 'package:bb_ui/bb_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _id = [4, 4, 4, 4];

TextEditingValue _edit(String text, int caret) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: caret),
);

void main() {
  group('formatCode', () {
    test('upper-cases and groups with a separator between groups', () {
      expect(formatCode('7kq2m9x', const [4, 4]), '7KQ2-M9X');
      expect(formatCode('h4pdr8tnb7qk2m9x', _id), 'H4PD-R8TN-B7QK-2M9X');
    });

    test('never ends in a separator', () {
      expect(formatCode('abcd', const [4, 4]), 'ABCD');
      expect(formatCode('abcde', const [4, 4]), 'ABCD-E');
    });

    test('drops punctuation and spaces and stops at the total length', () {
      expect(
        formatCode('h4pd r8tn_b7qk.2m9x-extra', _id),
        'H4PD-R8TN-B7QK-2M9X',
      );
      expect(codeCharacters('ab-cd ef', const [3, 3]), 'ABCDEF');
      expect(codeCharacters('', _id), '');
    });

    test('takes another separator', () {
      expect(formatCode('482913', const [3, 3], separator: ' '), '482 913');
    });
  });

  group('CodeFormatter', () {
    const formatter = CodeFormatter(_id);

    test(
      'typing the fifth character adds the separator and moves the caret',
      () {
        final v = formatter.formatEditUpdate(
          _edit('ABCD', 4),
          _edit('ABCDe', 5),
        );
        expect(v.text, 'ABCD-E');
        expect(v.selection.baseOffset, 6);
      },
    );

    test('typing inside a group keeps the caret after the typed character', () {
      final v = formatter.formatEditUpdate(_edit('ABCD', 4), _edit('ABxCD', 3));
      expect(v.text, 'ABXC-D');
      expect(v.selection.baseOffset, 3);
    });

    test('a pasted code with separators and lower case is normalised', () {
      final v = formatter.formatEditUpdate(
        _edit('', 0),
        _edit('h4pd-r8tn b7qk 2m9x', 19),
      );
      expect(v.text, 'H4PD-R8TN-B7QK-2M9X');
      expect(v.selection.baseOffset, 19);
    });

    test('Backspace over a separator deletes the character before it', () {
      final v = formatter.formatEditUpdate(
        _edit('ABCD-EF', 5),
        _edit('ABCDEF', 4),
      );
      expect(v.text, 'ABCE-F');
      expect(v.selection.baseOffset, 3);
    });

    test('Backspace on the first character of a group works as usual', () {
      final v = formatter.formatEditUpdate(
        _edit('ABCD-E', 6),
        _edit('ABCD-', 5),
      );
      expect(v.text, 'ABCD');
      expect(v.selection.baseOffset, 4);
    });
  });

  testWidgets('CodeField formats what is typed and pasted', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var changes = 0;
    await tester.pumpWidget(
      AppTheme(
        colors: AppColors.darkTheme,
        formFactor: FormFactor.desktop,
        child: WidgetsApp(
          color: const Color(0xFF000000),
          builder: (context, _) => Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (_) => Center(
                  child: SizedBox(
                    width: 360,
                    child: CodeField(
                      key: const ValueKey('code'),
                      controller: controller,
                      groups: _id,
                      placeholder: 'XXXX-XXXX-XXXX-XXXX',
                      semanticLabel: 'PC ID',
                      onChanged: (_) => changes++,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('XXXX-XXXX-XXXX-XXXX'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'h4pd r8tn');
    await tester.pump();
    expect(controller.text, 'H4PD-R8TN');
    expect(find.text('XXXX-XXXX-XXXX-XXXX'), findsNothing);
    await tester.enterText(find.byType(EditableText), 'h4pdr8tnb7qk2m9xzz');
    await tester.pump();
    expect(controller.text, 'H4PD-R8TN-B7QK-2M9X');
    expect(codeCharacters(controller.text, _id), 'H4PDR8TNB7QK2M9X');
    expect(changes, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}
