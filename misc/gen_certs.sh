#!/bin/bash
set -eo pipefail

usage() {
  cat <<'EOF'
Generate a private CA (root + intermediate) and issue TLS certificates.

USAGE
  gen_test_certs.sh <common_name> [output_dir] [--ca] [--cert] [--invalid]

ARGS
  <common_name>   Required. Leaf certificate CN (e.g. api.example.com or 192.168.1.10).
                  SANs include the CN plus localhost and 127.0.0.1.
  [output_dir]    Optional. Directory to write keys/certs (default: .).

OPTIONS (choose at least one)
  --ca            Create a Root + Intermediate CA. If a CA already exists, you’ll be
                  asked whether to overwrite it; otherwise it’s reused.
  --cert          Create CA-signed server/client certs for <common_name>. Uses the
                  existing CA or a newly created one (with --ca). Fails if no CA exists.
  --invalid       Create an alternate (untrusted) CA and issue “_alt” server/client
                  certs for negative tests.

BEHAVIOR
  • At least one action flag is required: --ca, --cert, or --invalid.
  • --ca and --cert can be used together (recommended on first run).
  • Overwrites (CA, leaf certs, fullchains) always prompt before proceeding.
  • On CA creation/overwrite, you’ll be asked whether to install the root CA into the
    system trust store (uses sudo).
  • All generated paths are printed as absolute paths.

OUTPUT FILES
  Main CA
    ca_root_{key,crt}.pem
    ca_intermediate_{key,crt}.pem

  CA-signed leaves
    <CN>_server_{key,crt}.pem
    <CN>_server_fullchain.pem    # server + intermediate
    <CN>_client_{key,crt}.pem

  Alternate (untrusted) chain
    ca_root_alt_{key,crt}.pem
    ca_intermediate_alt_{key,crt}.pem
    <CN>_server_alt_{key,crt}.pem
    <CN>_server_alt_fullchain.pem
    <CN>_client_alt_{key,crt}.pem

EXAMPLES
  # First run: create CA and issue certs
  gen_test_certs.sh local.entitywind.dev ./misc --ca --cert

  # Later: reuse existing CA, just issue new certs
  gen_test_certs.sh local.entitywind.dev ./misc --cert

  # Generate alternate untrusted chain + alt leaf certs (for failure testing)
  gen_test_certs.sh local.entitywind.dev ./misc --invalid

NOTES
  • Requires: openssl
  • On Linux, CA install uses update-ca-certificates / update-ca-trust / trust (p11-kit).
  • On macOS, CA install uses the System keychain (security add-trusted-cert).
EOF
}

