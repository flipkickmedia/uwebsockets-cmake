#!/bin/bash
set -eo pipefail

usage() {
  cat <<'EOF'
Remove private CA certificates from the system trust stores.

USAGE
  ca_clean.sh [--name <ca_base>]... [--force] [--dry-run]

OPTIONS
  --name <ca_base>   CA base name to remove (no extension). May be repeated.
                     If omitted, an interactive list is shown and you can pick one.
  --force            Skip the final delete confirmation. (Interactive picker still confirms selection.)
  --dry-run          Show what would be removed but make no changes.
  -h, --help         Show this help.

Listing (no --name):
  • Linux: lists anchors *.crt by file modified time; numbering is NEWEST=1 .. OLDEST=N.
           If the directory isn’t readable, you’ll be asked to use sudo just to list.
  • macOS: lists System keychain labels (mtime not available). We number newest=1 by
           showing the most likely names last and mapping 1 to the last entry.

Only system-trusted copies are removed; your project files remain untouched.
EOF
}

have() { command -v "$1" >/dev/null 2>&1; }

ask_yn_strict() {
  local prompt="$1"
  while true; do
    read -r -p "$prompt [Y/N] " ans
    case "$ans" in
      Y|y) return 0 ;;
      N|n) return 1 ;;
      *) echo "Please type Y or N." >&2 ;;
    esac
  done
}

linux_flavor() {
  if have update-ca-certificates || [[ -f /etc/debian_version ]]; then
    echo debian
  elif have update-ca-trust || [[ -f /etc/redhat-release ]]; then
    echo redhat
  elif have trust; then
    echo p11kit
  else
    echo unknown
  fi
}

anchors_dir_for_linux() {
  case "$(linux_flavor)" in
    debian)  echo "/usr/local/share/ca-certificates" ;;
    redhat)  echo "/etc/pki/ca-trust/source/anchors" ;;
    p11kit)  echo "/etc/ca-certificates/trust-source/anchors" ;;
    *)       echo "" ;;
  esac
}

# prints: EPOCH|BASENAME|FULLPATH|HUMAN  (sorted oldest->newest)
list_linux_anchors_sorted() {
  local dir="$1" use_sudo="$2"
  local RUN=()
  if [[ "$use_sudo" == "1" && $EUID -ne 0 && -x "$(command -v sudo)" ]]; then
    RUN=(sudo)
  fi
  "${RUN[@]}" find "$dir" -maxdepth 1 -type f -name '*.crt' \
    -printf '%T@|%f|%p|%TY-%Tm-%Td %TH:%TM:%TS\n' 2>/dev/null | sort -n -k1,1
}

list_macos_labels() {
  local keychain="/Library/Keychains/System.keychain"
  security find-certificate -a -Z "$keychain" 2>/dev/null \
    | awk '
        BEGIN{label="";hash=""}
        /labl</{label=$0; sub(/^.*<blob>="/,"",label); sub(/".*$/,"",label)}
        /SHA-1 hash:/ {hash=$3; if(label!=""){print label "\t" hash; label=""; hash=""}}
      ' | sort -f
}

