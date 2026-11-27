# homebrew-tap
Official Homebrew Tap for M78U Labs


## Packages

| Package | Status |
| --- | --- |
| [Trust Registry CLI](https://trust.m78u.com/) (Formula) | 0.2.0-preview.1 Developer Preview — Apple Silicon macOS, source build |
| SigLens CLI (Formula) | Pending reviewed public release |
| SigLens macOS App (Cask) | Pending reviewed signed and notarized release |

## Trust Registry CLI

```sh
brew tap m78u/tap
brew install --build-from-source m78u/tap/trust-registry
```

The formula supports Apple Silicon macOS only, builds tag `v0.2.0-preview.1` at its pinned commit and requires Go 1.26.11. A newer Homebrew Go patch requires updated notice evidence before installation is allowed. No bottle, default trusted CA dataset, production trust anchors or TUF administration tools are included. Native Intel support is pending. See the [release acceptance record](docs/TRUST-REGISTRY-CANDIDATE.md) and [upstream release](https://github.com/M78U/trust-registry/releases/tag/v0.2.0-preview.1).

## SigLens

SigLens distribution will include native Apple Silicon and Intel builds. Once the actual package definitions are published, use:

```bash
brew tap m78u/tap
brew install --formula m78u/tap/siglens
brew install --cask m78u/tap/siglens
```

These are planned install commands, not currently available packages. No candidate archive, temporary CI artifact, placeholder checksum or unreviewed release will be registered here. Package definitions will be generated from immutable public release assets and reviewed in a pull request. Do not disable Gatekeeper or quarantine to install the app.

Learn more about M78U Labs: https://labs.m78u.com
