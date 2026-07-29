#!/bin/bash
set -euo pipefail

FORMULA="Formula/see.rb"
CASK="Casks/see-desktop.rb"
FORMULA_REPO="sdotee/cli"
CASK_REPO="sdotee/app"

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

latest_tag() {
    local curl_args=(-fsSL --retry 3)
    if [ -n "${GH_TOKEN:-}" ]; then
        curl_args+=(
            -H "Authorization: Bearer ${GH_TOKEN}"
            -H "X-GitHub-Api-Version: 2022-11-28"
        )
    fi

    curl "${curl_args[@]}" "https://api.github.com/repos/$1/releases/latest" \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])"
}

verify_sha() {
    # verify_sha <url> <expected-sha>
    local url="$1" expected="$2"
    local tmp
    tmp=$(mktemp)
    curl -fsSL --retry 3 "$url" -o "$tmp"
    local actual
    actual=$(sha256 "$tmp" | awk '{print $1}')
    rm -f "$tmp"
    if [ "$expected" != "$actual" ]; then
        echo "Error: SHA256 mismatch for ${url}" >&2
        echo "  Expected: ${expected}" >&2
        echo "  Actual:   ${actual}" >&2
        return 1
    fi
    echo "$actual"
}

update_formula() {
    echo "==> Formula: ${FORMULA_REPO}"

    local latest_tag latest_version current_version
    latest_tag=$(latest_tag "$FORMULA_REPO")
    latest_version="${latest_tag#v}"
    current_version=$(grep 'SEE_VERSION' "$FORMULA" | head -1 | sed 's/.*"\(.*\)".*/\1/')

    echo "    Current: ${current_version}"
    echo "    Latest:  ${latest_version}"

    if [ "$current_version" = "$latest_version" ]; then
        echo "    Already up to date."
        return 0
    fi

    local checksums sha256_intel sha256_arm
    checksums=$(curl -fsSL --retry 3 "https://github.com/${FORMULA_REPO}/releases/download/v${latest_version}/checksums.txt")
    sha256_intel=$(echo "$checksums" | grep 'see_Darwin_x86_64.tar.gz' | awk '{print $1}')
    sha256_arm=$(echo "$checksums" | grep 'see_Darwin_arm64.tar.gz' | awk '{print $1}')

    if [ -z "$sha256_intel" ] || [ -z "$sha256_arm" ]; then
        echo "Error: could not find Darwin checksums in checksums.txt" >&2
        return 1
    fi

    echo "    Verifying Intel binary..."
    verify_sha "https://github.com/${FORMULA_REPO}/releases/download/v${latest_version}/see_Darwin_x86_64.tar.gz" "$sha256_intel" >/dev/null
    echo "    Verifying ARM binary..."
    verify_sha "https://github.com/${FORMULA_REPO}/releases/download/v${latest_version}/see_Darwin_arm64.tar.gz" "$sha256_arm" >/dev/null

    sedi "s/SEE_VERSION = \".*\"/SEE_VERSION = \"${latest_version}\"/" "$FORMULA"
    sedi "s/SHA256_INTEL = \".*\"/SHA256_INTEL = \"${sha256_intel}\"/" "$FORMULA"
    sedi "s/SHA256_ARM = \".*\"/SHA256_ARM = \"${sha256_arm}\"/" "$FORMULA"
    echo "    Updated ${FORMULA} to v${latest_version}"
}

update_cask() {
    echo "==> Cask: ${CASK_REPO}"

    local latest_tag latest_version current_version
    latest_tag=$(latest_tag "$CASK_REPO")
    latest_version="${latest_tag#v}"
    current_version=$(grep -E '^  version ' "$CASK" | head -1 | sed 's/.*"\(.*\)".*/\1/')

    echo "    Current: ${current_version}"
    echo "    Latest:  ${latest_version}"

    if [ "$current_version" = "$latest_version" ] && ! grep -q "TBD_FILLED_BY_UPDATE_SCRIPT" "$CASK"; then
        echo "    Already up to date."
        return 0
    fi

    local dmg_url published_sha actual_sha
    dmg_url="https://github.com/${CASK_REPO}/releases/download/v${latest_version}/SEE-${latest_version}.dmg"
    published_sha=$(curl -fsSL --retry 3 "${dmg_url}.sha256" | awk '{print $1}')

    if [ -z "$published_sha" ] || [ ${#published_sha} -ne 64 ]; then
        echo "Error: could not fetch a valid SHA256 from ${dmg_url}.sha256" >&2
        return 1
    fi

    echo "    Verifying DMG..."
    actual_sha=$(verify_sha "$dmg_url" "$published_sha")

    sedi "s/^  version \".*\"/  version \"${latest_version}\"/" "$CASK"
    sedi "s/^  sha256 \".*\"/  sha256 \"${actual_sha}\"/" "$CASK"
    echo "    Updated ${CASK} to v${latest_version}"
}

update_formula
update_cask

echo
echo "Done."
grep -E '(SEE_VERSION|SHA256_)' "$FORMULA"
grep -E '^  (version|sha256) ' "$CASK"