# ---------- helpers ----------
normalize_dir() { local d="$1"; [[ -z "$d" ]] && d="."; [[ "$d" != "/" ]] && d="${d%/}"; echo "$d"; }
abs_dir()       { (cd "$1" && pwd -P); }
is_ipv4()       { [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; }

ask_yes_no() {
    local prompt="$1" default="${2:-N}" suffix="[y/N]"
    [[ "$default" =~ ^[Yy]$ ]] && suffix="[Y/n]"
    read -r -p "$prompt $suffix " reply
    [[ -z "$reply" ]] && reply="$default"
    [[ "$reply" =~ ^[Yy]$ ]]
}

make_ext_cfg() {
    local profile="$1" subject_cn="$2"
    local cfg; cfg="$(mktemp)"
    {
        echo "[ req ]"
        echo "distinguished_name = req_distinguished_name"
        echo "prompt = no"
        echo
        echo "[ req_distinguished_name ]"
        echo "CN = ${subject_cn}"
        echo "O = uNetworking"
        echo "OU = uSockets"
        echo
        if [[ "$profile" == "server" || "$profile" == "client" ]]; then
            echo "[ alt_names ]"
            local dns_i=1 ip_i=1
            if is_ipv4 "$subject_cn"; then
                echo "IP.${ip_i} = ${subject_cn}"; ((ip_i++))
            else
                echo "DNS.${dns_i} = ${subject_cn}"; ((dns_i++))
            fi
            echo "DNS.${dns_i} = localhost"; ((dns_i++))
            echo "IP.${ip_i} = 127.0.0.1"; ((ip_i++))
            echo
        fi
        cat <<'PROFILES'
[v3_root_ca]
basicConstraints = critical, CA:true, pathlen:1
keyUsage = critical, keyCertSign, cRLSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer

[v3_intermediate_ca]
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, keyCertSign, cRLSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer

[v3_server]
basicConstraints = CA:false
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
subjectAltName = @alt_names

[v3_client]
basicConstraints = CA:false
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
subjectAltName = @alt_names
PROFILES
    } >"$cfg"
    echo "$cfg"
}

# gen_cert path name issuer_path issuer_name profile subject_cn
gen_cert() {
    local path="$1" name="$2" issuer_path="$3" issuer_name="$4" profile="$5" subject_cn="${6:-$2}"
    mkdir -p "$path"
    local key="${path}/${name}_key.pem"
    local crt="${path}/${name}_crt.pem"
    local csr="${path}/${name}.csr"

    openssl genrsa -out "$key" 2048 >/dev/null
    echo "generated $key"

    local cfg; cfg="$(make_ext_cfg "$profile" "$subject_cn")"
    openssl req -new -sha256 -key "$key" \
      -subj "/O=uNetworking/OU=uSockets/CN=${subject_cn}" \
      -config "$cfg" -out "$csr" &>/dev/null

    if [[ -z "${issuer_path}" || -z "${issuer_name}" ]]; then
        local ext="v3_root_ca"; [[ "$profile" =~ ^(server|client)$ ]] && ext="v3_server"
        openssl x509 -req -in "$csr" -signkey "$key" -days 825 -sha256 \
            -extfile "$cfg" -extensions "$ext" -outform PEM -out "$crt" &>/dev/null
    else
        local ext_section
        case "$profile" in
            intermediate_ca) ext_section=v3_intermediate_ca ;;
            server)          ext_section=v3_server ;;
            client)          ext_section=v3_client ;;
            *)               ext_section=v3_server ;;
        esac
        openssl x509 -req -in "$csr" \
            -CA "${issuer_path}/${issuer_name}_crt.pem" \
            -CAkey "${issuer_path}/${issuer_name}_key.pem" \
            -CAcreateserial -days 825 -sha256 \
            -extfile "$cfg" -extensions "$ext_section" \
            -outform PEM -out "$crt" &>/dev/null
    fi

    rm -f "$csr" "$cfg"
    echo "generated $crt"
}

maybe_gen_cert() {
    local path="$1" name="$2" issuer_path="$3" issuer_name="$4" profile="$5" subject_cn="$6"
    local key="${path}/${name}_key.pem"
    local crt="${path}/${name}_crt.pem"
    if [[ -e "$key" || -e "$crt" ]]; then
        if ask_yes_no "Files exist for '$name' in $path. Overwrite?" "N"; then
            rm -f "$key" "$crt"
            gen_cert "$path" "$name" "$issuer_path" "$issuer_name" "$profile" "$subject_cn"
        else
            echo "Skipped generating $name."
        fi
    else
        gen_cert "$path" "$name" "$issuer_path" "$issuer_name" "$profile" "$subject_cn"
    fi
}

maybe_write_fullchain() {
    local fullpath="$1"; shift
    if [[ -e "$fullpath" ]]; then
        if ! ask_yes_no "Fullchain exists at $fullpath. Overwrite?" "N"; then
            echo "Skipped writing $fullpath"
            return 0
        fi
        rm -f "$fullpath"
    fi
    cat "$@" > "$fullpath"
    echo "generated $fullpath"
}

