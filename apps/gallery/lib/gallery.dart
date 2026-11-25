// Standalone specimens of public primitives, without an agent or host.

import 'package:bb_ui/bb_ui.dart';
import 'package:flutter/widgets.dart';

import 'gallery_tokens.dart';
import 'devices_gallery.dart';
import 'editor_gallery.dart';
import 'palette_gallery.dart';
import 'search_gallery.dart';
import 'session_gallery.dart';

/// How far text follows the system text size.
const _maxTextScale = 2.0;

/// Which specimen page the gallery shows.
enum GalleryScene { primitives, search, palette, devices, session, editor }

class GalleryApp extends StatefulWidget {
  const GalleryApp({
    super.key,
    this.initialBrightness = Brightness.light,
    this.scene = GalleryScene.primitives,
  });

  final Brightness initialBrightness;
  final GalleryScene scene;

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
    // A narrow window stands in for a phone: compact and by touch. Text
    // follows the system size up to double.
    builder: (context, child) => LayoutBuilder(
      builder: (context, constraints) {
        final sizeClass = SizeClass.forWidth(constraints.maxWidth);
        return MediaQuery.withClampedTextScaling(
          maxScaleFactor: _maxTextScale,
          child: SizeClassScope(
            sizeClass: sizeClass,
            child: AppTheme(
              colors: _brightness == Brightness.dark
                  ? AppColors.darkTheme
                  : AppColors.light,
              density: sizeClass.isCompact ? Density.touch : Density.pointer,
              child: child!,
            ),
          ),
        );
      },
    ),
    home: switch (widget.scene) {
      GalleryScene.primitives => PrimitiveGallery(onThemeChanged: _toggleTheme),
      GalleryScene.search => SearchGallery(onThemeChanged: _toggleTheme),
      GalleryScene.palette => PaletteGallery(onThemeChanged: _toggleTheme),
      GalleryScene.devices => DevicesGallery(onThemeChanged: _toggleTheme),
      GalleryScene.session => SessionGallery(onThemeChanged: _toggleTheme),
      GalleryScene.editor => EditorGallery(onThemeChanged: _toggleTheme),
    },
  );

  void _toggleTheme() => setState(() {
    _brightness = _brightness == Brightness.light
        ? Brightness.dark
        : Brightness.light;
  });
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
              constraints: const BoxConstraints(maxWidth: PageWidths.standard),
              child: Padding(
                padding: EdgeInsets.all(
                  context.adaptive(compact: Space.xl, medium: Space.xxxl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: Space.xl,
                      runSpacing: Space.md,
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
                          size: ControlSize.xl,
                        ),
                      ],
                    ),
                    const Gap(Space.md),
                    Text(
                      'Try the controls, edit a field, and open a stack. '
                      'Every specimen uses the same light and dark tokens.',
                      style: ts(context.type.body, c.textSecondary),
                    ),
                    const _Section('Buttons'),
                    Wrap(
                      spacing: Space.md,
                      runSpacing: Space.md,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PrimaryButton(
                          label: 'Add sample',
                          size: ControlSize.xxl,
                          onTap: () => setState(() => _count++),
                        ),
                        SizedBox(
                          width: Specimen.buttonWidth,
                          child: SecondaryButton(
                            label: 'Reset',
                            size: ControlSize.xxl,
                            onTap: () => setState(() => _count = 0),
                          ),
                        ),
                        const OutlineButton(label: 'Unavailable', onTap: null),
                        IconBtn(
                          Ico.check,
                          size: ControlSize.xxl,
                          semanticLabel: 'Add with icon',
                          onTap: () => setState(() => _count++),
                        ),
                      ],
                    ),
                    const Gap(Space.md),
                    Text(
                      'Samples added: $_count',
                      style: ts(context.type.ui, c.textSecondary),
                    ),
                    const _Section('Fields and selection'),
                    Text(
                      'Collection name',
                      style: ts(context.type.ui, c.textPrimary),
                    ),
                    const Gap(Space.sm),
                    Semantics(
                      label: 'Collection name',
                      textField: true,
                      child: SettingsField(
                        controller: _name,
                        placeholder: 'Name a collection',
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const Gap(Space.sm),
                    Text(
                      'Preview: ${_name.text}',
                      style: ts(context.type.uiSmall, c.textSecondary),
                    ),
                    const Gap(Space.lg),
                    Row(
                      children: [
                        StacksCheckbox(
                          key: const ValueKey('selection-checkbox'),
                          checked: _checked,
                          size: Specimen.checkbox,
                          onChanged: (value) =>
                              setState(() => _checked = value),
                        ),
                        const Gap(Space.md),
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
                      spacing: Space.sm,
                      runSpacing: Space.sm,
                      children: [
                        ReferenceChip(label: 'Reference', colour: c.accent),
                        ReferenceChip(label: 'Collection', colour: c.pawBg),
                      ],
                    ),
                    const Gap(Space.lg),
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
                      spacing: Space.md,
                      runSpacing: Space.md,
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
                            width: Specimen.swatchWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  height: ControlSize.xxl.height,
                                  decoration: BoxDecoration(
                                    color: colour,
                                    border: Border.all(color: c.borderStrong),
                                    borderRadius: Radii.field,
                                  ),
                                ),
                                const Gap(Space.xs),
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
    padding: const EdgeInsets.only(top: Space.xxl, bottom: Space.lg),
    child: SettingsHeading(label),
  );
}
