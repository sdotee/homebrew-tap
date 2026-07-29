# typed: false
# frozen_string_literal: true

class See < Formula
  desc "Command-line client for the S.EE content sharing platform"
  homepage "https://s.ee"
  license "MIT"

  SEE_VERSION = "1.3.0"
  SHA256_INTEL = "e03278dcbe1010fdc9b224d7bf6578a8b9fdd249c67b1d41ba3a4190b2a5c1d6"
  SHA256_ARM = "bec3fed865fe18ab0363cbfc3fe5c4deceb819d0e4cb9e37c4d5b1d4097be544"

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