interactive_pick_name() {
  local os="$(uname -s)"
  local names=() paths=() humans=() default_name="" total=0

  if [[ "$os" == "Linux" ]]; then
    local dir; dir="$(anchors_dir_for_linux)"
    [[ -z "$dir" ]] && { echo "ERROR: Unsupported Linux trust store." >&2; return 1; }
    [[ -d "$dir" ]] || { echo "No anchors directory found at $dir" >&2; return 1; }

    mapfile -t rows < <(list_linux_anchors_sorted "$dir" 0)
    if (( ${#rows[@]} == 0 )); then
      if ask_yn_strict "No entries visible (or permission denied). Use sudo to list?"; then
        mapfile -t rows < <(list_linux_anchors_sorted "$dir" 1)
      fi
    fi
    if (( ${#rows[@]} == 0 )); then
      echo "No *.crt anchors found in $dir" >&2
      return 1
    fi

    # Build arrays oldest->newest, but we'll NUMBER newest=1 by reversing the numbers only.
    for ln in "${rows[@]}"; do
      IFS='|' read -r epoch base full human <<<"$ln"
      names+=("${base%.crt}")
      paths+=("$full")
      humans+=("$human")
    done

    total=${#names[@]}
    default_name="${names[$((total-1))]}"  # newest

    echo "System trust anchors in $dir (oldest → newest; NEWEST=1):" >&2
    for ((i=0; i<total; i++)); do
      num=$(( total - i ))  # newest gets 1
      printf "  %2d) %-30s  %s  (%s)\n" "$num" "${names[$i]}" "${paths[$i]}" "${humans[$i]}" >&2
    done

  elif [[ "$os" == "Darwin" ]]; then
    mapfile -t rows < <(list_macos_labels)
    if (( ${#rows[@]} == 0 )); then
      echo "No certificates found in macOS System keychain." >&2
      return 1
    fi
    for ln in "${rows[@]}"; do
      IFS=$'\t' read -r label _ <<<"$ln"
      names+=("$label")
    done
    # Push our common names to the end (so default/newest=1 maps to the final entry)
    for want in "ca_root" "ca_root_alt"; do
      for idx in "${!names[@]}"; do
        if [[ "${names[$idx]}" == "$want" ]]; then
          names=("${names[@]:0:$idx}" "${names[@]:$((idx+1))}" "$want")
          break
        fi
      done
    done
    total=${#names[@]}
    default_name="${names[$((total-1))]}"
    echo "macOS System keychain certificates (alphabetical; NEWEST=1 maps to the last entry):" >&2
    for ((i=0; i<total; i++)); do
      num=$(( total - i ))
      printf "  %2d) %s\n" "$num" "${names[$i]}" >&2
    done
  else
    echo "ERROR: Unsupported OS: $os" >&2
    return 1
  fi

  echo >&2
  # Input loop: accept number or name; validate; reprompt on error
  local typed chosen
  while true; do
    read -r -p "Enter NUMBER or NAME to remove (default: 1 - ${default_name}): " typed
    if [[ -z "$typed" ]]; then
      chosen="$default_name"
      break
    elif [[ "$typed" =~ ^[0-9]+$ ]]; then
      local n="$typed"
      if (( n>=1 && n<=total )); then
        local idx=$(( total - n ))  # map number to index
        chosen="${names[$idx]}"
        break
      else
        echo "Invalid number '$n'. Enter a value between 1 and $total." >&2
      fi
    else
      # match name exactly; case-sensitive to avoid surprises
      local found=0
      for nm in "${names[@]}"; do
        if [[ "$nm" == "$typed" ]]; then chosen="$nm"; found=1; break; fi
      done
      if (( found )); then
        break
      else
        echo "No such certificate '$typed'. Enter a listed number or exact name." >&2
      fi
    fi
  done

  echo >&2
  echo "WARNING: You are about to remove CA '$chosen' from the system trust store." >&2
  echo "This may break TLS verification for services that rely on it." >&2
  ask_yn_strict "Really remove '$chosen'?" || { echo "Cancelled." >&2; return 2; }

  printf "%s" "$chosen"
  return 0
}

remove_linux_ca() {
  local ca_base="$1" force="$2" dry="$3"
  local flavor dest upd_cmd
  flavor="$(linux_flavor)"
  case "$flavor" in
    debian) dest="/usr/local/share/ca-certificates/${ca_base}.crt"; upd_cmd=(update-ca-certificates) ;;
    redhat) dest="/etc/pki/ca-trust/source/anchors/${ca_base}.crt"; upd_cmd=(update-ca-trust extract) ;;
    p11kit) dest="/etc/ca-certificates/trust-source/anchors/${ca_base}.crt"; upd_cmd=(trust extract-compat) ;;
    *) echo "ERROR: Unsupported Linux trust store." >&2; return 1 ;;
  esac

  if [[ ! -e "$dest" ]]; then
    echo "Not found (skipping): $dest" >&2
    return 0
  fi

  if [[ "$force" != "1" ]]; then
    echo "About to REMOVE: $dest" >&2
    ask_yn_strict "Proceed?" || { echo "Skipped." >&2; return 0; }
  fi

  if [[ "$dry" == "1" ]]; then
    echo "[dry-run] sudo rm -f '$dest'" >&2
    echo "[dry-run] sudo ${upd_cmd[*]}" >&2
    return 0
  fi

  if have sudo && [[ $EUID -ne 0 ]]; then
    sudo rm -f "$dest"
    sudo "${upd_cmd[@]}"
  else
    rm -f "$dest"
    "${upd_cmd[@]}"
  fi
  echo "Removed and updated trust: $dest" >&2
}

remove_macos_ca() {
  local ca_base="$1" force="$2" dry="$3"
  local keychain="/Library/Keychains/System.keychain"
  if ! have security; then echo "ERROR: 'security' not found on macOS." >&2; return 1; fi

  mapfile -t hashes < <(security find-certificate -a -c "$ca_base" -Z "$keychain" 2>/dev/null | awk '/SHA-1 hash:/ {print $3}')
  if (( ${#hashes[@]} == 0 )); then
    echo "No System keychain matches for CN=\"$ca_base\"" >&2
    return 0
  fi

  for h in "${hashes[@]}"; do
    if [[ "$force" != "1" ]]; then
      echo "About to REMOVE macOS System cert: CN=\"$ca_base\", SHA-1=$h" >&2
      ask_yn_strict "Proceed?" || { echo "Skipped SHA-1=$h" >&2; continue; }
    fi
    if [[ "$dry" == "1" ]]; then
      echo "[dry-run] sudo security delete-certificate -Z $h $keychain" >&2
    else
      if have sudo && [[ $EUID -ne 0 ]]; then
        sudo security delete-certificate -Z "$h" "$keychain"
      else
        security delete-certificate -Z "$h" "$keychain"
      fi
      echo "Deleted macOS System cert (SHA-1=$h)" >&2
    fi
  done
}

# -------- args & main --------
NAMES=()
FORCE=0
DRYRUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) NAMES+=("$2"); shift 2 ;;
    --force) FORCE=1; shift ;;
    --dry-run) DRYRUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

OS="$(uname -s)"
if (( ${#NAMES[@]} == 0 )); then
  pick="$(interactive_pick_name)" || rc=$?
  if [[ "${rc:-0}" -ne 0 ]]; then exit $rc; fi
  NAMES=("$pick")
fi

case "$OS" in
  Linux)
    for name in "${NAMES[@]}"; do
      remove_linux_ca "$name" 1 "$DRYRUN"   # 1 = already confirmed in picker
    done
    ;;
  Darwin)
    for name in "${NAMES[@]}"; do
      remove_macos_ca "$name" 1 "$DRYRUN"
    done
    ;;
  *) echo "ERROR: Unsupported OS: $OS" >&2; exit 1 ;;
esac
