// Standalone specimens of public primitives, without an agent or host.

import 'package:bb_ui/bb_ui.dart';
import 'package:flutter/widgets.dart';

class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key, this.initialBrightness = Brightness.light});

  final Brightness initialBrightness;

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  late Brightness _brightness = widget.initialBrightness;

  @override
  Widget build(BuildContext context) => WidgetsApp(
    title: 'UI primitives',
    color: AppColors.light.desk,
    debugShowCheckedModeBanner: false,
    pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondary) => builder(context),
    ),
    // The theme wraps the Navigator and its Overlay, including text handles.
    builder: (context, child) => LayoutBuilder(
      builder: (context, constraints) => AppTheme(
        colors: _brightness == Brightness.dark
            ? AppColors.darkTheme
            : AppColors.light,
        formFactor: FormFactor.forWidth(constraints.maxWidth),
        child: child!,
      ),
    ),
    home: PrimitiveGallery(
      onThemeChanged: () => setState(() {
        _brightness = _brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light;
      }),
    ),
  );
}

class PrimitiveGallery extends StatefulWidget {
  const PrimitiveGallery({super.key, required this.onThemeChanged});

  final VoidCallback onThemeChanged;

  @override
  State<PrimitiveGallery> createState() => _PrimitiveGalleryState();
}

class _PrimitiveGalleryState extends State<PrimitiveGallery> {
  final _name = TextEditingController(text: 'Sample collection');
  int _count = 0;
  bool _checked = true;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ColoredBox(
      color: c.bgPrimary,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Padding(
                padding: EdgeInsets.all(context.mobile ? 20 : 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'UI primitives',
                          style: tsDisplay(context.type.h1, c.textPrimary),
                        ),
                        TextBtn(
                          c.dark ? 'Use light theme' : 'Use dark theme',
                          key: const ValueKey('theme-toggle'),
                          onTap: widget.onThemeChanged,
                          height: 44,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Try the controls, edit a field, and open a stack. '
                      'Every specimen uses the same light and dark tokens.',
                      style: ts(context.type.body, c.textSecondary),
                    ),
                    const _Section('Buttons'),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PrimaryButton(
                          label: 'Add sample',
                          height: 46,
                          onTap: () => setState(() => _count++),
                        ),
                        SizedBox(
                          width: 120,
                          child: SecondaryButton(
                            label: 'Reset',
                            height: 46,
                            onTap: () => setState(() => _count = 0),
                          ),
                        ),
                        const OutlineButton(label: 'Unavailable', onTap: null),
                        IconBtn(
                          Ico.check,
                          size: 46,
                          semanticLabel: 'Add with icon',
                          onTap: () => setState(() => _count++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Samples added: $_count',
                      style: ts(context.type.ui, c.textSecondary),
                    ),
                    const _Section('Fields and selection'),
                    Text(
                      'Collection name',
                      style: ts(context.type.ui, c.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Collection name',
                      textField: true,
                      child: SettingsField(
                        controller: _name,
                        placeholder: 'Name a collection',
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Preview: ${_name.text}',
                      style: ts(context.type.uiSmall, c.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        StacksCheckbox(
                          key: const ValueKey('selection-checkbox'),
                          checked: _checked,
                          size: 32,
                          onChanged: (value) =>
                              setState(() => _checked = value),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _checked
                                ? 'Sample selected'
                                : 'Sample not selected',
                            style: ts(context.type.ui, c.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    const _Section('References and stacks'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ReferenceChip(label: 'Reference', colour: c.accent),
                        ReferenceChip(label: 'Collection', colour: c.pawBg),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FoldableStackCard(
                      edge: c.accent,
                      label: 'Three items',
                      title: 'Sample stack',
                      stacked: true,
                      faceKey: const ValueKey('stack-toggle'),
                      peek: Text(
                        'Open to see the contents.',
                        style: ts(context.type.uiSmall, c.textSecondary),
                      ),
                      body: Text(
                        'A stack keeps related items together.',
                        style: ts(context.type.body, c.textPrimary),
                      ),
                    ),
                    const _Section('Semantic colours'),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final (label, colour) in [
                          ('Surface', c.bgSecondary),
                          ('Accent', c.accent),
                          ('Constructive', c.okBg),
                          ('Information', c.infoBg),
                          ('Attention', c.attnBg),
                          ('Danger', c.dangerBg),
                        ])
                          SizedBox(
                            width: 128,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: colour,
                                    border: Border.all(color: c.borderStrong),
                                    borderRadius: Radii.field,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  label,
                                  style: ts(
                                    context.type.uiSmall,
                                    c.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 32, bottom: 16),
    child: SettingsHeading(label),
  );
}
