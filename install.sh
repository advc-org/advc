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
#                     printed and CONFIRMED one at a time — the default
#                     answer is NO and one no aborts the whole uninstall
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
    n_bytes=0
    if [ -d "$CACHE" ]; then
        for entry in "$CACHE"/*; do
            [ -e "$entry" ] || break
            cache_entries="$cache_entries
$entry"
            n_entries=$((n_entries + 1))
            entry_bytes=$(du -sk "$entry" | cut -f1)
            n_bytes=$((n_bytes + entry_bytes))
        done
    fi

    # The summary/what-will-go.
    echo "  uninstalling advc ($triple)"
    echo
    echo "  what will be removed, ONE by ONE (each printed + confirmed; the"
    echo "  default answer is NO and the first no aborts the whole uninstall;"
    echo "  anything explicitly confirmed before it stays removed):"
    echo
    if [ -n "$found_bin" ]; then
        echo "    the executable:  $found_bin"
    else
        echo "    the executable:  none found in $BIN_DIR, /usr/local/bin, ~/.local/bin"
    fi
    if [ "$n_entries" -gt 0 ]; then
        echo "    the cache:       $n_entries item(s) under $CACHE (~${n_bytes} MB)"
        printf '%s\n' "$cache_entries" | while IFS= read -r e; do
            [ -n "$e" ] && echo "                     $e"
        done
    else
        echo "    the cache:       nothing under $CACHE"
    fi
    echo
    printf 'Proceed? [y/N] '
    IFS= read -r answer </dev/tty 2>/dev/null || answer=""
    case "$answer" in
        y|Y|yes|YES) ;;
        *) echo "uninstall cancelled — nothing was removed (answer '$answer')" >&2; exit 1 ;;
    esac
    echo

    # The removals, one by one, CONFIRMED individually — the y above only
    # opened the phase. The same default: Enter or anything else = abort.
    confirm() {
        printf '%s\nRemove this? [y/N] ' "$1"
        IFS= read -r answer </dev/tty 2>/dev/null || answer=""
        case "$answer" in
            y|Y|yes|YES) return 0 ;;
            *) echo "  → kept (answer '$answer'); the uninstall aborts here" >&2; return 1 ;;
        esac
    }
    run_rm() {
        if confirm "rm -rf $1"; then
            if eval "rm -rf $1" 2>/dev/null; then
                echo "  → removed"
            elif sudo rm -rf "$1" 2>/dev/null; then
                # A root-owned path (the /usr/local/bin default) needs the
                # admin rights the user just proved by confirming.
                echo "  → removed (with sudo)"
            else
                echo "  → FAILED — the item stays; check its permissions" >&2
                exit 1
            fi
        else
            exit 1
        fi
    }

    if [ -n "$found_bin" ]; then
        run_rm "'$found_bin'"
    fi
    if [ -d "$CACHE" ]; then
        for entry in "$CACHE"/*; do
            [ -e "$entry" ] || break
            run_rm "'$entry'"
        done
        if [ -e "$CACHE" ] && confirm "rmdir $CACHE"; then
            rmdir "$CACHE" && echo "  → removed" || { echo "  → kept (not empty)"; exit 1; }
        fi
    fi

    echo
    echo "  uninstall done. any kept items stay exactly where they are."
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

echo "  [2/5] downloading the packs"
echo "        compiler pack: $compiler_name.tar.gz  (~21 MB)"
echo "        runtime pack:  $runtime_name.tar.gz  (~37 MB)"

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
