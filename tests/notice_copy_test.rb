require "digest"
require "fileutils"
require "pathname"
require "tmpdir"

# Exercise the actual helper without loading Homebrew's formula DSL.
formula = File.read(File.expand_path("../Formula/trust-registry.rb", __dir__))
helper = formula[/^  def install_notice\(source, destination, sha\)\n.*?^  end\n/m]
abort "install_notice helper not found" unless helper
klass = Class.new do
  def odie(message)
    raise ArgumentError, message
  end
end
klass.class_eval(helper, __FILE__, __LINE__)
checked = formula[/^  def checked_notice\(.*?^  end\n/m]
abort "checked_notice helper not found" unless checked
klass.class_eval(checked, __FILE__, __LINE__)
installer = klass.new

def assert(condition, message)
  raise message unless condition
end

Dir.mktmpdir("trust-notice-copy-") do |dir|
  root = Pathname.new(dir)
  cache = root/"cache"
  cache.mkpath
  source = cache/"LICENSE"
  source.write("fixture notice\n")
  source.chmod(0o444)
  cache.chmod(0o555)
  begin
    sha = Digest::SHA256.file(source).hexdigest
    destination = root/"installed"/"LICENSE"
    installer.install_notice(source, destination, sha)
    assert(source.file? && Digest::SHA256.file(source).hexdigest == sha, "source modified or removed")
    assert((source.stat.mode & 0o777) == 0o444, "source permissions changed")
    assert((cache.stat.mode & 0o777) == 0o555, "cache permissions changed")
    assert(destination.read == source.read, "copy differs")
    assert((destination.stat.mode & 0o777) == 0o644, "unexpected installed mode")
    assert(!File.identical?(source, destination), "expected an independent copy")
    begin
      installer.install_notice(source, root/"bad"/"LICENSE", "0" * 64)
      raise "accepted invalid hash"
    rescue ArgumentError => e
      assert(e.message.include?("Missing or changed reviewed notice"), "unexpected failure")
    end
    assert(!(root/"bad").exist?, "created output for invalid input")
    puts "PASS: read-only source copied intact; invalid digest rejected"
  ensure
    cache.chmod(0o755)
  end
end

Dir.mktmpdir("trust-notice-path-") do |dir|
  root = Pathname.new(dir)
  keg = root/"keg"
  keg.mkpath
  source = keg/"LICENSE"
  source.write("fixture notice\n")
  sha = Digest::SHA256.file(source).hexdigest
  link = keg/"linked"
  link.make_symlink(source)
  assert(installer.checked_notice(link, keg, sha, "Go LICENSE", allow_symlink: true) == source.realpath, "internal link rejected")
  outside = root/"outside"
  outside.write(source.read)
  escape = keg/"escape"
  escape.make_symlink(outside)
  [
    [link, sha, false, "Unexpected notice symlink"],
    [escape, sha, true, "Notice outside dependency root"],
    [source, "0"*64, true, "Changed reviewed notice: Go LICENSE"],
    [keg/"missing", sha, true, "Missing reviewed notice: Go LICENSE"],
  ].each do |file, digest, allow, message|
    begin
      installer.checked_notice(file, keg, digest, "Go LICENSE", allow_symlink: allow)
      raise "accepted invalid notice"
    rescue ArgumentError => e
      assert(e.message.include?(message), "unexpected error: #{e.message}")
    end
  end
  puts "PASS: contained toolchain link accepted; escaping, changed, missing and module links rejected"
end
