# typed: false
# frozen_string_literal: true

class See < Formula
  desc "A command-line client for the S.EE content sharing platform"
  homepage "https://s.ee"
  license "MIT"

  SEE_VERSION = "1.2.0"
  SHA256_INTEL = "054d5ba6e215d91d5ca283c9a8dad51f6cfc39417ef6102dc5407c6cfa011f1e"
  SHA256_ARM = "379ad0b404634a72af26c89a4f8052623e9fa6dbd9b4fe8575c3fe976ffe608b"
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
