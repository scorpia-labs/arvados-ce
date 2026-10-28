#!/bin/sh

# Sanity checks.
if [ "$#" -ne 2 ] || [ -z "$1" ] || [ -z "$2" ]; then
    echo "ERROR: Usage: make-apt-repo.sh INPUT_DIR OUTPUT_DIR" >&2
    exit 1
fi

CODENAME="${CODENAME:-noble}"
SUITE="${CODENAME}-dev"
ARCH="${ARCH:-amd64}"
COMPONENT="main"

# Set up paths.
BINARY_SRCDIR="$(readlink -f "$1")"
REPO_DIR="$(readlink -f "$2")"
# The following are relative paths.
POOL_DIR="pool"
DIST_SUITE_DIR="dists/${SUITE}"
DIST_DESTDIR="$DIST_SUITE_DIR/$COMPONENT/binary-${ARCH}"

mkdir -p "$REPO_DIR/$CODENAME/$POOL_DIR"
mkdir -p "$REPO_DIR/$CODENAME/$DIST_DESTDIR"

cd "$REPO_DIR/$CODENAME"

# Copy .deb binaries to pool.
find "$BINARY_SRCDIR" -name '*.deb' -type f | while IFS= read -r DEB_PATH; do
    DEB_SRC_BASENAME="$(basename "$DEB_PATH")"
    case "$DEB_SRC_BASENAME" in
	lib*)
	    DEB_DST_PREFIX="$(echo "$DEB_SRC_BASENAME" | cut -c1-4)" ;;
	*)
	    DEB_DST_PREFIX="$(echo "$DEB_SRC_BASENAME" | cut -c1)" ;;
    esac
    DEB_PKGNAME="$(echo "$DEB_SRC_BASENAME" | cut -d_ -f1)"
    DEB_DST_DIR="$POOL_DIR/$COMPONENT/$DEB_DST_PREFIX/$DEB_PKGNAME"
    if ! [ -d "$DEB_DST_DIR" ]; then
	mkdir -p "$DEB_DST_DIR"
    fi
    cp "$DEB_PATH" "$DEB_DST_DIR/$DEB_SRC_BASENAME"
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
    -o "APT::FTPArchive::Release::Components=${COMPONENT}" \
    release "$DIST_SUITE_DIR" > "$DIST_SUITE_DIR/Release"
