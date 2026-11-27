# Trust Registry 0.1.0 source-build candidate

Status: **not published / local acceptance only**. The file in `candidates/trust-registry.rb` is deliberately outside Formula/. Do not advertise the installation command as available yet, move it into Formula/, distribute a bottle or publish a binary before the gates below are complete.

The upstream release tag is `0.1.0` (without v), and GitHub's compare endpoint confirmed it is identical to the locally validated source revision `0477dd115adb86f32b6b3ac41a8018bf4b087ade`. The formula pins both tag and commit; it does not use main, a mutable HEAD or an invented archive checksum. Upstream: https://github.com/M78U/trust-registry/releases/tag/0.1.0.

Scope: one macOS CLI, CGO disabled, Go 1.26.11 (exact reviewed patch), no TUF publisher/client executables, service, CA downloads, trust anchors, or automatic update job. The candidate separates module fetching from offline compilation using current Homebrew fetch/deny_network_access! support (https://docs.brew.sh/Language-Specific-Formulae#go). A current compatible Homebrew version is required. No CI or Cloudflare changes.

## Acceptance

1. Confirm the release is published, and tag/revision still match. Never retag a released version for packaging.
2. Package-level evidence received for both architectures, at the exact release and Go 1.26.11. See the review below. Recollect on toolchain or source changes.
3. Complete source-header, embedded data and nested notice review. Candidate now installs the hash-pinned union of observed notices; source-level review is not complete. Do not move to Formula/ yet.
4. Test the candidate using an isolated local review tap (not the official tap), on native Apple Silicon and native Intel macOS, with current Homebrew and the exact supported Go 1.26.x toolchain. Verify source-build fetch, offline install, lock preservation, `brew test`, installed notices and actual binary build metadata. The candidate now checks the installed executable's Go build information before copying notices: expected toolchain, main package, Darwin architecture, CGO disabled, exact four external module paths, versions and Go module sums, and no replacement modules. Go build information is a local consistency check, not a signed attestation or a substitute for source review. Do not bypass Homebrew sandboxing, checksum validation or security settings.
5. Once acceptance is recorded and owner approves, submit a separate PR moving the reviewed definition into Formula/ and updating the README to mark it available. No bottle at this stage.

## Observed notice evidence

Operator's two local inventories report revision 0477dd115adb86f32b6b3ac41a8018bf4b087ade, CGO_ENABLED=0, go1.26.11, darwin/arm64 and darwin/amd64. All 34 referenced notice files (16 ARM64, 18 AMD64) matched reported byte lengths and SHA-256. macOS AppleDouble metadata excluded; original archive not committed. Each architecture selects the same four external modules plus the Go toolchain. AMD64 adds vendor/golang.org/x/sys/cpu and two corresponding Go-vendored notice paths. Install the union of 18 path-specific notices on both targets, independently checking each file from the actual build source or toolchain. Preserve the existing upstream notices as well. The extra nested gmsm bn256 BSD text is distinct from gmsm MIT and the root Go BSD text. The crypto/internal/boring notice includes conditional BoringSSL terms for GOEXPERIMENT=boringcrypto; retain the text without claiming that BoringSSL is linked (CGO disabled, macOS target). Explicitly clear GOEXPERIMENT and GOENV; exact toolchain patch and source lock digests are enforced. If Homebrew provides another Go patch, stop and refresh evidence rather than bypassing the check.

Both inventories report MANUAL_REVIEW at src/internal/copyright (a name matching the collector's notice pattern, not a regular notice file). Inspect the actual directory contents and selected source headers, and review embedded assets and notices not captured by the collector before approving distribution. No automatic license clearance. The archive is operator evidence, not an independently authenticated upstream source archive; build-time SHA-256 checks compare actual source bytes.

## Local candidate testing

From a clone of this tap, with a separate unused review tap name (choose another if it already exists):

```sh
brew tap-new m78u/trust-registry-review
review_tap="$(brew --repository m78u/trust-registry-review)"
mkdir -p "$review_tap/Formula"
cp candidates/trust-registry.rb "$review_tap/Formula/trust-registry.rb"
brew install --build-from-source m78u/trust-registry-review/trust-registry
brew test m78u/trust-registry-review/trust-registry
prefix="$(brew --prefix m78u/trust-registry-review/trust-registry)"
"$(brew --prefix go@1.26)/bin/go" version -m "$prefix/bin/trust-registry"
file "$prefix/bin/trust-registry"
```

Run only in a trusted local review environment, not on a production workstation with a conflicting installed formula. Native Ruby syntax, Homebrew install and architecture tests have not been executed by this PR. Inspect all logs privately; do not publish evidence archives containing private paths. Clean up the temporary tap after testing as appropriate.
