# Release history, notes and consumers

`packages/bb_release` is a command-line tool for any git repository of Dart
packages. It reads each package's version history from git, checks which
repositories pin the packages and how far behind they are, and drafts
release notes through a coding agent. It writes reports and drafts. It does
not edit CHANGELOGs, create tags or push.

Run it from the repository it should read. Use `--repo` for another
checkout.

```sh
dart pub get --directory packages/bb_release
dart run packages/bb_release/bin/bb_release.dart versions
```

In another repository, activate it from git and run `bb_release`:

```sh
dart pub global activate --source git https://github.com/BubbleBuffer/bb-ui \
  --git-path packages/bb_release
bb_release versions
```

Reports go to `build/release/`, or to the directory you pass with `--out`.
`build/` is ignored by git. Consumer reports name other repositories, some of
them private, so keep those reports out of this public repository. Use
`--package <name>` to select packages. Run `--help` to see every option.

## Versions

```sh
bb_release versions --remote-tags
```

A package releases a version in each commit that changes the `version:` line
of its pubspec. The tool reads the history without tags. The release is
assigned the commits that touch the package directory after the previous bump
and up to the bump. Commits after the last bump appear as **unreleased**. A
release is tagged when a tag matches `v1.2.3`, `1.2.3`, `name-v1.2.3` or
`name/v1.2.3`. The tool lists untagged releases, which consumers cannot pin by
tag. `--remote-tags` also reads tags on origin.

The tool writes `versions.json` and `versions.md`. A `(#12)` or `Merge pull
request #12` in a commit subject records its pull request number. Imported
history keeps the numbers from its original repository.

## Consumers

```sh
bb_release consumers
bb_release consumers --fetch --strict
```

The tool searches the origin owner's repositories on GitHub for pubspecs that
depend on this repository by git. It needs the `gh` CLI and permission to run
code search. Use `--owner` to search another owner.

The tool resolves each pin in the local clone. It fetches missing pinned
commits from origin unless you pass `--no-git-fetch`. Then it compares the pin
with the default branch:

| Status | Meaning |
| --- | --- |
| `current` | On the default branch, and no release of the package is newer. Unreleased commits after the pin are noted. |
| `behind` | On the default branch, and newer releases exist. |
| `off main` | The default branch does not contain the pinned commit, for example after a squash merge. GitHub can delete such commits. The consumer's `pub get` then fails. |
| `missing` | Origin does not have the ref. |
| `unpinned` | No `ref:` is set. The consumer gets whatever commit its lockfile recorded. |

Search returns fragments of each file. When a fragment omits `path:` and the
dependency name, the tool cannot identify the package and counts every commit
after the pin. `--fetch` downloads each matched pubspec, which requires read
access to the consumer repositories. GitHub code search covers only default
branches. `--strict` exits 1 when a pin is off the default branch or missing.

The tool writes `consumers.json` and `consumers.md`.

## Notes

```sh
bb_release notes --since 0.10.1 --unreleased
bb_release notes --harness command --command "<argv>" --model <id>
```

The tool sends one prompt for each release. The prompt contains the release's
commit messages, changed-file summary and the diff of the package's `lib/`,
`bin/` and README. The tool cuts diffs at `--max-diff` characters (default
60000). The model replies with one JSON object containing a summary and
entries. Each entry has `breaking`, `feature`, `fix`, `docs` or `internal` as
its kind, one line of text and the public symbols it concerns. Later stages
use the symbols to find affected docs and consumer call sites.

The tool runs `--jobs` requests at a time (default 4). It caches each reply
under `<out>/cache`, keyed by harness, model and the exact prompt. A rerun
sends prompts only for releases whose material changed. The tool writes
`notes.json` and a `<package>/CHANGELOG.md` draft for review. Pass
`--internal` to keep internal entries in the draft. `--prompts` saves every
prompt.

### Harnesses

All model calls go through one adapter interface, so every stage works with
any of them:

| `--harness` | Runs | `--model` |
| --- | --- | --- |
| `claude` (default) | `claude -p --output-format json` without tools, MCP servers or a saved session. | Claude Code's id, default `haiku` |
| `command` | Any `--command "<argv>"`. The prompt goes to stdin and the reply comes from stdout, with `{model}` substituted. | Optional |
| `echo` | Nothing. It returns an empty reply, so you can check a run and its prompts for free. | — |

`--harness-arg` adds an argument to the `claude` command line.
`--timeout` limits each request (default 300 seconds). An adapter error or a
reply without JSON marks that release as failed. Its draft lists the commit
subjects, and the command exits 1.
