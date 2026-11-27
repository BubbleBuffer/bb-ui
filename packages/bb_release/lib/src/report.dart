// Markdown renderings of the stage outputs. The JSON files hold the same data
// for tools; these are for people.

import 'consumers.dart';
import 'notes.dart';
import 'versions.dart';

String _short(String sha) => sha.length > 7 ? sha.substring(0, 7) : sha;

String _cell(String s) => s.replaceAll('|', r'\|').replaceAll('\n', ' ');

String versionsMarkdown(String slug, Map<String, List<Release>> history) {
  final b = StringBuffer('# Versions of $slug\n');
  for (final MapEntry(key: name, value: list) in history.entries) {
    final released = list.where((r) => !r.unreleased).toList();
    final untagged = released
        .where((r) => r.tags.isEmpty)
        .map((r) => r.version);
    b.writeln('\n## $name\n');
    if (untagged.isNotEmpty) {
      b.writeln('Untagged: ${untagged.join(', ')}\n');
    }
    b.writeln('| Version | Date | Commit | Tags | Commits |');
    b.writeln('| --- | --- | --- | --- | --- |');
    for (final r in list.reversed) {
      b.writeln(
        '| ${r.version ?? '_unreleased_'} | ${r.date} | `${_short(r.commit)}` '
        '| ${r.tags.isEmpty ? '—' : r.tags.join(', ')} | ${r.commits.length} |',
      );
    }
    for (final r in list.reversed) {
      b.writeln('\n### ${r.version ?? 'Unreleased'}\n');
      for (final c in r.commits) {
        b.writeln('- `${_short(c.sha)}` ${c.subject}');
      }
    }
  }
  return b.toString();
}

const _statusText = {
  PinStatus.current: 'current',
  PinStatus.behind: 'behind',
  PinStatus.offMain: '**off main**',
  PinStatus.missing: '**missing**',
  PinStatus.unpinned: 'unpinned',
};

String consumersMarkdown(String slug, List<PinReport> reports) {
  final b = StringBuffer('# Consumers of $slug\n\n');
  final order = [
    PinStatus.missing,
    PinStatus.offMain,
    PinStatus.behind,
    PinStatus.unpinned,
    PinStatus.current,
  ];
  final sorted = [...reports]
    ..sort((x, y) {
      final s = order.indexOf(x.status).compareTo(order.indexOf(y.status));
      return s != 0 ? s : y.releasesBehind.compareTo(x.releasesBehind);
    });
  b.writeln(
    '| Consumer | File | Package | Pin | Version | Latest | Releases behind | Commits behind | Status | Note |',
  );
  b.writeln('| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |');
  for (final r in sorted) {
    final ref = r.pin.ref == null ? '—' : '`${_short(r.pin.ref!)}`';
    final comment = r.pin.comment == null ? '' : ' (${_cell(r.pin.comment!)})';
    b.writeln(
      '| ${r.pin.repo} | ${r.pin.file} | ${r.package?.name ?? '?'} | $ref$comment '
      '| ${r.version ?? '?'} | ${r.latest ?? '?'} | ${r.releasesBehind} | ${r.commitsBehind} '
      '| ${_statusText[r.status]} | ${_cell(r.note ?? '')} |',
    );
  }
  return b.toString();
}

const _headings = {
  'breaking': 'Breaking changes',
  'feature': 'Features',
  'fix': 'Fixes',
  'docs': 'Documentation',
  'internal': 'Internal',
};

/// A CHANGELOG draft, newest version first, in the usual pub layout.
String changelogMarkdown(
  String package,
  List<Notes> notes, {
  bool internal = false,
}) {
  final b = StringBuffer('# $package changelog (draft)\n');
  for (final n in notes.reversed) {
    final r = n.release;
    b.writeln(
      '\n## ${r.version ?? 'Unreleased'}${r.unreleased ? '' : ' (${r.date})'}\n',
    );
    if (n.error != null) {
      b.writeln('> Notes failed (${n.harness}): ${n.error}\n');
      for (final c in r.commits) {
        b.writeln('- ${c.subject}');
      }
      continue;
    }
    if (n.summary.isNotEmpty) b.writeln('${n.summary}\n');
    for (final kind in kinds) {
      if (kind == 'internal' && !internal) continue;
      final entries = n.entries.where((e) => e.kind == kind).toList();
      if (entries.isEmpty) continue;
      b.writeln('### ${_headings[kind]}\n');
      for (final e in entries) {
        final symbols = e.symbols.isEmpty
            ? ''
            : ' (${e.symbols.map((s) => '`$s`').join(', ')})';
        b.writeln('- ${e.text}$symbols');
      }
      b.writeln();
    }
  }
  return b.toString();
}
