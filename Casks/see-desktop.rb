# typed: false
# frozen_string_literal: true

cask "see-desktop" do
  version "0.2.0"
  sha256 "a0ca77fd6088a2926b7ec2b35252b4a3ef90cfe18d13813314677277e542d918"

  url "https://github.com/sdotee/app/releases/download/v#{version}/SEE-#{version}.dmg",
      verified: "github.com/sdotee/app/"
  name "S.EE"
  desc "Client for the S.EE URL shortening, text sharing, and file hosting service"
  homepage "https://s.ee/"

  livecheck do
    url "https://raw.githubusercontent.com/sdotee/app/main/macos/appcast.xml"
    strategy :sparkle, &:short_version
  end

  auto_updates true
  depends_on macos: :sonoma

  app "SEE.app"

  zap trash: [
    "~/Library/Application Support/SEE",
    "~/Library/Caches/s.how.see",
    "~/Library/Caches/s.how.see.ShipIt",
    "~/Library/HTTPStorages/s.how.see",
    "~/Library/Preferences/s.how.see.plist",
    "~/Library/Saved Application State/s.how.see.savedState",
  ]
end
