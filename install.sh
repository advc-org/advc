#!/bin/sh
# advc — the installer from the advc releases (github.com/advc-org/advc).
#
#   curl -fsSL https://github.com/advc-org/advc/raw/master/install.sh | sh
#
#   curl -fsSL https://github.com/advc-org/advc/raw/master/install.sh | sh -s -- --uninstall
#
#   --version <x>     install a specific version (default: the newest release)
#   --bin-dir <dir>   where the `advc` executable goes (default: /usr/local/bin)
#   --cache-dir <dir> where the packs extract (default: $HOME/.cache/advc)
#   --uninstall       remove the installed compiler; every removal is
#                     printed FIRST in one list, confirmed once with a
#                     single [y/N] — the default answer is NO and nothing
#                     is removed without that one yes
#   --help            this text
#
# The tool override for the GitHub checkout (tests): ADVC_GITHUB_REPO.

GITHUB_REPO="${ADVC_GITHUB_REPO:-advc-org/advc}"
API_BASE="${ADVC_API_BASE:-https://api.github.com}"
BIN_DIR="/usr/local/bin"
VERSION=""

banner() {
    echo "        __       __"
    echo "  __ _| |__ __| |__"
    echo " / _\` | '_ \ _| '_ \\"
    echo " \\__,_|_.__/\\__|_.__/"
    echo " the adventure game compiler"
    echo
}

while [ $# -gt 0 ]; do
    case "$1" in
        -s)
            shift
            ;;
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
            banner
            sed -n '20,33p' "$0" 2>/dev/null | sed 's/^#//;s/^ //'
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
    *) banner; echo "install.sh: unsupported OS `uname -s` — the packs ship for macOS and Linux" >&2; exit 1 ;;
esac
case "$(uname -m)" in
    arm64|aarch64) triple="aarch64-$triple" ;;
    x86_64)        triple="x86_64-$triple" ;;
    *) banner; echo "install.sh: unsupported architecture `uname -m`" >&2; exit 1 ;;
esac

banner

