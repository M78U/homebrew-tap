# Trust Registry 0.1.0 source-build release acceptance

Release scope: Apple Silicon macOS Developer Preview, source-build Formula only. This record accompanies the proposed registration in `Formula/trust-registry.rb`. **Before merging the registration PR, the owner must review outstanding source-level copyright/embedded-material issues and explicitly accept the documented test-runner limitation.** This PR is not itself evidence that the remaining license review has been completed. Do not publish a bottle, standalone binary or Intel package on this evidence.

## Operator acceptance record

- Exact upstream tag/revision: `0.1.0` / `0477dd115adb86f32b6b3ac41a8018bf4b087ade`.
- Prior candidate (tap main `04c80086bfbfc71c162218e0b1f030e6d3185346`): operator reported native Apple Silicon Homebrew source installation completed. The install path enforces source lock hashes, Go build identity, notice source and installed-copy digests.
- Direct installed CLI smoke tests: both init and validate returned `{"certificates":0,"provenanceRecords":0}`. Installed notice-file count: 18.
- `brew test`: blocked before any visible test output, including verbose/debug and HOMEBREW_NO_AUTO_UPDATE=1 attempts; operator interrupted. Root cause unknown. **Not a passed Homebrew test.** The formula test block is retained. Direct tests are narrower evidence.
- Intel native installation: not tested; architecture requirement excludes Intel. Evidence collection on AMD64 is not native execution.
- Go 1.26.11 required; no automatic acceptance of future patch changes.
- License archive integrity: independently rechecked 16 ARM64 and 18 AMD64 notice file lengths and SHA-256 in the supplied local archive. Exact source-header and embedded-asset review remains a merge prerequisite.
- New formula path and ARM64 restriction are not yet tested with a native Homebrew installation. No CI or automatic publication.

The upstream release tag is `0.1.0` (without v), and GitHub's compare endpoint confirmed it is identical to the locally validated source revision `0477dd115adb86f32b6b3ac41a8018bf4b087ade`. The formula pins both tag and commit; it does not use main, a mutable HEAD or an invented archive checksum. Upstream: https://github.com/M78U/trust-registry/releases/tag/0.1.0.