install_ca() {
    local abs_certs_dir="$1" ca_base="$2"
    local src="${abs_certs_dir}/${ca_base}_crt.pem"
    [[ -s "$src" ]] || { echo "ERROR: CA certificate not found at: $src"; return 1; }
    local SUDO=""; [[ $EUID -ne 0 && -x "$(command -v sudo)" ]] && SUDO="sudo"
    case "$(uname -s)" in
        Linux)
            if command -v update-ca-certificates >/dev/null 2>&1 || [[ -f /etc/debian_version ]]; then
                local dest="/usr/local/share/ca-certificates/${ca_base}.crt"
                $SUDO install -m 0644 "$src" "$dest"
                $SUDO update-ca-certificates
                echo "Installed CA to $dest (Debian/Ubuntu)."
            elif command -v update-ca-trust >/dev/null 2>&1 || [[ -f /etc/redhat-release ]]; then
                local dest="/etc/pki/ca-trust/source/anchors/${ca_base}.crt"
                $SUDO install -m 0644 "$src" "$dest"
                $SUDO update-ca-trust extract
                echo "Installed CA to $dest (RHEL/CentOS/Fedora)."
            elif command -v trust >/dev/null 2>&1; then
                local dest="/etc/ca-certificates/trust-source/anchors/${ca_base}.crt"
                $SUDO install -m 0644 "$src" "$dest"
                $SUDO trust extract-compat
                echo "Installed CA to $dest (p11-kit)."
            else
                echo "ERROR: Could not detect a known trust store update tool on this system."
                return 1
            fi
            ;;
        Darwin)
            $SUDO security add-trusted-cert -d -r trustRoot \
                -k /Library/Keychains/System.keychain "$src"
            echo "Installed CA into macOS System keychain."
            ;;
        *)  echo "ERROR: Unsupported OS $(uname -s)."; return 1 ;;
    esac
}

# ---------- args ----------
[[ -z "${1:-}" ]] && { echo "ERROR: Common Name is required."; usage; exit 2; }
CN="$1"; shift

CERTS_DIR_RAW="."
if [[ -n "${1:-}" && "${1:0:2}" != "--" ]]; then
    CERTS_DIR_RAW="$1"; shift
fi

DO_CA=0; DO_CERT=0; DO_INVALID=0
while [[ -n "${1:-}" ]]; do
    case "$1" in
        --ca) DO_CA=1 ;;
        --cert) DO_CERT=1 ;;
        --invalid) DO_INVALID=1 ;;
        *) echo "ERROR: Unknown option: $1"; usage; exit 2 ;;
    esac
    shift
done

# NEW: Require at least one actionable flag
if (( !DO_CA && !DO_CERT && !DO_INVALID )); then
    echo "ERROR: No operation specified. Add --ca and/or --cert (optionally --invalid)."
    usage
    exit 2
fi

if ! command -v openssl >/dev/null 2>&1; then
    echo "ERROR: openssl not found in PATH."
    exit 1
fi

CERTS_DIR="$(normalize_dir "$CERTS_DIR_RAW")"
mkdir -p "$CERTS_DIR"
ABS_CERTS_DIR="$(abs_dir "$CERTS_DIR")"

# Base names
MAIN_CA_ROOT="ca_root"
MAIN_CA_INT="ca_intermediate"
ALT_CA_ROOT="ca_root_alt"
ALT_CA_INT="ca_intermediate_alt"

main_ca_exists=0
[[ -s "${ABS_CERTS_DIR}/${MAIN_CA_ROOT}_crt.pem" && -s "${ABS_CERTS_DIR}/${MAIN_CA_ROOT}_key.pem" \
&& -s "${ABS_CERTS_DIR}/${MAIN_CA_INT}_crt.pem"  && -s "${ABS_CERTS_DIR}/${MAIN_CA_INT}_key.pem" ]] && main_ca_exists=1

