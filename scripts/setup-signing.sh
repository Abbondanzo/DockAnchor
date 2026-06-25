#!/bin/bash
#
# One-time setup: creates a self-signed code-signing identity in the login
# keychain so DockAnchor gets a STABLE signature across rebuilds. A stable
# signature means macOS keeps your Accessibility grant instead of forgetting
# it every time you rebuild (which ad-hoc signing causes).
#
# Safe to re-run: it does nothing if the identity already exists.
#
set -euo pipefail

IDENTITY_CN="DockAnchor Self-Signed"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

if security find-certificate -c "$IDENTITY_CN" "$KEYCHAIN" >/dev/null 2>&1; then
	echo "Identity '$IDENTITY_CN' already exists — nothing to do."
	exit 0
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/openssl.cnf" <<EOF
[req]
distinguished_name = dn
x509_extensions = v3
prompt = no
[dn]
CN = $IDENTITY_CN
[v3]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
EOF

echo "==> Generating self-signed code-signing certificate..."
openssl req -x509 -newkey rsa:2048 -nodes \
	-keyout "$WORK/key.pem" -out "$WORK/cert.pem" -days 3650 \
	-config "$WORK/openssl.cnf" -extensions v3

# -legacy is required so macOS's Security framework can read the PKCS#12
# (OpenSSL 3's default MAC/cipher is rejected by `security import`). A non-empty
# passphrase is also more reliable than an empty one for macOS import.
P12_PASS="dockanchor"
openssl pkcs12 -export -legacy -inkey "$WORK/key.pem" -in "$WORK/cert.pem" \
	-out "$WORK/identity.p12" -passout "pass:$P12_PASS"

echo "==> Importing identity into login keychain..."
security import "$WORK/identity.p12" -k "$KEYCHAIN" -P "$P12_PASS" \
	-T /usr/bin/codesign -T /usr/bin/security

# Note: we deliberately do NOT add the cert to the trust store. codesign can
# use an untrusted self-signed identity, and TCC (Accessibility) only needs the
# signature to be *stable* across rebuilds — not Gatekeeper-trusted. Skipping
# trust avoids an admin-authentication prompt.

echo "==> Done. Identity '$IDENTITY_CN' installed."
security find-identity -p codesigning | grep "$IDENTITY_CN" || true
