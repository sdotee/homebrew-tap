# typed: false
# frozen_string_literal: true

class See < Formula
  desc "A command-line client for the S.EE content sharing platform"
  homepage "https://s.ee"
  license "MIT"

  SEE_VERSION = "1.0.0"
  SHA256_INTEL = "444720f2b8059d0aa23a8e4ed04b0804ddc0d0f08a7eabeda74a8f628d14b0de"
  SHA256_ARM = "3359fafecac790e834beebedafc343ee8f3065ee1a51c8c61749d7dbc718fb7c"
  BASE_URL = "https://github.com/sdotee/cli/releases/download/v#{SEE_VERSION}"

  version SEE_VERSION

  livecheck do
    url "https://github.com/sdotee/cli.git"
    strategy :github_latest
  end

  on_macos do
    if Hardware::CPU.intel?
      url "#{BASE_URL}/see_Darwin_x86_64.tar.gz"
      sha256 SHA256_INTEL
    elsif Hardware::CPU.arm?
      url "#{BASE_URL}/see_Darwin_arm64.tar.gz"
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