# --ca: create CA (or prompt to overwrite)
created_or_overwrote_ca=0
if (( DO_CA )); then
    if (( main_ca_exists )); then
        if ask_yes_no "Main CA already exists in ${ABS_CERTS_DIR}. Overwrite it?" "N"; then
            rm -f "${ABS_CERTS_DIR}/${MAIN_CA_ROOT}_key.pem" "${ABS_CERTS_DIR}/${MAIN_CA_ROOT}_crt.pem" \
                  "${ABS_CERTS_DIR}/${MAIN_CA_INT}_key.pem"  "${ABS_CERTS_DIR}/${MAIN_CA_INT}_crt.pem" \
                  "${ABS_CERTS_DIR}/${MAIN_CA_ROOT}.srl" "${ABS_CERTS_DIR}/${MAIN_CA_INT}.srl" || true
            maybe_gen_cert "$ABS_CERTS_DIR" "$MAIN_CA_ROOT" "" "" "root_ca" "$MAIN_CA_ROOT"
            maybe_gen_cert "$ABS_CERTS_DIR" "$MAIN_CA_INT"  "$ABS_CERTS_DIR" "$MAIN_CA_ROOT" "intermediate_ca" "$MAIN_CA_INT"
            created_or_overwrote_ca=1
        else
            echo "Reusing existing CA."
        fi
    else
        maybe_gen_cert "$ABS_CERTS_DIR" "$MAIN_CA_ROOT" "" "" "root_ca" "$MAIN_CA_ROOT"
        maybe_gen_cert "$ABS_CERTS_DIR" "$MAIN_CA_INT"  "$ABS_CERTS_DIR" "$MAIN_CA_ROOT" "intermediate_ca" "$MAIN_CA_INT"
        created_or_overwrote_ca=1
        main_ca_exists=1
    fi
    # Re-evaluate existence
    main_ca_exists=0
    [[ -s "${ABS_CERTS_DIR}/${MAIN_CA_ROOT}_crt.pem" && -s "${ABS_CERTS_DIR}/${MAIN_CA_ROOT}_key.pem" \
    && -s "${ABS_CERTS_DIR}/${MAIN_CA_INT}_crt.pem"  && -s "${ABS_CERTS_DIR}/${MAIN_CA_INT}_key.pem" ]] && main_ca_exists=1
fi

# --cert: produce CA-signed leaves (requires CA)
if (( DO_CERT )); then
    if (( ! main_ca_exists )); then
        echo "ERROR: No CA found in ${ABS_CERTS_DIR}. Re-run with --ca (e.g. '--ca --cert') to create a CA and sign the certs."
        exit 2
    fi
    maybe_gen_cert "$ABS_CERTS_DIR" "${CN}_server" "$ABS_CERTS_DIR" "$MAIN_CA_INT" "server" "$CN"
    maybe_gen_cert "$ABS_CERTS_DIR" "${CN}_client" "$ABS_CERTS_DIR" "$MAIN_CA_INT" "client" "$CN"
    maybe_write_fullchain "${ABS_CERTS_DIR}/${CN}_server_fullchain.pem" \
        "${ABS_CERTS_DIR}/${CN}_server_crt.pem" "${ABS_CERTS_DIR}/${MAIN_CA_INT}_crt.pem"
fi

# --invalid: alternate untrusted chain + leaves
if (( DO_INVALID )); then
    maybe_gen_cert "$ABS_CERTS_DIR" "$ALT_CA_ROOT" "" "" "root_ca" "$ALT_CA_ROOT"
    maybe_gen_cert "$ABS_CERTS_DIR" "$ALT_CA_INT"  "$ABS_CERTS_DIR" "$ALT_CA_ROOT" "intermediate_ca" "$ALT_CA_INT"
    maybe_gen_cert "$ABS_CERTS_DIR" "${CN}_server_alt" "$ABS_CERTS_DIR" "$ALT_CA_INT" "server" "$CN"
    maybe_gen_cert "$ABS_CERTS_DIR" "${CN}_client_alt" "$ABS_CERTS_DIR" "$ALT_CA_INT" "client" "$CN"
    maybe_write_fullchain "${ABS_CERTS_DIR}/${CN}_server_alt_fullchain.pem" \
        "${ABS_CERTS_DIR}/${CN}_server_alt_crt.pem" "${ABS_CERTS_DIR}/${ALT_CA_INT}_crt.pem"
fi

# If we created/overwrote the main CA, offer to install its root cert
if (( created_or_overwrote_ca )); then
    echo
    if ask_yes_no "Install the Root CA (${ABS_CERTS_DIR}/${MAIN_CA_ROOT}_crt.pem) into the system trust store now?" "N"; then
        install_ca "$ABS_CERTS_DIR" "$MAIN_CA_ROOT" || { echo "Failed to install the Root CA."; exit 1; }
    else
        echo "Skipping Root CA install."
    fi
fi