# ─── uninstall: careful, default-off, one no aborts ──────────────────────
if [ "${UNINSTALL:-0}" = 1 ]; then
    # Discover everything FIRST, so the plan is complete before any rm.
    found_bin=""
    for b in "$BIN_DIR/advc" /usr/local/bin/advc "$HOME/.local/bin/advc" /bin/advc; do
        if [ -x "$b" ]; then
            found_bin="$b"
            break
        fi
    done
    cache_entries=""
    n_entries=0
    n_kb=0
    if [ -d "$CACHE" ]; then
        for entry in "$CACHE"/*; do
            [ -e "$entry" ] || break
            cache_entries="$cache_entries
$entry"
            n_entries=$((n_entries + 1))
            entry_kb=$(du -sk "$entry" | cut -f1)
            n_kb=$((n_kb + entry_kb))
        done
    fi
    # du -sk counts in KB; the summary reads better as MB (or GB).
    if [ "$n_kb" -ge 1048576 ]; then
        n_size="$(( (n_kb + 524287) / 1048576 )) GB"
    elif [ "$n_kb" -ge 1024 ]; then
        n_size="$(( (n_kb + 511) / 1024 )) MB"
    else
        n_size="${n_kb} KB"
    fi

    # The summary/what-will-go: EVERY command is printed before anything runs.
    echo "  uninstalling advc ($triple)"
    echo
    echo "  what will be removed, in one go:"
    echo
    if [ -n "$found_bin" ]; then
        echo "    rm -rf $found_bin"
    else
        echo "    (no executable found in $BIN_DIR, /usr/local/bin, ~/.local/bin)"
    fi
    if [ "$n_entries" -gt 0 ]; then
        echo "    the cache: $n_entries item(s) under $CACHE (~$n_size)"
        printf '%s\n' "$cache_entries" | while IFS= read -r e; do
            [ -n "$e" ] && echo "    rm -rf $e"
        done
        echo "    rmdir $CACHE"
    else
        echo "    (the cache: nothing under $CACHE)"
    fi
    echo
    printf 'Proceed? [y/N] '
    IFS= read -r answer </dev/tty 2>/dev/null || answer=""
    case "$answer" in
        y|Y|yes|YES) ;;
        *) echo "uninstall cancelled — nothing was removed (answer '$answer')" >&2; exit 1 ;;
    esac
    echo

    # The removals, one go: the confirm above approved the whole list. A
    # failed rm never prints "removed".
    run_rm() {
        if rm -rf "$1" 2>/dev/null; then
            echo "  → removed $1"
        elif sudo rm -rf "$1" 2>/dev/null; then
            # A root-owned path (the /usr/local/bin default) needs the
            # admin rights the user just proved by confirming.
            echo "  → removed $1 (with sudo)"
        else
            echo "  → FAILED to remove $1 — check its permissions" >&2
        fi
    }

    if [ -n "$found_bin" ]; then
        run_rm "$found_bin"
    fi
    if [ -d "$CACHE" ]; then
        for entry in "$CACHE"/*; do
            [ -e "$entry" ] || break
            run_rm "$entry"
        done
        if [ -e "$CACHE" ]; then
            if rmdir "$CACHE" 2>/dev/null; then
                echo "  → removed $CACHE"
            else
                echo "  → kept $CACHE (not empty)"
            fi
        fi
    fi

    echo
    echo "  uninstall done."
    exit 0
fi

# ─── install: the newest (or the --version) release for this triple ──────
echo "  [1/5] resolving the release to install$([ -n "$VERSION" ] && echo " (pinned: $VERSION)") for $triple …"
releases_json=$(curl -fsSL "$API_BASE/repos/$GITHUB_REPO/releases?per_page=100") \
    || { echo "install.sh: could not reach GitHub (curl $?)" >&2; exit 1; }
if ! printf '%s' "$releases_json" | grep -q browser_download_url; then
    echo "install.sh: no releases published at $GITHUB_REPO yet" >&2
    exit 1
fi

# The pack pickers: each runs its OWN pipeline from the JSON (the releases
# list is newest-first, so `head -1` = the newest release's asset for this
# triple). The compiler pack's name is `advc-<semver>-…`; the runtime pack's
# is `advc-runtime-<semver>-…`.
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

if [ "$VERSION" != "" ]; then
    compiler_url=$(printf '%s' "$compiler_url" | grep "/advc-$VERSION-" || true)
    runtime_url=$(printf '%s' "$runtime_url" | grep "/advc-runtime-$VERSION-" || true)
    [ -n "$compiler_url" ] || { echo "install.sh: no release asset for version $VERSION with triple $triple" >&2; exit 1; }
    [ -n "$runtime_url" ] || { echo "install.sh: no runtime asset for version $VERSION with triple $triple" >&2; exit 1; }
else
    [ -n "$compiler_url" ] || { echo "install.sh: no compiler pack for triple $triple in the releases" >&2; exit 1; }
    [ -n "$runtime_url" ] || { echo "install.sh: no runtime pack for triple $triple in the releases" >&2; exit 1; }
fi

compiler_name=$(basename "$compiler_url" .tar.gz)
runtime_name=$(basename "$runtime_url" .tar.gz)
version_from_name=$(printf '%s' "$compiler_name" | sed "s/^advc-//; s/-$triple\$//")

# The pack sizes straight from the release JSON (the "size" field sits in
# the same asset object as the browser_download_url, BEFORE it), byte → ~MB.
# RS="," splits the JSON into one field per record, so it works on both the
# pretty-printed (GitHub API) and compact forms.
size_of() {
    printf '%s' "$releases_json" | awk -v target="$1" '
        BEGIN { RS = "," }
        /"browser_download_url"/ {
            if (index($0, target) > 0) { print last_size; exit }
        }
        /"size": *[0-9]+/ {
            bytes = $0
            sub(/.*"size": */, "", bytes)
            gsub(/[^0-9]/, "", bytes)
            last_size = bytes
        }
    '
}
mb_of() { echo "$(( ($1 + 524287) / 1048576 ))"; }

# ─── the plan: everything that will happen, BEFORE anything touches the disk
c_bytes=$(size_of "$compiler_url")
r_bytes=$(size_of "$runtime_url")
echo
echo "  installing advc $version_from_name for $triple. here is what will happen:"
echo
echo "    1. download (into a temp dir, removed after):"
echo "         $compiler_name.tar.gz  (~$(mb_of "${c_bytes:-0}") MB)"
echo "         $runtime_name.tar.gz  (~$(mb_of "${r_bytes:-0}") MB)"
echo "    2. extract both packs into $CACHE"
echo "         (the compiler and the runtime stay there — advc finds"
echo "          them by version: $CACHE/$compiler_name/)"
echo "    3. copy the executable into $BIN_DIR"
echo "         (a root-owned folder, so sudo may ask for your password;"
echo "          a Skip keeps advc in the cache and prints the full path)"
echo "    4. run advc --version to verify"
echo
printf 'Proceed? [y/N] '
IFS= read -r answer </dev/tty 2>/dev/null || answer=""
case "$answer" in
    y|Y|yes|YES) echo ;;
    *) echo "install cancelled — nothing was downloaded or changed (answer '$answer')" >&2; exit 1 ;;
