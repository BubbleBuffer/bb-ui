# Verification and golden baselines

All workflows use GitHub-hosted Linux runners with read-only repository
permissions. Flutter is pinned to 3.47.5. CI checks format, strict analysis,
package and gallery tests, committed golden comparison, generated-colour
drift, raw colours and private strings. It also builds the web gallery and,
on pushes, resolves the package through a Git dependency at the pushed commit.

## First baseline generation

The primitive gallery is new. Its reference PNGs (`primitives_*`, `search_*` and `palette_*`) must be rendered and
reviewed before normal golden comparison can pass. Do not copy old agent-scene
images, skip comparison, or manufacture screenshots. The old agent gallery
and its references remain in agent-kit and the extracted history.

1. After publishing the branch, manually run **ci** from Actions on that
   branch (`gh workflow run ci.yml --ref <branch>`). A manual run executes the
   gallery behaviour tests, then renders candidates using the same Linux image,
   Flutter version and bundled fonts as push and pull-request comparison.
2. Download the `primitive-golden-candidates` artifact. Check `commit.txt` against
   the intended source commit; the artifact also records Flutter and OS details.
3. Inspect every `test/goldens/primitives_*.png`, `search_*.png` and `palette_*.png` file at 100% size. Check
   readable text, complete sheets, unclipped controls, both themes and both
   widths. Review any accompanying code or token changes.
4. Copy the reviewed files into `apps/gallery/test/goldens/`, commit them,
   and run normal CI again. A matching CI comparison is the acceptance evidence.

For later intentional visual changes, use the same candidate workflow and
review the old and new images together. It has no permission to push images
or open an approval automatically. Push and pull-request runs always compare
committed baselines; manual `ci` runs explicitly generate candidates.

If format fails on a machine without Dart, download the `format-patch` artifact,
review it, and apply with `git apply format.patch`. A colour drift failure
uploads the regenerated Dart for review. Golden failures upload their diff
images separately. Neither artifact changes the accepted source by itself.

## Private-string rules

Set the repository Actions secret `PRIVATE_STRINGS` before expecting push CI
to pass. It contains newline-separated rules, never committed values:

```text
deny  <case-insensitive extended regular expression>
host  <case-sensitive whole-word expression>
allow <repository-path>:<allowed literal>
```

Blank lines and comments beginning with `#` are ignored. Locally pass a private
file via `bash scripts/check-private-strings.sh --patterns /path/to/private-rules`.
The scanner reports file and line only for sensitive matches. Recognizable
secret formats, personal tool directories and forbidden runner labels are
checked even without private rules. Pushes and same-repository PRs require
rules. Fork PRs receive no secrets and run the public checks only.

## Initial extraction limits

The initial extraction was prepared without a local Flutter/Dart SDK.
Package analysis, runtime interactions, web compilation, generated-colour
drift and rendered baselines must be verified on the configured runner before
a release. Static repository checks alone do not establish those outcomes.
