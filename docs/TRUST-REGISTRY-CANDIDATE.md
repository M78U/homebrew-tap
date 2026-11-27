# Trust Registry 0.1.0 source-build candidate

Status: **not published / local acceptance only**. The file in `candidates/trust-registry.rb` is deliberately outside Formula/. Do not advertise the installation command as available yet, move it into Formula/, distribute a bottle or publish a binary before the gates below are complete.

The upstream release tag is `0.1.0` (without v), and GitHub's compare endpoint confirmed it is identical to the locally validated source revision `0477dd115adb86f32b6b3ac41a8018bf4b087ade`. The formula pins both tag and commit; it does not use main, a mutable HEAD or an invented archive checksum. Upstream: https://github.com/M78U/trust-registry/releases/tag/0.1.0.

Scope: one macOS CLI, CGO disabled, Go 1.26.x, no TUF publisher/client executables, service, CA downloads, trust anchors, or automatic update job. The candidate separates module fetching from offline compilation using current Homebrew fetch/deny_network_access! support (https://docs.brew.sh/Language-Specific-Formulae#go). A current compatible Homebrew version is required. No CI or Cloudflare changes.

## Acceptance

1. Confirm the release is published, and tag/revision still match. Never retag a released version for packaging.
2. Collect actual package-level license evidence from the exact upstream release checkout using the reviewed `scripts/cli-license-evidence.mjs` from the later development commit. Review each supported macOS architecture and the actual Homebrew Go patch version. The current collector derives the source checkout from its own location; use a private detached worktree and a reviewed temporary copy of the collector, or adapt the collector to accept an explicit clean source checkout. Do not use main's source graph as release evidence or commit the temporary script to the release tag.
3. Complete source-header, embedded data and nested notice review. The candidate currently installs the existing scoped upstream notices and Go root LICENSE/PATENTS only; this is preliminary and is **not** complete binary redistribution clearance. Add all applicable missing notices before moving the candidate to Formula/.
4. Test the candidate using an isolated local review tap (not the official tap), on native Apple Silicon and native Intel macOS, with current Homebrew and the exact supported Go 1.26.x toolchain. Verify source-build fetch, offline install, lock preservation, `brew test`, installed notices and actual binary build metadata. Do not bypass Homebrew sandboxing, checksum validation or security settings.
5. Once acceptance is recorded and owner approves, submit a separate PR moving the reviewed definition into Formula/ and updating the README to mark it available. No bottle at this stage.

## Local candidate testing

From a clone of this tap, with a separate unused review tap name (choose another if it already exists):

```sh
brew tap-new m78u/trust-registry-review
review_tap="$(brew --repository m78u/trust-registry-review)"
mkdir -p "$review_tap/Formula"
cp candidates/trust-registry.rb "$review_tap/Formula/trust-registry.rb"
brew install --build-from-source m78u/trust-registry-review/trust-registry
brew test m78u/trust-registry-review/trust-registry
```

Run only in a trusted local review environment, not on a production workstation with a conflicting installed formula. Native Ruby syntax, Homebrew install and architecture tests have not been executed by this PR. Inspect all logs privately; do not publish evidence archives containing private paths. Clean up the temporary tap after testing as appropriate.