esac

echo "  [2/5] downloading the packs"
echo "        compiler pack: $compiler_name.tar.gz"
echo "        runtime pack:  $runtime_name.tar.gz"

# Download both packs into a temp dir (cleaned up however the script ends).
# curl '#' = one quiet progress bar per download.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT TERM
compiler_tgz="$tmp/$(basename "$compiler_url")"
runtime_tgz="$tmp/$(basename "$runtime_url")"
echo "        [compiler]"
curl -#fSL -o "$compiler_tgz" "$compiler_url" || { echo "install.sh: download failed ($compiler_url)" >&2; exit 1; }
echo "        [runtime]"
curl -#fSL -o "$runtime_tgz" "$runtime_url" || { echo "install.sh: download failed ($runtime_url)" >&2; exit 1; }

echo "  [3/5] extracting into $CACHE"
mkdir -p "$CACHE"
tar -xzf "$compiler_tgz" -C "$CACHE" || exit 1
tar -xzf "$runtime_tgz" -C "$CACHE" || exit 1
echo "        the packs extracted into $CACHE:"

# The executable into BIN_DIR. /usr/local/bin is root-owned: the copy asks
# for the admin password through sudo — the y/N/[S]kip confirm below is
# where the user decides. y = copy now; S = skip (the compiler stays in the
# cache and works via the full path, the instructions print); N/default =
# cancel the installation.
echo
echo "  [4/5] the executable"
echo "        copying \"advc\" ($version_from_name) into $BIN_DIR"
echo "        — this folder is root-owned, so sudo may ask for your password."
printf '        install it there? [y=install / S=skip / N=cancel] '
IFS= read -r answer </dev/tty 2>/dev/null || answer=""
case "$answer" in
    y|Y|yes|YES)
        src="$CACHE/advc-$version_from_name-$triple/advc"
        mkdir -p "$BIN_DIR" 2>/dev/null || true
        if [ -w "$BIN_DIR" ]; then
            cp "$src" "$BIN_DIR/advc" && chmod +x "$BIN_DIR/advc"
        elif command -v sudo >/dev/null 2>&1 && sudo -v; then
            # A root-owned bin dir (the /usr/local/bin default): sudo prompts
            # for the password on the terminal.
            sudo cp "$src" "$BIN_DIR/advc" && sudo chmod +x "$BIN_DIR/advc"
        else
            echo "        → no sudo available; installing to $HOME/.local/bin instead"
            BIN_DIR="$HOME/.local/bin"
            mkdir -p "$BIN_DIR"
            cp "$src" "$BIN_DIR/advc" && chmod +x "$BIN_DIR/advc"
            echo "        → add it to your PATH:  export PATH=\"$BIN_DIR:\$PATH\""
        fi
        if [ -n "$BIN_DIR" ] && [ -x "$BIN_DIR/advc" ]; then
            echo "        → installed at $BIN_DIR/advc"
        fi
        ;;
    s|S)
        echo "        → skipped. the compiler stays in the cache; run it directly for now:"
        echo "           $CACHE/advc-$version_from_name-$triple/advc --version"
        echo "           and copy it to your PATH whenever you're ready."
        ;;
    *)
        echo "        → cancelled. nothing more was installed (answer '$answer')"
        echo "        the packs extracted into $CACHE remain; run this installer again"
        echo "        whenever you're ready."
        exit 0
        ;;
esac

echo
echo "  [5/5] verifying"
echo
"$CACHE/advc-$version_from_name-$triple/advc" --version || true
echo
if [ -n "$BIN_DIR" ] && [ -x "$BIN_DIR/advc" ]; then
    echo "all set — `advc --version` now works from any folder."
else
    echo "installed in the cache; the executable is at"
    echo "  $CACHE/advc-$version_from_name-$triple/advc"
fi
