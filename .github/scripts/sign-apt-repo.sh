#!/bin/sh

if [ -z "${GPG_PRIVATE_KEY}" ] || [ -z "${GPG_KEY_ID}" ]; then
    echo "ERROR: GPG_PRIVATE_KEY and GPG_KEY_ID must be set in secrets." >&2
    exit 1
fi

if [ "$#" -lt 1 ] || [ -z "$1" ]; then
    echo "ERROR: Usage: sign-apt-repo.sh REPO_DIR" >&2
    exit 1
fi

REPO_DIR="$(readlink -f "$1")"
CODENAME="${CODENAME:-noble}"
SUITE="${CODENAME}-dev"
RELEASE_FILE_DIR="${REPO_DIR}/${CODENAME}/dists/${SUITE}"
# Set up GPG.
mkdir -p "$HOME/.gnupg"
chmod 700 "$HOME/.gnupg"
echo "allow-loopback-pinentry" >> "$HOME/.gnupg/gpg-agent.conf"
gpgconf --kill gpg-agent
echo "${GPG_PRIVATE_KEY}" | gpg --batch --import

# Publish public key.
gpg --armor --export "$GPG_KEY_ID" > "$REPO_DIR/pubkey.gpg"

# Clearsign Release to produce InRelease.
gpg --yes --quiet --batch --default-key "${GPG_KEY_ID}" \
    --pinentry-mode loopback --passphrase "${GPG_PASSPHRASE}" \
    --clearsign \
    -o "$RELEASE_FILE_DIR/InRelease" "$RELEASE_FILE_DIR/Release"
