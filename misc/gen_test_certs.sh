#!/bin/bash
set -eo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") <common_name> [output_dir]

  <common_name>  Required. The certificate Common Name (e.g. example.com or 192.168.1.10)
  [output_dir]   Optional. Where to write certs/keys (default: current directory)

The script generates:
  - valid_ca (CA)
  - <CN>_server signed by valid_ca
  - <CN>_client signed by valid_ca
  - invalid_ca (another CA)
  - invalid_client signed by invalid_ca
  - selfsigned_client (self-signed)
Then it prompts to install the valid_ca certificate into the system trust store.
EOF
}

# ---- arg parsing & validation ----
COMMON_NAME="${1:-}"
CERTS_DIR="${2:-.}"

if [[ -z "$COMMON_NAME" ]]; then
    echo "ERROR: Common Name is required."
    usage
    exit 2
fi

if ! command -v openssl >/dev/null 2>&1; then
    echo "ERROR: openssl not found in PATH."
    exit 1
fi

mkdir -p "$CERTS_DIR"

# Build SAN for a given CN: if IPv4 -> IP:..., else DNS:...
build_san_csv() {
    local cn="$1"
    local is_ipv4='^([0-9]{1,3}\.){3}[0-9]{1,3}$'

    # Always include localhost entries too
    if [[ "$cn" =~ $is_ipv4 ]]; then
        echo "IP:${cn},DNS:localhost,IP:127.0.0.1"
    else
        echo "DNS:${cn},DNS:localhost,IP:127.0.0.1"
    fi
}

gen_cert() {
    local path=$1
    local CN=$2
    local ca_path=$3      # optional
    local ca_name=${4:-ca}
    local san_csv=$5      # optional SAN list CSV (e.g. 'DNS:example.com,IP:127.0.0.1')

    mkdir -p "${path}"

    openssl genrsa -out "${path}/${CN}_key.pem" 2048 >/dev/null
    echo "generated ${path}/${CN}_key.pem"

    # Build a temporary config that appends a [SAN] section only if san_csv provided
    local cfg_file
    cfg_file="$(mktemp)"
    # Use system OpenSSL config as base if available; otherwise create minimal stub
    if [[ -r /etc/ssl/openssl.cnf ]]; then
        cat /etc/ssl/openssl.cnf >"${cfg_file}"
    else
        printf "%s\n" "[ req ]" "distinguished_name = req_distinguished_name" \
            "prompt = no" "req_extensions = SAN" "[$(printf req_distinguished_name)]" >> "${cfg_file}"
    fi
    if [[ -n "${san_csv:-}" ]]; then
        printf "\n[SAN]\nsubjectAltName=%s\n" "$san_csv" >> "${cfg_file}"
        local reqexts=( -reqexts SAN -extensions SAN )
    else
        local reqexts=()
    fi

    openssl req -new -sha256 \
        -key "${path}/${CN}_key.pem" \
        -subj "/O=uNetworking/O=uSockets/CN=${CN}" \
        "${reqexts[@]}" -config "${cfg_file}" \
        -out "${path}/${CN}.csr" &>/dev/null

    if [[ -z "${ca_path:-}" ]]; then
        # self-signed
        openssl x509 -req -in "${path}/${CN}.csr" \
            -signkey "${path}/${CN}_key.pem" -days 365 -sha256 \
            -outform PEM -out "${path}/${CN}_crt.pem" &>/dev/null
    else
        openssl x509 -req -in "${path}/${CN}.csr" \
            -CA "${ca_path}/${ca_name}_crt.pem" -CAkey "${ca_path}/${ca_name}_key.pem" \
            -CAcreateserial -days 365 -sha256 \
            -outform PEM -out "${path}/${CN}_crt.pem" &>/dev/null
    fi

    rm -f "${path:?}/${CN}.csr" "${cfg_file}"
    echo "generated ${path}/${CN}_crt.pem"
}

install_ca() {
    local certs_dir=$1
    local ca_base=${2:-valid_ca}
    local src="${certs_dir}/${ca_base}_crt.pem"

    if [[ ! -s "$src" ]]; then
        echo "ERROR: CA certificate not found at: $src"
        return 1
    fi

    local SUDO=""
    if [[ $EUID -ne 0 ]]; then
        if command -v sudo >/dev/null 2>&1; then
            SUDO="sudo"
        else
            echo "ERROR: Not root and 'sudo' not available."
            return 1
        fi
    fi

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
        *)
            echo "ERROR: Unsupported OS $(uname -s)."
            return 1
            ;;
    esac
}

# -----------------
# main
# -----------------
CN="$COMMON_NAME"
SAN_CSV="$(build_san_csv "$CN")"

# 1) Generate a CA
gen_cert "${CERTS_DIR}" "valid_ca"

# 2) Generate server and client signed by that CA, using the provided CN in the SANs
gen_cert "${CERTS_DIR}" "${CN}_server" "${CERTS_DIR}" "valid_ca" "${SAN_CSV}"
gen_cert "${CERTS_DIR}" "${CN}_client" "${CERTS_DIR}" "valid_ca" "${SAN_CSV}"

# 3) Extra test certs (unchanged)
gen_cert "${CERTS_DIR}" "invalid_ca"
gen_cert "${CERTS_DIR}" "invalid_client" "${CERTS_DIR}" "invalid_ca" "${SAN_CSV}"
gen_cert "${CERTS_DIR}" "selfsigned_client" "" "" "${SAN_CSV}"

echo
read -r -p "Certificates generated. Install the Certificate Authority certificate now? [y/N] " reply
if [[ "$reply" =~ ^[Yy]$ ]]; then
    install_ca "${CERTS_DIR}" "valid_ca" || {
        echo "Failed to install the CA certificate."
        exit 1
    }
else
    echo "Skipping CA install."
fi
