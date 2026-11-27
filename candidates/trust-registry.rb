# Local acceptance candidate only. Do not move to Formula/ before review.
require "digest"
require "json"

class TrustRegistry < Formula
  desc "Independent PKI certificate research and trust registry toolkit"
  homepage "https://trust.m78u.com/"
  url "https://github.com/M78U/trust-registry.git",
      tag: "0.1.0",
      revision: "0477dd115adb86f32b6b3ac41a8018bf4b087ade"
  version "0.1.0"
  license all_of: ["MIT", "Apache-2.0", "BSD-3-Clause"]

  depends_on "go@1.26" => :build
  depends_on :macos

  deny_network_access!

  def configure_go
    ENV["GOWORK"] = "off"
    ENV["GOTOOLCHAIN"] = "local"
    ENV["CGO_ENABLED"] = "0"
    ENV["GOFLAGS"] = ""
    ENV["GOPRIVATE"] = ""
    ENV["GONOSUMDB"] = ""
    ENV["GONOPROXY"] = ""
    ENV["GOSUMDB"] = "sum.golang.org"
    Formula["go@1.26"].opt_bin/"go"
  end

  def lock_digests
    ["go.mod", "go.sum"].map { |name| Digest::SHA256.file(name).hexdigest }
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
    system go, "build", "-mod=readonly", "-trimpath", "-buildvcs=false",
           "-o", bin/"trust-registry", "./cmd/trust-registry"
    odie "Dependency locks changed during build" unless before == lock_digests

    # Preliminary notice bundle. Package-level review is a separate publication gate.
    pkgshare.install "LICENSE", "NOTICE.md", "THIRD-PARTY-NOTICES.md", "licenses"
    goroot = Pathname.new(Utils.safe_popen_read(go, "env", "GOROOT").strip)
    (pkgshare/"go-toolchain").install goroot/"LICENSE"
    (pkgshare/"go-toolchain").install goroot/"PATENTS" if (goroot/"PATENTS").file?
  end

  test do
    system bin/"trust-registry", "init", "--registry", testpath/"empty"
    system bin/"trust-registry", "validate", "--registry", testpath/"empty"
    assert_predicate pkgshare/"LICENSE", :file?
    assert_predicate pkgshare/"THIRD-PARTY-NOTICES.md", :file?
    assert_predicate pkgshare/"go-toolchain/LICENSE", :file?
  end
end
