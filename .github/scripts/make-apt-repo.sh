#!/bin/sh
set -eu

# Sanity checks.
if [ "$#" -ne 2 ] || [ -z "$1" ] || [ -z "$2" ]; then
    echo "ERROR: Usage: make-apt-repo.sh INPUT_DIR OUTPUT_DIR" >&2
    exit 1
fi

if [ -z "${GPG_PRIVATE_KEY}" ] || [ -z "${GPG_KEY_ID}" ]; then
    echo "ERROR: GPG_PRIVATE_KEY and GPG_KEY_ID must be set in secrets." >&2
    exit 1
fi

CODENAME="noble"
SUITE="${CODENAME}-dev"
ARCH="amd64"

# Set up GPG.
mkdir -p "$HOME/.gnupg"
chmod 700 "$HOME/.gnupg"
echo "allow-loopback-pinentry" >> "$HOME/.gnupg/gpg-agent.conf"
gpgconf --kill gpg-agent
echo "${GPG_PRIVATE_KEY}" | gpg --batch --import

# Set up paths.
BINARY_SRCDIR="$(readlink -f "$1")"
REPO_DIR="$(readlink -f "$2")"
# The following are elative paths.
POOL_DIR="pool"
DIST_SUITE_DIR="dists/${SUITE}"
DIST_DESTDIR="$DIST_SUITE_DIR/main/binary-${ARCH}"

mkdir -p "$REPO_DIR/$CODENAME/$POOL_DIR"
mkdir -p "$REPO_DIR/$CODENAME/$DIST_DESTDIR"

# Write public key.
gpg --armor --export "$GPG_KEY_ID" > "$REPO_DIR/pubkey.gpg"

cd "$REPO_DIR/$CODENAME"

# Copy .deb binaries to pool.
find "$BINARY_SRCDIR" -name '*.deb' -type f | while IFS= read -r DEB_PATH; do
    SRC_BASENAME="$(basename "$DEB_PATH")"
    case "$SRC_BASENAME" in
	lib*)
	    DST_PREFIX="lib" ;;
	*)
	    DST_PREFIX="$(echo "$SRC_BASENAME" | cut -c1)" ;;
    esac
    mkdir "$POOL_DIR/$DST_PREFIX"
    cp "$DEB_PATH" "$POOL_DIR/$DST_PREFIX/$SRC_BASENAME"
done

# Scan pool and generate compressed Package indices containing relative paths.
apt-ftparchive packages "$POOL_DIR" > "$DIST_DESTDIR/Packages"
gzip -fk "$DIST_DESTDIR/Packages"

# Generate Release file containing checksums of the Package indices.
apt-ftparchive \
    -o "APT::FTPArchive::Release::Origin=Arvados-CE" \
    -o "APT::FTPArchive::Release::Suite=${SUITE}" \
    -o "APT::FTPArchive::Release::Codename=${CODENAME}" \
    -o "APT::FTPArchive::Release::Architectures=${ARCH}" \
    -o "APT::FTPArchive::Release::Components=main" \
    release "$DIST_SUITE_DIR" > "$DIST_SUITE_DIR/Release"

# Clearsign Release to produce InRelease.
gpg --yes --quiet --batch --default-key "${GPG_KEY_ID}" \
    --pinentry-mode loopback --passphrase "$GPG_PASSPHRASE" \
    --clearsign \
    -o "$DIST_SUITE_DIR/InRelease" "$DIST_SUITE_DIR/Release"
