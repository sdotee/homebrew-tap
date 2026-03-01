#!/bin/bash
set -euo pipefail

REPO="sdotee/cli"
FORMULA="Formula/see.rb"

# Cross-platform helpers
sedi() {
    if [[ "$OSTYPE" == darwin* ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

sha256() {
    if command -v sha256sum &>/dev/null; then
        sha256sum "$@"
    else
        shasum -a 256 "$@"
    fi
}

# Get latest release version
echo "Fetching latest release from ${REPO}..."
LATEST_TAG=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])")
LATEST_VERSION="${LATEST_TAG#v}"
CURRENT_VERSION=$(grep 'SEE_VERSION' "$FORMULA" | head -1 | sed 's/.*"\(.*\)".*/\1/')

echo "Current version: ${CURRENT_VERSION}"
echo "Latest version:  ${LATEST_VERSION}"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "Already up to date."
    exit 0
fi

# Download checksums
echo "Downloading checksums..."
CHECKSUMS=$(curl -sL "https://github.com/${REPO}/releases/download/v${LATEST_VERSION}/checksums.txt")

SHA256_INTEL=$(echo "$CHECKSUMS" | grep 'see_Darwin_x86_64.tar.gz' | awk '{print $1}')
SHA256_ARM=$(echo "$CHECKSUMS" | grep 'see_Darwin_arm64.tar.gz' | awk '{print $1}')

if [ -z "$SHA256_INTEL" ] || [ -z "$SHA256_ARM" ]; then
    echo "Error: Could not find Darwin checksums in checksums.txt"
    exit 1
fi

# Verify checksums by downloading and checking
echo "Verifying Intel binary checksum..."
TMPDIR_PATH=$(mktemp -d)
trap 'rm -rf "$TMPDIR_PATH"' EXIT

curl -sL "https://github.com/${REPO}/releases/download/v${LATEST_VERSION}/see_Darwin_x86_64.tar.gz" -o "${TMPDIR_PATH}/intel.tar.gz"
ACTUAL_INTEL=$(sha256 "${TMPDIR_PATH}/intel.tar.gz" | awk '{print $1}')
if [ "$SHA256_INTEL" != "$ACTUAL_INTEL" ]; then
    echo "Error: Intel SHA256 mismatch!"
    echo "  Expected: ${SHA256_INTEL}"
    echo "  Actual:   ${ACTUAL_INTEL}"
    exit 1
fi
echo "  OK: ${SHA256_INTEL}"

echo "Verifying ARM binary checksum..."
curl -sL "https://github.com/${REPO}/releases/download/v${LATEST_VERSION}/see_Darwin_arm64.tar.gz" -o "${TMPDIR_PATH}/arm.tar.gz"
ACTUAL_ARM=$(sha256 "${TMPDIR_PATH}/arm.tar.gz" | awk '{print $1}')
if [ "$SHA256_ARM" != "$ACTUAL_ARM" ]; then
    echo "Error: ARM SHA256 mismatch!"
    echo "  Expected: ${SHA256_ARM}"
    echo "  Actual:   ${ACTUAL_ARM}"
    exit 1
fi
echo "  OK: ${SHA256_ARM}"

# Update Formula
echo "Updating ${FORMULA}..."
sedi "s/SEE_VERSION = \".*\"/SEE_VERSION = \"${LATEST_VERSION}\"/" "$FORMULA"
sedi "s/SHA256_INTEL = \".*\"/SHA256_INTEL = \"${SHA256_INTEL}\"/" "$FORMULA"
sedi "s/SHA256_ARM = \".*\"/SHA256_ARM = \"${SHA256_ARM}\"/" "$FORMULA"

echo "Done! Updated ${FORMULA} to v${LATEST_VERSION}"
echo ""
grep -E '(SEE_VERSION|SHA256_)' "$FORMULA"
