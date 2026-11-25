// Standalone specimens of the editor chrome primitives: tool rail, number
// fields, slider, segmented control, colour swatches & picker, tree rows,
// zoom control and property sections, plus a composed mini-workspace.

import 'package:bb_ui/bb_ui.dart';
import 'package:flutter/widgets.dart';

import 'gallery_tokens.dart';

const _initialX = 120.0;
const _initialY = 80.0;
const _initialWidth = 240.0;
const _initialHeight = 160.0;
const _minDim = 1.0;
const _maxCoord = 2000.0;
const _stepFine = 0.5;
const _precisionOne = 1;
const _initialAngle = 15.0;
const _minAngle = -360.0;
const _maxAngle = 360.0;
const _initialOpacity = 0.85;
const _initialSteps = 5.0;
const _minSteps = 1.0;
const _maxSteps = 12.0;
const _stepDivisions = 11;
const _initialZoom = 1.0;
const _zoomFactor = 1.25;
const _minZoom = 0.25;
const _maxZoom = 4.0;
const _depthRoot = 0;
const _depthChild = 1;
const _depthLeaf = 2;
const _treeFlex = 1;
const _inspectorFlex = 2;
const _percentScale = 100;

class _TreeNode {
  const _TreeNode(this.id, this.depth, this.icon);
  final String id;
  final int depth;
  final Ico icon;
}

const _treeNodes = [
  _TreeNode('group', _depthRoot, Ico.folder),
  _TreeNode('rect', _depthChild, Ico.square),
  _TreeNode('circle', _depthLeaf, Ico.circle),
  _TreeNode('text', _depthRoot, Ico.text),
];
const _nodeIds = ['group', 'rect', 'circle', 'text'];

/// Specimen page for editor controls. [onThemeChanged] flips light and dark.
class EditorGallery extends StatefulWidget {
  const EditorGallery({super.key, required this.onThemeChanged});

  final VoidCallback onThemeChanged;

  @override
  State<EditorGallery> createState() => _EditorGalleryState();
}

class _EditorGalleryState extends State<EditorGallery> {
  String _tool = 'pointer';
  double _x = _initialX;
  double _y = _initialY;
  double _width = _initialWidth;
  double _height = _initialHeight;
  double _angle = _initialAngle;
  double _opacity = _initialOpacity;
  double _steps = _initialSteps;
  String _mode = 'design';
  String _align = 'left';
  Color? _fillColor = AppColors.light.accent;
  Color? _strokeColor = AppColors.light.textPrimary;
  Color? _pickerColor = AppColors.light.palette.spaceSky;
  bool _groupExpanded = true;
  final Set<String> _selectedNodes = {'rect'};
  String _anchorNode = 'rect';
  bool _itemVisible = true;
  final Map<String, String> _nodeLabels = {
    'group': 'Header group',
    'rect': 'Backdrop card',
    'circle': 'Accent mark',
    'text': 'Caption',
  };
  final Map<String, GlobalKey<TreeRowState>> _rowKeys = {
    for (final id in _nodeIds) id: GlobalKey<TreeRowState>(),
  };

  List<_TreeNode> get _visibleNodes => [
    for (final n in _treeNodes)
      if (_groupExpanded || n.depth == _depthRoot) n,
  ];

  void _pressNode(String id, TreeRowPress press) {
    final order = [for (final n in _visibleNodes) n.id];
    setState(() {
      if (press.shift) {
        final a = order.indexOf(_anchorNode);
        final b = order.indexOf(id);
        final lo = a < b ? a : b;
        final hi = a < b ? b : a;
        _selectedNodes
          ..clear()
          ..addAll(order.sublist(lo < 0 ? 0 : lo, hi + 1));
        return;
      }
      if (press.toggle) {
        if (!_selectedNodes.remove(id)) _selectedNodes.add(id);
      } else {
        _selectedNodes
          ..clear()
          ..add(id);
      }
      _anchorNode = id;
    });
  }

