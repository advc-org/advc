#!/bin/sh
# advc — the installer from the advc releases (github.com/advc-org/advc).
#
#   curl -fsSL https://github.com/advc-org/advc/raw/master/install.sh | sh
#
# Downloads both packs (the compiler + the runtime) for the host
# architecture from the releases, extracts them into the expected cache
# folder (~/.cache/advc — `advc --install`'s install layout), and installs
# the `advc` executable into /usr/local/bin (sudo; falls back to
# ~/.local/bin, which needs a PATH export).
#
# Options:
#   --version <x>     install a specific version (default: the newest release)
#   --bin-dir <dir>   where the `advc` executable goes (default: /usr/local/bin)
#   --cache-dir <dir> where the packs extract (default: $HOME/.cache/advc)
#   --uninstall       remove the installed compiler; every removal is
#                     printed and CONFIRMED one at a time — the default
#                     answer is NO and one no aborts the whole uninstall
#   --help            this text
#
# The tool override for the GitHub checkout (tests): ADVC_GITHUB_REPO.
GITHUB_REPO="${ADVC_GITHUB_REPO:-advc-org/advc}"
API_BASE="${ADVC_API_BASE:-https://api.github.com}"
BIN_DIR="/usr/local/bin"
VERSION=""
while [ $# -gt 0 ]; do
    case "$1" in
        --version)
            shift
            [ $# -gt 0 ] || { echo "install.sh: --version needs a value (e.g. --version 0.0.1)" >&2; exit 1; }
            VERSION="$1"
            ;;
        --bin-dir)
            shift
            [ $# -gt 0 ] || { echo "install.sh: --bin-dir needs a value" >&2; exit 1; }
            BIN_DIR="$1"
            ;;
        --cache-dir)
            shift
            [ $# -gt 0 ] || { echo "install.sh: --cache-dir needs a value" >&2; exit 1; }
            CACHE_DIR_ARG="$1"
            ;;
        --uninstall)
            UNINSTALL=1
            ;;
        -h|--help)
            sed -n '2,23p' "$0" 2>/dev/null | sed 's/^#//;s/^ //'
            exit 0
            ;;
        *)
            echo "install.sh: unknown option $1 (see --help)" >&2
            exit 1
            ;;
    esac
    shift
done

CACHE="${CACHE_DIR_ARG:-$HOME/.cache/advc}"

# ─── the host architecture → the pack triple ─────────────────────────────
# (the arch names follow the pack naming: aarch64-apple-darwin,
# x86_64-unknown-linux-gnu, …)
case "$(uname -s)" in
    Darwin) triple="apple-darwin" ;;
    Linux)  triple="unknown-linux-gnu" ;;
    *) echo "install.sh: unsupported OS `uname -s` — the packs ship for macOS and Linux" >&2; exit 1 ;;
esac
case "$(uname -m)" in
    arm64|aarch64) triple="aarch64-$triple" ;;
    x86_64)        triple="x86_64-$triple" ;;
    *) echo "install.sh: unsupported architecture `uname -m`" >&2; exit 1 ;;
esac
echo "install.sh: host triple $triple"

