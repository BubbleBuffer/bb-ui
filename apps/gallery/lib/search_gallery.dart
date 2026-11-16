// A specimen of the search widgets over sample results, without a backend: the
// panel with its filters and keyboard selection, and the compact list a phone
// draws.

import 'package:bb_ui/bb_ui.dart';
import 'package:flutter/widgets.dart';

import 'gallery_tokens.dart';

enum _Kind { document, conversation }

/// On a phone a result's title may wrap once.
const _compactTitleLines = 2;

class _Sample {
  const _Sample(this.id, this.kind, this.title, this.snippet, [this.path = '']);
  final String id;
  final _Kind kind;
  final String title;
  final String snippet;
  final String path;
}

const _samples = [
  _Sample(
    'garden-plan',
    _Kind.document,
    'Garden plan',
    'Raised beds along the south fence, herbs by the kitchen door.',
    'Projects / House',
  ),
  _Sample(
    'garden-tools',
    _Kind.document,
    'Tools and supplies',
    'Order a new spade and a hose reel before the garden opens.',
    'Projects / House',
  ),
  _Sample(
    'seed-list',
    _Kind.document,
    'Seed list',
    'Beans, courgettes and two kinds of tomato for the garden.',
  ),
  _Sample(
    'garden-chat',
    _Kind.conversation,
    'Garden planning › Raised beds',
    'Settled on four beds of 1.2 by 2.4 metres, cedar boards.',
  ),
  _Sample(
    'watering-chat',
    _Kind.conversation,
    'Garden planning › Watering',
    'A drip line on a timer keeps the garden alive over the summer.',
  ),
];

/// The search specimen. [onThemeChanged] flips light and dark.
class SearchGallery extends StatefulWidget {
  const SearchGallery({super.key, required this.onThemeChanged});

  final VoidCallback onThemeChanged;

  @override
  State<SearchGallery> createState() => _SearchGalleryState();
}

class _SearchGalleryState extends State<SearchGallery> {
  final _query = TextEditingController(text: 'garden');
  _Kind? _kind;
  String _picked = 'Nothing opened yet';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<String> get _terms => [
    for (final term in _query.text.split(' '))
      if (term.isNotEmpty) term,
  ];

  SearchResult _result(
    _Sample sample, {
    bool compact = false,
    String keyPrefix = 'sample',
  }) => SearchResult(
    id: sample.id,
    title: sample.title,
    titleHighlights: termHighlights(sample.title, _terms),
    titleMaxLines: compact ? _compactTitleLines : 1,
    secondary: sample.path,
    snippet: sample.snippet,
    snippetHighlights: termHighlights(sample.snippet, _terms),
    icon: sample.kind == _Kind.document ? Ico.page : Ico.comment,
    typeLabel: sample.kind == _Kind.document ? 'Document' : 'Chat',
    rowKey: ValueKey('$keyPrefix-${sample.id}'),
  );

  /// The samples that match the query and the chosen kind, grouped by kind.
  List<SearchResultSection>? _sections({bool compact = false}) {
    if (_terms.isEmpty) return null;
    bool matches(_Sample s) {
      final text = '${s.title} ${s.snippet}'.toLowerCase();
      return _terms.every((t) => text.contains(t.toLowerCase()));
    }

    final found = [
      for (final s in _samples)
        if ((_kind == null || _kind == s.kind) && matches(s)) s,
    ];
    return [
      for (final (kind, label) in [
        (_Kind.document, 'Documents'),
        (_Kind.conversation, 'Chats'),
      ])
        if (found.any((s) => s.kind == kind))
          SearchResultSection(
            id: kind.name,
            label: label,
            results: [
              for (final s in found)
                if (s.kind == kind)
                  _result(
                    s,
                    compact: compact,
                    keyPrefix: compact ? 'phone' : 'sample',
                  ),
            ],
          ),
    ];
  }

  void _pick(SearchResult result) => setState(() {
    _picked = 'Opened: ${result.title}';
  });

  Widget _chips() {
    SearchTypeChip chip(String id, String label, _Kind? kind) => SearchTypeChip(
      id: id,
      label: label,
      selected: _kind == kind,
      onTap: () => setState(() => _kind = _kind == kind ? null : kind),
    );
    return SearchTypeChips(
      chips: [
        chip('all', 'All', null),
        chip('documents', 'Documents', _Kind.document),
        chip('chats', 'Chats', _Kind.conversation),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final narrow = context.sizeClass.isCompact;
    final sections = _sections();
    final compact = _sections(compact: true);
    return ColoredBox(
      color: c.bgPrimary,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: PageWidths.standard),
              child: Padding(
                padding: EdgeInsets.all(narrow ? Space.xl : Space.xxxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: Space.xl,
                      runSpacing: Space.md,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Search',
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
                      'Type to filter the samples, choose a kind, move with '
                      'the arrow keys and press Enter to open one.',
                      style: ts(context.type.body, c.textSecondary),
                    ),
                    const _Heading('Panel'),
                    Align(
                      alignment: Alignment.topLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: PageWidths.narrow,
                        ),
                        child: SizedBox(
                          height: Specimen.search,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: c.bgPrimary,
                              border: Border.all(color: c.border),
                              borderRadius: Radii.panel,
                            ),
                            child: ClipRRect(
                              borderRadius: Radii.panel,
                              child: SearchPanel(
                                key: const ValueKey('sample-panel'),
                                controller: _query,
                                fieldKey: const ValueKey('sample-field'),
                                placeholder: 'Search the samples…',
                                onQueryChanged: (_) => setState(() {}),
                                onPick: _pick,
                                sections: sections,
                                filters: _chips(),
                                idleNote: 'Search sample titles and text.',
                                narrowedNote: _kind == null
                                    ? null
                                    : 'Showing only one kind of result',
                                selectionResetKey: Object.hash(
                                  _query.text,
                                  _kind,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Gap(Space.md),
                    Text(
                      _picked,
                      key: const ValueKey('sample-picked'),
                      style: ts(context.type.ui, c.textSecondary),
                    ),
                    const _Heading('Phone list'),
                    if (compact == null || compact.isEmpty)
                      Text(
                        'No results',
                        style: ts(context.type.ui, c.textTertiary),
                      )
                    else
                      // The phone layout, shown by touch whatever the window.
                      AppTheme(
                        colors: c,
                        density: Density.touch,
                        child: SizedBox(
                          height: Heights.list,
                          child: SearchResultsList(
                            sections: compact,
                            onPick: _pick,
                          ),
                        ),
                      ),
                    const _Heading('Flat list with type labels'),
                    for (final sample in _samples.take(Specimen.flatSamples))
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: SearchResultRow.extent(context.metrics),
                        ),
                        child: SearchResultRow(
                          result: _result(
                            sample,
                            compact: narrow,
                            keyPrefix: 'flat',
                          ),
                          showTypeLabel: true,
                          onTap: () => _pick(_result(sample)),
                        ),
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

class _Heading extends StatelessWidget {
  const _Heading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Space.xxl, bottom: Space.lg),
    child: SettingsHeading(label),
  );
}
