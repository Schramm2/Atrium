#!/usr/bin/env bash
# Creates the local code signing identity that development builds use.
#
# macOS ties Microphone, Speech Recognition, and Screen Recording access to an
# application's code signature. An ad-hoc signature changes with every build, so
# every rebuild loses the access the previous build was granted. One self-signed
# identity in the login keychain keeps the signature stable, and the grants with
# it. This identity is for local builds only. Released disk images stay ad-hoc
# signed; see docs/RELEASING.md.
#
# Keychain Access asks for permission while this script runs.
set -euo pipefail

IDENTITY_NAME="${ATRIUM_SIGNING_IDENTITY:-Atrium Local Signing}"
KEYCHAIN="${HOME}/Library/Keychains/login.keychain-db"

if /usr/bin/security find-identity -v -p codesigning 2>/dev/null | grep -qF "$IDENTITY_NAME"; then
  echo "$IDENTITY_NAME is already available. ./script/build_and_run.sh uses it."
  exit 0
fi

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/atrium-signing.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

/usr/bin/openssl req -x509 \
  -newkey rsa:2048 \
  -nodes \
  -days 3650 \
  -keyout "$work_dir/key.pem" \
  -out "$work_dir/certificate.pem" \
  -subj "/CN=$IDENTITY_NAME" \
  -addext "basicConstraints=critical,CA:false" \
  -addext "keyUsage=critical,digitalSignature" \
  -addext "extendedKeyUsage=critical,codeSigning" >/dev/null 2>&1

# The bundle needs a passphrase. macOS rejects a PKCS#12 file exported with an
# empty one: "MAC verification failed during PKCS12 import". The passphrase
# protects the temporary file only, and that file is removed when this ends.
TRANSFER_PASSPHRASE="atrium-local-signing"

/usr/bin/openssl pkcs12 -export \
  -inkey "$work_dir/key.pem" \
  -in "$work_dir/certificate.pem" \
  -name "$IDENTITY_NAME" \
  -passout "pass:$TRANSFER_PASSPHRASE" \
  -out "$work_dir/identity.p12" >/dev/null 2>&1

/usr/bin/security import "$work_dir/identity.p12" \
  -k "$KEYCHAIN" \
  -P "$TRANSFER_PASSPHRASE" \
  -T /usr/bin/codesign \
  -T /usr/bin/security >/dev/null

# codesign ignores an untrusted certificate, so the certificate must be trusted
# for code signing. This trust applies to this user account only, and macOS asks
# for the login password here.
/usr/bin/security add-trusted-cert \
  -p codeSign \
  -k "$KEYCHAIN" \
  "$work_dir/certificate.pem"

if /usr/bin/security find-identity -v -p codesigning | grep -qF "$IDENTITY_NAME"; then
  echo "Created $IDENTITY_NAME."
  echo "Build once with ./script/build_and_run.sh run, then grant Microphone, Speech Recognition, and Screen Recording access. Later builds keep that access."
else
  echo "Could not create $IDENTITY_NAME. Development builds stay ad-hoc signed." >&2
  echo "Remove the partial item in Keychain Access before trying again." >&2
  exit 1
fi