  Future<void> _openNodeMenu(String id, Offset at) async {
    setState(() {
      if (!_selectedNodes.contains(id)) {
        _selectedNodes
          ..clear()
          ..add(id);
        _anchorNode = id;
      }
    });
    final action = await showPopover<String>(
      context,
      at & Size.zero,
      (_) => MenuList(
        width: Widths.menu,
        children: [
          MenuItem(
            label: 'Rename',
            icon: Ico.pencil,
            onTap: () => Navigator.of(context).pop('rename'),
          ),
          const MenuSeparator(),
          MenuItem(
            label: _itemVisible ? 'Hide' : 'Show',
            icon: _itemVisible ? Ico.eyeOff : Ico.eye,
            onTap: () => Navigator.of(context).pop('visibility'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'rename') {
      _rowKeys[id]?.currentState?.startRename();
    } else if (action == 'visibility') {
      setState(() => _itemVisible = !_itemVisible);
    }
  }

  Widget _treeRow(_TreeNode node) {
    final id = node.id;
    final isGroup = id == 'group';
    return TreeRow(
      key: _rowKeys[id],
      label: _nodeLabels[id]!,
      depth: node.depth,
      icon: node.icon,
      expanded: isGroup ? _groupExpanded : null,
      selected: _selectedNodes.contains(id),
      trailingAlwaysVisible: id == 'circle',
      onToggleExpanded: isGroup
          ? () => setState(() => _groupExpanded = !_groupExpanded)
          : null,
      onPressed: (press) => _pressNode(id, press),
      onSecondaryTap: (at) => _openNodeMenu(id, at),
      onRename: (name) => setState(() => _nodeLabels[id] = name),
      trailing: id == 'text'
          ? const []
          : [
              IconBtn(
                _itemVisible ? Ico.eye : Ico.eyeOff,
                size: ControlSize.xs,
                glyph: IconSize.xs,
                semanticLabel: 'Toggle visibility',
                onTap: () => setState(() => _itemVisible = !_itemVisible),
              ),
            ],
    );
  }

  double _zoom = _initialZoom;

  List<Color> _swatches(AppColors c) => [
    c.accent,
    c.palette.spacePaw,
    c.palette.spaceMoss,
    c.palette.spaceSun,
    c.palette.spaceSky,
    c.palette.spaceDuvet,
  ];

  Future<void> _openPicker(
    BuildContext triggerContext, {
    required Color? current,
    required ValueChanged<Color?> onUpdate,
  }) async {
    final before = current;
    await showColorPicker(
      triggerContext,
      color: current,
      swatches: _swatches(triggerContext.colors),
      onChanged: onUpdate,
      onChangeEnd: onUpdate,
      onChangeCancel: (_) => onUpdate(before),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final compact = context.sizeClass.isCompact;
    final swatches = _swatches(c);

    final toolButtons = [
      ToolButton(
        icon: Ico.pointer,
        tooltip: 'Select',
        shortcut: 'V',
        selected: _tool == 'pointer',
        onPressed: () => setState(() => _tool = 'pointer'),
      ),
      ToolButton(
        icon: Ico.hand,
        tooltip: 'Pan',
        shortcut: 'H',
        selected: _tool == 'hand',
        onPressed: () => setState(() => _tool = 'hand'),
      ),
      const ToolRailSeparator(),
      ToolButton(
        icon: Ico.square,
        tooltip: 'Rectangle',
        shortcut: 'R',
        selected: _tool == 'rect',
        onPressed: () => setState(() => _tool = 'rect'),
      ),
      ToolButton(
        icon: Ico.circle,
        tooltip: 'Ellipse',
        shortcut: 'O',
        selected: _tool == 'ellipse',
        onPressed: () => setState(() => _tool = 'ellipse'),
      ),
      ToolButton(
        icon: Ico.text,
        tooltip: 'Text',
        shortcut: 'T',
        selected: _tool == 'text',
        onPressed: () => setState(() => _tool = 'text'),
      ),
      const ToolButton(icon: Ico.lock, tooltip: 'Locked tool', onPressed: null),
    ];

    final treePanel = Container(
      padding: const EdgeInsets.all(Space.xs),
      decoration: BoxDecoration(
        color: c.bgElevated,
        borderRadius: Radii.panel,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.xs,
              vertical: Space.xxs,
            ),
            child: Text(
              'Outline',
              style: ts(
                context.type.uiSmall,
                c.textSecondary,
                weight: Weight.strong,
              ),
            ),
          ),
          for (final node in _visibleNodes) _treeRow(node),
        ],
      ),
    );

    final inspectorPanel = Container(
      decoration: BoxDecoration(
        color: c.bgElevated,
        borderRadius: Radii.panel,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PropertySection(
            title: 'Geometry',
            children: [
              PropertyRow(
                label: 'Position',
                secondary: NumberField(
                  label: 'Y',
                  unit: 'px',
                  value: _y,
                  min: -_maxCoord,
                  max: _maxCoord,
                  step: _stepFine,
                  onChanged: (v) => setState(() => _y = v),
                  onChangeEnd: (v) => setState(() => _y = v),
                ),
                child: NumberField(
                  label: 'X',
                  unit: 'px',
                  value: _x,
                  min: -_maxCoord,
                  max: _maxCoord,
                  step: _stepFine,
                  onChanged: (v) => setState(() => _x = v),
                  onChangeEnd: (v) => setState(() => _x = v),
                ),
              ),
              PropertyRow(
                label: 'Size',
                secondary: NumberField(
                  label: 'H',
                  unit: 'px',
                  value: _height,
                  min: _minDim,
                  max: _maxCoord,
                  onChanged: (v) => setState(() => _height = v),
                  onChangeEnd: (v) => setState(() => _height = v),
                ),
                child: NumberField(
                  label: 'W',
                  unit: 'px',
                  value: _width,
                  min: _minDim,
                  max: _maxCoord,
                  onChanged: (v) => setState(() => _width = v),
                  onChangeEnd: (v) => setState(() => _width = v),
                ),
              ),
              PropertyRow(
                label: 'Align',
                child: Segmented<String>(
                  value: _align,
                  expand: true,
                  options: const [
                    SegmentOption(value: 'left', label: 'L'),
                    SegmentOption(value: 'center', label: 'C'),
                    SegmentOption(value: 'right', label: 'R'),
                  ],
                  onChanged: (v) => setState(() => _align = v),
                ),
              ),
            ],
          ),
          PropertySection(
            title: 'Appearance',
            children: [
              PropertyRow(
                label: 'Fill',
                child: Row(
                  spacing: Space.sm,
                  children: [
                    Builder(
                      builder: (b) => SwatchButton(
                        key: const ValueKey('inspector-fill-swatch'),
                        color: _fillColor,
                        tooltip: 'Pick fill colour',
                        onPressed: () => _openPicker(
                          b,
                          current: _fillColor,
                          onUpdate: (next) => setState(() => _fillColor = next),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _fillColor == null
                            ? 'None'
                            : formatHexColor(_fillColor!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ts(
                          context.type.codeSmall,
                          c.textPrimary,
                          mono: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PropertyRow(
                label: 'Stroke',
                child: Row(
                  spacing: Space.sm,
                  children: [
                    Builder(
                      builder: (b) => SwatchButton(
                        key: const ValueKey('inspector-stroke-swatch'),
                        color: _strokeColor,
                        tooltip: 'Pick stroke colour',
                        onPressed: () => _openPicker(
                          b,
                          current: _strokeColor,
                          onUpdate: (next) =>
                              setState(() => _strokeColor = next),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _strokeColor == null
                            ? 'None'
                            : formatHexColor(_strokeColor!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ts(
                          context.type.codeSmall,
                          c.textPrimary,
                          mono: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PropertyRow(
                label: 'Opacity',
                child: BbSlider(
                  value: _opacity,
                  semanticLabel: 'Opacity',
                  onChanged: (v) => setState(() => _opacity = v),
                  onChangeEnd: (v) => setState(() => _opacity = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return ColoredBox(
      color: c.bgPrimary,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: PageWidths.wide),
              child: Padding(
                padding: EdgeInsets.all(compact ? Space.xl : Space.xxxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: Space.xl,
                      runSpacing: Space.md,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Editor controls',
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
                      'Tool rails, scrubbable number fields, sliders, segmented '
                      'switches, colour pickers, tree rows, zoom controls and '
                      'property sections.',
                      style: ts(context.type.body, c.textSecondary),
                    ),
                    const _Section('Tool rail'),
                    Wrap(
                      spacing: Space.xl,
                      runSpacing: Space.lg,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      children: [
                        ToolRail(
                          semanticLabel: 'Vertical tools',
                          children: toolButtons,
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ToolRail(
                            direction: Axis.horizontal,
                            semanticLabel: 'Horizontal tools',
                            children: toolButtons,
                          ),
                        ),
                      ],
                    ),
                    const _Section('Number fields and sliders'),
                    Wrap(
                      spacing: Space.lg,
                      runSpacing: Space.md,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: Specimen.numberField,
                          child: NumberField(
                            label: 'Angle',
                            unit: '°',
                            value: _angle,
                            min: _minAngle,
                            max: _maxAngle,
                            step: _stepFine,
                            precision: _precisionOne,
                            onChanged: (v) => setState(() => _angle = v),
                            onChangeEnd: (v) => setState(() => _angle = v),
                          ),
                        ),
                        SizedBox(
                          width: Specimen.numberField,
                          child: const NumberField(
                            label: 'Z',
                            unit: 'px',
                            value: 0,
                            enabled: false,
                          ),
                        ),
                        SizedBox(
                          width: Specimen.sliderWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              BbSlider(
                                value: _opacity,
                                semanticLabel: 'Continuous opacity',
                                onChanged: (v) => setState(() => _opacity = v),
                                onChangeEnd: (v) =>
                                    setState(() => _opacity = v),
                              ),
                              Text(
                                'Opacity: ${(_opacity * _percentScale).round()}%',
                                style: ts(
                                  context.type.uiSmall,
                                  c.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: Specimen.sliderWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              BbSlider(
                                value: _steps,
                                min: _minSteps,
                                max: _maxSteps,
                                divisions: _stepDivisions,
                                semanticLabel: 'Discrete steps',
                                onChanged: (v) => setState(() => _steps = v),
                                onChangeEnd: (v) => setState(() => _steps = v),
                              ),
                              Text(
                                'Steps: ${_steps.round()}',
                                style: ts(
                                  context.type.uiSmall,
                                  c.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: Specimen.sliderWidth,
                          child: const BbSlider(
                            value: _initialOpacity,
                            semanticLabel: 'Disabled slider',
                          ),
                        ),
                      ],
                    ),
                    const _Section('Segmented controls'),
                    Wrap(
                      spacing: Space.lg,
                      runSpacing: Space.md,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Segmented<String>(
                            value: _mode,
                            options: const [
                              SegmentOption(value: 'design', label: 'Design'),
                              SegmentOption(value: 'animate', label: 'Animate'),
                              SegmentOption(value: 'preview', label: 'Preview'),
                            ],
                            onChanged: (v) => setState(() => _mode = v),
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Segmented<String>(
                            value: _align,
                            options: const [
                              SegmentOption(
                                value: 'left',
                                icon: Ico.indent,
                                tooltip: 'Align left',
                              ),
                              SegmentOption(
                                value: 'center',
                                icon: Ico.divider,
                                tooltip: 'Align center',
                              ),
                              SegmentOption(
                                value: 'right',
                                icon: Ico.outdent,
                                tooltip: 'Align right',
                              ),
                            ],
                            onChanged: (v) => setState(() => _align = v),
                          ),
                        ),
                        const SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Segmented<String>(
                            value: 'design',
                            options: [
                              SegmentOption(value: 'design', label: 'Locked'),
                              SegmentOption(value: 'other', label: 'Other'),
                            ],
                            onChanged: null,
                          ),
                        ),
                      ],
                    ),
                    const _Section('Colour swatches and picker'),
                    Wrap(
                      spacing: Space.xl,
                      runSpacing: Space.lg,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      children: [
                        SizedBox(
                          width: compact ? double.infinity : Specimen.column,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: Space.md,
                            children: [
                              Wrap(
                                spacing: Space.sm,
                                runSpacing: Space.sm,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  SwatchButton(
                                    color: c.accent,
                                    selected: true,
                                    tooltip: 'Selected swatch',
                                    onPressed: () {},
                                  ),
                                  SwatchButton(
                                    color: c.accent.withValues(
                                      alpha: Alpha.muted,
                                    ),
                                    tooltip: 'Translucent swatch',
                                    onPressed: () {},
                                  ),
                                  SwatchButton(
                                    color: null,
                                    tooltip: 'None',
                                    onPressed: () {},
                                  ),
                                  SwatchButton(color: c.infoBg),
                                ],
                              ),
                              SwatchGrid(
                                colors: swatches,
                                selected: _pickerColor,
                                allowNone: true,
                                onSelected: (next) =>
                                    setState(() => _pickerColor = next),
                              ),
                              Builder(
                                builder: (b) => SecondaryButton(
                                  label: 'Open picker popover',
                                  onTap: () => _openPicker(
                                    b,
                                    current: _pickerColor,
                                    onUpdate: (next) =>
                                        setState(() => _pickerColor = next),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(Space.md),
                          decoration: BoxDecoration(
                            color: c.bgElevated,
                            borderRadius: Radii.panel,
                            border: Border.all(color: c.border),
                          ),
                          child: ColorPickerPanel(
                            color: _pickerColor,
                            swatches: swatches,
                            onChanged: (next) =>
                                setState(() => _pickerColor = next),
                            onChangeEnd: (next) =>
                                setState(() => _pickerColor = next),
                            onChangeCancel: (prev) =>
                                setState(() => _pickerColor = prev),
                          ),
                        ),
                      ],
                    ),
                    const _Section('Zoom control'),
                    Wrap(
                      spacing: Space.lg,
                      runSpacing: Space.md,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ZoomControl(
                            zoom: _zoom,
                            min: _minZoom,
                            max: _maxZoom,
                            onZoomOut: () => setState(
                              () => _zoom = (_zoom / _zoomFactor).clamp(
                                _minZoom,
                                _maxZoom,
                              ),
                            ),
                            onZoomIn: () => setState(
                              () => _zoom = (_zoom * _zoomFactor).clamp(
                                _minZoom,
                                _maxZoom,
                              ),
                            ),
                            onLabelPressed: () =>
                                setState(() => _zoom = _initialZoom),
                            onFit: () => setState(() => _zoom = _initialZoom),
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ZoomControl(
                            zoom: _minZoom,
                            min: _minZoom,
                            max: _maxZoom,
                            onZoomOut: () {},
                            onZoomIn: () {},
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ZoomControl(
                            zoom: _maxZoom,
                            min: _minZoom,
                            max: _maxZoom,
                            onZoomOut: () {},
                            onZoomIn: () {},
                          ),
                        ),
                      ],
                    ),
                    const _Section('Composed workspace'),
                    if (compact)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: Space.md,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ToolRail(
                              direction: Axis.horizontal,
                              children: toolButtons,
                            ),
                          ),
                          treePanel,
                          inspectorPanel,
                        ],
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: Space.lg,
                        children: [
                          ToolRail(children: toolButtons),
                          Expanded(flex: _treeFlex, child: treePanel),
                          Expanded(flex: _inspectorFlex, child: inspectorPanel),
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
