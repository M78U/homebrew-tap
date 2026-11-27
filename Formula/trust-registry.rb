# Apple Silicon developer preview, source-build only; see release acceptance record.
require "digest"
require "fileutils"
require "json"
require "shellwords"

class TrustRegistry < Formula
  desc "Independent PKI certificate research and trust registry toolkit"
  homepage "https://trust.m78u.com/"
  url "https://github.com/M78U/trust-registry.git",
      tag: "v0.2.0-preview.1",
      revision: "45cc3aad74d93ade0fbfde44996e5f44739deb6d"
  version "0.2.0-preview.1"
  license all_of: ["MIT", "Apache-2.0", "BSD-3-Clause"]

  depends_on "go@1.26" => :build
  depends_on :macos
  depends_on arch: :arm64

  deny_network_access!

  def configure_go
    ENV["GOWORK"] = "off"
    ENV["GOTOOLCHAIN"] = "local"
    ENV["CGO_ENABLED"] = "0"
    ENV["GOFLAGS"] = ""
    ENV["GOENV"] = "off"
    ENV["GOEXPERIMENT"] = ""
    ENV["GOOS"] = "darwin"
    ENV["GOARCH"] = "arm64"
    ENV["GOPRIVATE"] = ""
    ENV["GONOSUMDB"] = ""
    ENV["GONOPROXY"] = ""
    ENV["GOSUMDB"] = "sum.golang.org"
    go = Formula["go@1.26"].opt_bin/"go"
    odie "Go patch version requires notice re-review" unless Utils.safe_popen_read(go, "env", "GOVERSION").strip == "go1.26.11"
    go
  end

  def lock_digests
    actual = ["go.mod", "go.sum"].map { |name| Digest::SHA256.file(name).hexdigest }
    expected = [
      "b539bbfbead8dae535744d360622b403acdfce6d75a2917982abf7a6f8701bee",
      "665968e4ad33d21972d316998c24fe64cdf989c4370412ccf1297351aa844865",
    ]
    odie "Source lock digests differ from reviewed release" unless actual == expected
    actual
  end

  def fetch
    go = configure_go
    before = lock_digests
    system go, "mod", "download"
    system go, "mod", "verify"
    odie "Dependency locks changed during fetch" unless before == lock_digests
  end

  def install
    go = configure_go
    ENV["GOPROXY"] = "off"
    before = lock_digests
    system go, "mod", "verify"
    notices = reviewed_notice_sources(go)
    system go, "build", "-mod=readonly", "-trimpath", "-buildvcs=false",
           "-o", bin/"trust-registry", "./cmd/trust-registry"
    odie "Dependency locks changed during build" unless before == lock_digests
    verify_build_identity(go)

    pkgshare.install "LICENSE", "NOTICE.md", "THIRD-PARTY-NOTICES.md", "licenses"
    notices.each { |source, destination, sha| install_notice(source, destination, sha) }
  end

  # Verify actual linked module identities, not the larger go.mod graph.
  def verify_build_identity(go)
    info = JSON.parse(Utils.safe_popen_read(go, "version", "-m", "-json", bin/"trust-registry"))
    arch = "arm64"
    expected = {
      "github.com/emmansun/gmsm" => ["v0.45.0", "h1:PU/6ObyR3g05YN3jn1L5GZDowzyAi8Xhkq4svzYNyiA="],
      "github.com/santhosh-tekuri/jsonschema/v6" => ["v6.0.2", "h1:KRzFb2m7YtdldCEkzs6KqmJw4nqEVZGK7IN2kJkjTuQ="],
      "golang.org/x/crypto" => ["v0.57.0", "h1:3ZVCjf8Ggz7zneR/EHRVx68Ctf+2pmIMP2UFhh9cC6M="],
      "golang.org/x/text" => ["v0.42.0", "h1:JbOZXgfeCPU9gacVtYliJqOhD+zhrEqK4LfdpmlUZqI="],
    }
    odie "Unexpected binary toolchain or main package" unless
      info["GoVersion"] == "go1.26.11" &&
      info["Path"] == "github.com/M78U/trust-registry/cmd/trust-registry" &&
      info.dig("Main", "Path") == "github.com/M78U/trust-registry" &&
      !info.dig("Main", "Replace")
    settings = info.fetch("Settings").to_h { |entry| [entry.fetch("Key"), entry.fetch("Value")] }
    odie "Unexpected binary target or CGO configuration" unless
      settings.values_at("GOOS", "GOARCH", "CGO_ENABLED") == ["darwin", arch, "0"]
    deps = info.fetch("Deps")
    odie "Unexpected binary dependencies" unless deps.length == expected.length &&
      deps.all? { |dep| !dep["Replace"] } &&
      deps.to_h { |dep| [dep.fetch("Path"), dep.values_at("Version", "Sum")] } == expected
  end

  # Exact reviewed bytes, not a license classifier. The Go vendor x/sys notices
  # are conservatively retained from the reviewed two-architecture inventory.
  def reviewed_notice_sources(go)
    notices = []
    modules = [
      ["github.com/emmansun/gmsm","v0.45.0","gmsm","LICENSE","32f582b4f6f130fdcf87e1dda6069c3cac57914408bcc1a289cff8635d32d837"],
      ["github.com/emmansun/gmsm","v0.45.0","gmsm","internal/sm9/bn256/LICENSE","b4d4d55e3fdc559101e018a8a218d94f4cadfac473a32953645545c23ef5672f"],
      ["github.com/santhosh-tekuri/jsonschema/v6","v6.0.2","jsonschema-v6","LICENSE","c8858a5a76440bbca484e134cf7df46385d090dd18b2c58e650f939258802e5b"],
      ["golang.org/x/crypto","v0.57.0","x-crypto","LICENSE","911f8f5782931320f5b8d1160a76365b83aea6447ee6c04fa6d5591467db9dad"],
      ["golang.org/x/crypto","v0.57.0","x-crypto","PATENTS","96f408bfae65bf137fc2525d3ecb030271c50c1e90799f87abf8846d8dd505cc"],
      ["golang.org/x/text","v0.42.0","x-text","LICENSE","911f8f5782931320f5b8d1160a76365b83aea6447ee6c04fa6d5591467db9dad"],
      ["golang.org/x/text","v0.42.0","x-text","PATENTS","96f408bfae65bf137fc2525d3ecb030271c50c1e90799f87abf8846d8dd505cc"],
    ]
    roots = {}
    modules.each do |mod, version, name, path, sha|
      root = roots[[mod, version]] ||= begin
        info = JSON.parse(Utils.safe_popen_read(go, "list", "-mod=readonly", "-m", "-json", mod))
        odie "Unexpected module identity" unless info["Path"] == mod && info["Version"] == version && !info["Replace"] && info["Dir"]
        Pathname.new(info["Dir"])
      end
      source = checked_notice(root/path, root, sha, "#{mod}@#{version}/#{path}")
      notices << [source, pkgshare/"reviewed-notices"/name/path, sha]
    end

    goroot = Pathname.new(Utils.safe_popen_read(go, "env", "GOROOT").strip)
    go_prefix = Formula["go@1.26"].opt_prefix.realpath
    [
      ["LICENSE","911f8f5782931320f5b8d1160a76365b83aea6447ee6c04fa6d5591467db9dad"],
      ["PATENTS","96f408bfae65bf137fc2525d3ecb030271c50c1e90799f87abf8846d8dd505cc"],
      ["src/crypto/internal/boring/LICENSE","56210f826b8f0fbac3160dfe55c97f4019eb6cdda3963b5a0eab8a8bdb62360e"],
      ["src/vendor/golang.org/x/crypto/LICENSE","911f8f5782931320f5b8d1160a76365b83aea6447ee6c04fa6d5591467db9dad"],
      ["src/vendor/golang.org/x/crypto/PATENTS","96f408bfae65bf137fc2525d3ecb030271c50c1e90799f87abf8846d8dd505cc"],
      ["src/vendor/golang.org/x/net/LICENSE","911f8f5782931320f5b8d1160a76365b83aea6447ee6c04fa6d5591467db9dad"],
      ["src/vendor/golang.org/x/net/PATENTS","96f408bfae65bf137fc2525d3ecb030271c50c1e90799f87abf8846d8dd505cc"],
      ["src/vendor/golang.org/x/sys/LICENSE","911f8f5782931320f5b8d1160a76365b83aea6447ee6c04fa6d5591467db9dad"],
      ["src/vendor/golang.org/x/sys/PATENTS","96f408bfae65bf137fc2525d3ecb030271c50c1e90799f87abf8846d8dd505cc"],
      ["src/vendor/golang.org/x/text/LICENSE","911f8f5782931320f5b8d1160a76365b83aea6447ee6c04fa6d5591467db9dad"],
      ["src/vendor/golang.org/x/text/PATENTS","96f408bfae65bf137fc2525d3ecb030271c50c1e90799f87abf8846d8dd505cc"],
    ].each do |path, sha|
      source = goroot/path
      # Some packaged toolchains keep their root notices in the keg prefix.
      # Only use that explicit alternative for absent root LICENSE/PATENTS.
      if ["LICENSE", "PATENTS"].include?(path) && !source.exist? && !source.symlink?
        alternative = go_prefix/path
        source = alternative if alternative.exist? || alternative.symlink?
      end
      source = checked_notice(source, go_prefix, sha, "go1.26.11/#{path}", allow_symlink: true)
      notices << [source, pkgshare/"reviewed-notices/go-toolchain"/path, sha]
    end
    notices
  end

  def checked_notice(source, root, sha, label, allow_symlink: false)
    odie "Missing reviewed notice: #{label} (#{source})" unless source.file?
    odie "Unexpected notice symlink: #{label}" if source.symlink? && !allow_symlink
    resolved = source.realpath
    odie "Notice outside dependency root: #{label}" unless
      resolved.to_s.start_with?(root.realpath.to_s + File::SEPARATOR)
    actual = Digest::SHA256.file(resolved).hexdigest
    odie "Changed reviewed notice: #{label} (expected #{sha}, got #{actual})" unless actual == sha
    resolved
  end

  def install_notice(source, destination, sha)
    odie "Missing or changed reviewed notice: #{source.basename}" unless
      source.file? && !source.symlink? && Digest::SHA256.file(source).hexdigest == sha
    destination.dirname.mkpath
    # Go module caches and the installed Go toolchain are read-only inputs.
    FileUtils.copy_file(source, destination)
    destination.chmod(0o644)
    odie "Copied notice differs: #{destination.basename}" unless Digest::SHA256.file(destination).hexdigest == sha
  end

  test do
    system bin/"trust-registry", "init", "--registry", testpath/"empty"
    system bin/"trust-registry", "validate", "--registry", testpath/"empty"
    coverage = JSON.parse(shell_output("#{bin}/trust-registry sources acquisition-coverage --registry #{(testpath/"empty").to_s.shellescape}"))
    assert_equal "NOT_ESTABLISHED", coverage.fetch("trustStatus")
    assert_equal false, coverage.fetch("releaseAuthenticated")
    assert_equal 0, coverage.fetch("counts").fetch("matchingInventoryRows")
    assert_equal 0, coverage.fetch("inventory").fetch("certificates")
    refute coverage.key?("archiveCoverage")
    assert_predicate pkgshare/"LICENSE", :file?
    assert_predicate pkgshare/"THIRD-PARTY-NOTICES.md", :file?
    assert_predicate pkgshare/"reviewed-notices/go-toolchain/LICENSE", :file?
    assert_predicate pkgshare/"reviewed-notices/gmsm/internal/sm9/bn256/LICENSE", :file?
    assert_predicate pkgshare/"reviewed-notices/go-toolchain/src/vendor/golang.org/x/sys/PATENTS", :file?
    assert_equal 18, (pkgshare/"reviewed-notices").glob("**/*").count(&:file?)
  end
end