# ─── uninstall: careful, default-off, one no aborts ──────────────────────
# Every removal is PRINTED first and confirmed with an explicit y (or yes);
# pressing Enter (the default) or answering anything else runs nothing and
# ABORTS the whole uninstall — already-confirmed removals stay (they were
# genuinely confirmed).
if [ "${UNINSTALL:-0}" = 1 ]; then
    confirm() {
        printf '%s\nRemove this? [y/N] ' "$1"
        IFS= read -r answer </dev/tty 2>/dev/null || answer=""
        case "$answer" in
            y|Y|yes|YES) return 0 ;;
            *) echo "  → kept (answer '$answer'); the uninstall aborts here" >&2; return 1 ;;
        esac
    }
    run_rm() {
        # $1 = the rm command line (quoted); echo + CONFIRM + run.
        if confirm "rm -rf $1"; then
            eval "rm -rf $1"
            echo "  → removed"
        else
            exit 1
        fi
    }

    echo "The advc uninstall removes, ONE BY ONE, each of the following (the"
    echo "first no aborts; anything already confirmed stays):"
    echo "  - the advc executable in $BIN_DIR (and the common alternates)"
    echo "  - every installed version dir + tool file under $CACHE"

    # 1. The executable, wherever it is.
    found_bin=""
    for b in "$BIN_DIR/advc" /usr/local/bin/advc "$HOME/.local/bin/advc" /bin/advc; do
        if [ -x "$b" ]; then
            found_bin="$b"
            break
        fi
    done
    if [ -n "$found_bin" ]; then
        run_rm "'$found_bin'"
    else
        echo "no advc executable found in $BIN_DIR, /usr/local/bin, ~/.local/bin — nothing to remove there"
    fi

    # 2. The cache's entries, one file/folder at a time.
    if [ -d "$CACHE" ]; then
        for entry in "$CACHE"/*; do
            [ -e "$entry" ] || break
            run_rm "'$entry'"
        done
        if [ -e "$CACHE" ] && confirm "rmdir $CACHE"; then
            rmdir "$CACHE" && echo "  → removed" || { echo "  → kept (not empty)"; exit 1; }
        fi
    else
        echo "no cache at $CACHE — nothing to remove there"
    fi

    echo "uninstall done."
    exit 0
fi

# ─── install: the newest (or the --version) release for this triple ──────
# The GitHub API (unauthenticated, the releases endpoint), parsed without
# jq: the release tags + the assets' browser_download_urls per release.
echo "querying $API_BASE/repos/$GITHUB_REPO/releases …"
releases_json=$(curl -fsSL "$API_BASE/repos/$GITHUB_REPO/releases?per_page=100") \
    || { echo "install.sh: could not reach GitHub (curl $?)" >&2; exit 1; }
# The rate-limit / not-found shape: an empty "browser_download_url" set.
if ! printf '%s' "$releases_json" | grep -q browser_download_url; then
    echo "install.sh: no releases published at $GITHUB_REPO yet" >&2
    exit 1
fi

# The pack pickers: each runs its OWN pipeline from the JSON (the releases
# list is newest-first, so `head -1` = the newest release's asset for this
# triple). The COMPILER pack's name is `advc-<semver>-…`; the RUNTIME
# pack's is `advc-runtime-<semver>-…` (its own pattern — the compiler
# pattern alone never matches it). Two separate pipelines: two greps on one
# shared pipe race the buffered input.
pick_compiler() {
    printf '%s' "$releases_json" | grep -oE '"browser_download_url": *"[^"]*"' \
        | cut -d'"' -f4 \
        | grep -E "advc-[0-9]+\.[0-9]+\.[0-9]+-${triple}\.tar\.gz$" \
        | head -1
}
pick_runtime() {
    printf '%s' "$releases_json" | grep -oE '"browser_download_url": *"[^"]*"' \
        | cut -d'"' -f4 \
        | grep -E "advc-runtime-[0-9]+\.[0-9]+\.[0-9]+-${triple}\.tar\.gz$" \
        | head -1
}
compiler_url=$(pick_compiler)
runtime_url=$(pick_runtime)
compiler_url=$(pick_compiler)
runtime_url=$(pick_runtime)

if [ "$VERSION" != "" ]; then
    # A pinned version: that release's own assets only.
    compiler_url=$(printf '%s' "$compiler_url" | grep "/advc-$VERSION-" || true)
    runtime_url=$(printf '%s' "$runtime_url" | grep "/advc-runtime-$VERSION-" || true)
    [ -n "$compiler_url" ] || { echo "install.sh: no release asset for version $VERSION with triple $triple" >&2; exit 1; }
    [ -n "$runtime_url" ] || { echo "install.sh: no runtime asset for version $VERSION with triple $triple" >&2; exit 1; }
else
    [ -n "$compiler_url" ] || { echo "install.sh: no compiler pack for triple $triple in the releases" >&2; exit 1; }
    [ -n "$runtime_url" ] || { echo "install.sh: no runtime pack for triple $triple in the releases" >&2; exit 1; }
fi

echo "compiler pack: $compiler_url"
echo "runtime pack:  $runtime_url"

# Download both packs into a temp dir (cleaned up however the script ends).
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT TERM
compiler_tgz="$tmp/$(basename "$compiler_url")"
runtime_tgz="$tmp/$(basename "$runtime_url")"
curl -fSLo "$compiler_tgz" "$compiler_url" || { echo "install.sh: download failed ($compiler_url)" >&2; exit 1; }
curl -fSLo "$runtime_tgz" "$runtime_url" || { echo "install.sh: download failed ($runtime_url)" >&2; exit 1; }

# Extract into the expected cache folder: the packs' entries are
# `<name>-<version>-<triple>/…` dirs, so they land as
# `~/.cache/advc/<name>-<version>-<triple>/…`.
mkdir -p "$CACHE"
tar -xzf "$compiler_tgz" -C "$CACHE" || exit 1
tar -xzf "$runtime_tgz" -C "$CACHE" || exit 1
echo "extracted packs into $CACHE"

# The advc version directory of this install (the compiler pack's extracted
# layout) — for the post-install hint only.
version_from_name=$(basename "$compiler_tgz" .tar.gz | sed "s/^advc-//; s/-$triple\$//")

# The executable into BIN_DIR. /usr/local/bin is root-owned: sudo; when no
# sudo password can be had (a non-interactive curl|sh), fall back to
# ~/.local/bin and print the PATH export the user needs.
install_bin() {
    src="$CACHE/advc-$version_from_name-$triple/advc"
    if [ -w "$BIN_DIR" ]; then
        cp "$src" "$BIN_DIR/advc"
    elif command -v sudo >/dev/null 2>&1 && sudo -v; then
        # /bin-style dirs are root-owned; sudo prompts on the terminal
        # (`curl … | sh` still reaches the user's terminal through it).
        sudo cp "$src" "$BIN_DIR/advc"
    else
        BIN_DIR="$HOME/.local/bin"
        mkdir -p "$BIN_DIR"
        cp "$src" "$BIN_DIR/advc"
        echo "install.sh: no sudo — installed to $BIN_DIR/advc instead; add it to your PATH:"
        echo "  export PATH=\"$BIN_DIR:\$PATH\""
    fi
    chmod +x "$BIN_DIR/advc"
}
install_bin
echo "installed $BIN_DIR/advc"
echo "advc --version:"
"$BIN_DIR/advc" --version || true