Scope: one Apple Silicon macOS CLI, CGO disabled, Go 1.26.11 (exact reviewed patch), no TUF publisher/client executables, service, CA downloads, trust anchors, or automatic update job. The candidate separates module fetching from offline compilation using current Homebrew fetch/deny_network_access! support (https://docs.brew.sh/Language-Specific-Formulae#go). A current compatible Homebrew version is required. No CI or Cloudflare changes.

## Acceptance

1. Confirm the release is published, and tag/revision still match. Never retag a released version for packaging.
2. Package-level evidence received for both architectures, at the exact release and Go 1.26.11. See the review below. Recollect on toolchain or source changes.
3. Complete source-header, embedded data and nested notice review. The proposed formula installs the hash-pinned union of observed notices; source-level review is not complete. Do not merge registration before the owner records this review.
4. The Apple Silicon source installation and direct smoke tests are operator-reported as above. Record the unresolved Homebrew test-runner limitation; the owner must accept it explicitly for this scoped preview. Native Intel validation is deferred, and the formula restricts architecture to arm64. Retest the registered path after merge. Verify source-build fetch, offline install, lock preservation, `brew test`, installed notices and actual binary build metadata. The candidate now checks the installed executable's Go build information before copying notices: expected toolchain, main package, Darwin architecture, CGO disabled, exact four external module paths, versions and Go module sums, and no replacement modules. Go build information is a local consistency check, not a signed attestation or a substitute for source review. Do not bypass Homebrew sandboxing, checksum validation or security settings.
5. Once outstanding review and owner approval are recorded, merge the registration PR. No bottle at this stage.

## Observed notice evidence

Operator's two local inventories report revision 0477dd115adb86f32b6b3ac41a8018bf4b087ade, CGO_ENABLED=0, go1.26.11, darwin/arm64 and darwin/amd64. All 34 referenced notice files (16 ARM64, 18 AMD64) matched reported byte lengths and SHA-256. macOS AppleDouble metadata excluded; original archive not committed. Each architecture selects the same four external modules plus the Go toolchain. AMD64 adds vendor/golang.org/x/sys/cpu and two corresponding Go-vendored notice paths. Install the union of 18 path-specific notices on both targets, independently checking each file from the actual build source or toolchain. Preserve the existing upstream notices as well. The extra nested gmsm bn256 BSD text is distinct from gmsm MIT and the root Go BSD text. The crypto/internal/boring notice includes conditional BoringSSL terms for GOEXPERIMENT=boringcrypto; retain the text without claiming that BoringSSL is linked (CGO disabled, macOS target). Explicitly clear GOEXPERIMENT and GOENV; exact toolchain patch and source lock digests are enforced. If Homebrew provides another Go patch, stop and refresh evidence rather than bypassing the check.

Both inventories report MANUAL_REVIEW at src/internal/copyright (a name matching the collector's notice pattern, not a regular notice file). Inspect the actual directory contents and selected source headers, and review embedded assets and notices not captured by the collector before approving distribution. No automatic license clearance. The archive is operator evidence, not an independently authenticated upstream source archive; build-time SHA-256 checks compare actual source bytes.

## Read-only dependency notice installation

The first local source-build attempt reached the notice-install step but failed with EACCES because Homebrew's Pathname#install attempted to rename a file out of the read-only Go module cache. The helper now copies reviewed notice bytes, sets the installed copy's permissions to 0644, and verifies the installed SHA-256. Neither cache nor toolchain files are moved or chmodded. Do not use sudo, chmod the cache, or disable sandboxing.

Regression fixture: `ruby tests/notice_copy_test.rb` exercises the actual helper with a 0555 cache directory and 0444 source file. Passed on Linux Ruby 3.3.8 as unprivileged user; native Homebrew rerun is still required. Refresh the existing review tap's formula after pulling this fix; no new tap is needed.

## Packaged toolchain notice paths

The second install attempt reached the build but reported a generic "Missing or changed reviewed notice: LICENSE". That message did not identify the failing dependency. The candidate now checks all 18 notice sources before compilation and reports the exact module/version/relative path plus missing-file or expected/actual digest details. A Go toolchain notice may resolve through a symlink only within the real installed go@1.26 keg, and a missing root LICENSE/PATENTS may be found at that keg's root. The exact reviewed SHA-256 remains mandatory. A changed file never falls back to another copy. Module notice symlinks remain forbidden, and all resolved source paths must stay within their dependency root. No cache mutations. The original failure's precise location is not independently confirmed; the operator's subsequent installation succeeded.

## Local candidate testing

From a clone of this tap, with a separate unused review tap name (choose another if it already exists):

```sh
brew tap-new m78u/trust-registry-review
review_tap="$(brew --repository m78u/trust-registry-review)"
mkdir -p "$review_tap/Formula"
cp Formula/trust-registry.rb "$review_tap/Formula/trust-registry.rb"
brew install --build-from-source m78u/trust-registry-review/trust-registry
brew test m78u/trust-registry-review/trust-registry
prefix="$(brew --prefix m78u/trust-registry-review/trust-registry)"
"$(brew --prefix go@1.26)/bin/go" version -m "$prefix/bin/trust-registry"
file "$prefix/bin/trust-registry"
```

Run only in a trusted local review environment, not on a production workstation with a conflicting installed formula. Native Homebrew test for the newly registered formula path and native Intel tests have not been executed by this PR. Inspect all logs privately; do not publish evidence archives containing private paths. Clean up the temporary tap after testing as appropriate.


## v0.2.0-preview.1 package upgrade candidate — 2026-11-27

The owner reported publishing the upstream source-only preview, and the exact tag was checked against commit `45cc3aad74d93ade0fbfde44996e5f44739deb6d`. The owner supplied a clean locked developer validation report for that commit (Go 1.26.11, Darwin ARM64), with registry and isolated TUF tests/builds, CLI smoke and Explorer checks passing. Release metadata is owner-reported, not independently retrieved. This new formula packages only the Registry CLI and retains the prior source-build/ARM64 restrictions.

The uploaded local evidence archive `trust-v02-preview-license-arm64.tar.gz` reports the exact same revision, GOOS=darwin, GOARCH=arm64, GOVERSION=go1.26.11, CGO_ENABLED=0 and target ./cmd/trust-registry. Its two lock SHA-256 values match the existing formula; the upstream four tracked Go lock blobs are unchanged relative to 0.1.0. All 15 referenced notice files (37,508 bytes) were independently rehashed and length-checked against the inventory and existing formula's path-specific digest values. Four external module identities and versions remain the same. The evidence is a selected-package inventory, not actual linked-binary metadata or an independent source authenticity attestation. The existing strict build identity checks remain mandatory.

The new evidence does not include the Go root LICENSE or vendored x/sys LICENSE/PATENTS. Keep those three additional conservative requirements from the earlier reviewed formula, with the same digest checks at build/install time. Do not remove the existing fallback for a packaged Go root notice. The collector still reports MANUAL_REVIEW for src/internal/copyright; inspect that directory and source-level/embedded materials. The inventory explicitly says licenseReviewComplete=false and distributionAuthorized=false. The archive is private evidence, not a grant of redistribution permission; no archive contents committed. The native candidate install, brew test, and installed notices must still be accepted by the owner before merging (or record a narrowly scoped explicit test-runner exception if the previous runner issue persists). No bottle, Intel package or production CA data.

### Test the exact candidate before merge

Review the changes and use a clean dedicated Mac review environment. The existing review-tap instructions above apply, but use this PR's candidate Formula and a separate unused tap name (for example m78u/trust-registry-v02-review). Do not overwrite a working production tap or install conflicting formula names without reviewing the local installation state. Run the native source build and test, then confirm the new acquisition-coverage command directly in a fresh temporary inventory:

```sh
scratch="$(mktemp -d)"
trust-registry init --registry "$scratch/registry"
trust-registry sources acquisition-coverage --registry "$scratch/registry"
```

Check the tested executable's exact path, Go build metadata and version via brew list/info; require zero candidates and no trust authentication. Confirm all 18 installed reviewed-notice files; the candidate test retains the old init/validate checks and adds offline acquisition coverage assertions. No actual CA network acquisition in the package test. Only merge after review and native acceptance or an explicitly documented narrow test-runner exception. On the official tap after merge, run brew update and brew upgrade --build-from-source m78u/tap/trust-registry, then repeat the smoke checks against the registered package. The original release tag is immutable.
