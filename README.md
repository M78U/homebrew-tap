# homebrew-tap
Official Homebrew Tap for M78U Labs


## Packages

| Package | Status |
| --- | --- |
| SigLens CLI (Formula) | Pending reviewed public release |
| SigLens macOS App (Cask) | Pending reviewed signed and notarized release |

SigLens distribution will include native Apple Silicon and Intel builds. Once the actual package definitions are published, use:

```bash
brew tap m78u/tap
brew install --formula m78u/tap/siglens
brew install --cask m78u/tap/siglens
```

These are planned install commands, not currently available packages. No candidate archive, temporary CI artifact, placeholder checksum or unreviewed release will be registered here. Package definitions will be generated from immutable public release assets and reviewed in a pull request. Do not disable Gatekeeper or quarantine to install the app.

Learn more about M78U Labs: https://labs.m78u.com
