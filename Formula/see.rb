# typed: false
# frozen_string_literal: true

class See < Formula
  desc "Command-line client for the S.EE content sharing platform"
  homepage "https://s.ee"
  license "MIT"

  SEE_VERSION = "1.4.2"
  SHA256_INTEL = "5ed99a11ba5ad5e303aa412e2cb175d5db0c13a56aa643450121f449bf83a08e"
  SHA256_ARM = "e4afeda334c2b4fc88e3df3e43918755382db72955d0828f26328c5ef1ef6988"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    if Hardware::CPU.intel?
      url "https://github.com/sdotee/cli/releases/download/v#{SEE_VERSION}/see_Darwin_x86_64.tar.gz"
      sha256 SHA256_INTEL
    elsif Hardware::CPU.arm?
      url "https://github.com/sdotee/cli/releases/download/v#{SEE_VERSION}/see_Darwin_arm64.tar.gz"
      sha256 SHA256_ARM
    end
  end

  def install
    bin.install "see"
  end

  test do
    system "#{bin}/see", "--version"
  end
end
