#!/bin/bash

set -eu

# Set up a temporary directory; this may have already been set up by the outer
# process (if running under `pseudo`).
if [ -z "${DEBAZEL_TOOL_TMPDIR:-}" ]; then
  export DEBAZEL_TOOL_TMPDIR="$(mktemp -d "$(pwd)/binary_package.XXXXXXXX")"
fi

function usage() {
  cat >&2 <<EOF
Usage: $0 [--run_under_pseudo=path/to/pseudo] <flags>

Flags:
  --changelog_file=debian/changelog
  --control_file=debian/control
  --manifest=path/to/manifest.txt
  --output_dir=path/for/output_debs
  --output_filelist=path/for/output.filelist
  --package=my-package
EOF
  [ 0 -eq "$#" ] || echo "ERROR: $*" >&2
  exit 1
}

# If --run_under_pseudo was specified, it must be first, but we will re-exec
# with all remaining flags.
case "$1" in
  (--run_under_pseudo=*)
    WRAPPER="$(realpath -es "${1##--run_under_pseudo=}")"
    shift 1

    # Set up `pseudo`
    export PSEUDO_BINDIR="$(dirname "${WRAPPER}")"
    export PSEUDO_LIBDIR="${PSEUDO_BINDIR}/lib/pseudo"
    export PSEUDO_PREFIX="${DEBAZEL_TOOL_TMPDIR}/pseudo"
    mkdir "${PSEUDO_PREFIX}"
    exec "${WRAPPER}" "$0" "$@"
    ;;
esac

CHANGELOG_FILE=""
CONTROL_FILE=""
MANIFEST=""
OUTPUT_DIR=""
OUTPUT_FILELIST=""
PACKAGE=""
while [ 0 -lt "$#" ]; do
  case "$1" in
    (--)
      shift 1
      break
      ;;
    (--run_under_pseudo=*)
      usage "The flag '--run_under_pseudo' MUST be first!"
      ;;
    (--changelog_file=*)
      CHANGELOG_FILE="$(realpath -es "${1##--changelog_file=}")"
      shift 1
      ;;
    (--control_file=*)
      CONTROL_FILE="$(realpath -es "${1##--control_file=}")"
      shift 1
      ;;
    (--manifest=*)
      MANIFEST="$(realpath -es "${1##--manifest=}")"
      shift 1
      ;;
    (--output_dir=*)
      OUTPUT_DIR="$(realpath -ms "${1##--output_dir=}")"
      shift 1
      ;;
    (--output_filelist=*)
      OUTPUT_FILELIST="$(realpath -ms "${1##--output_filelist=}")"
      shift 1
      ;;
    (--package=*)
      PACKAGE="${1##--package=}"
      shift 1
      ;;
    (--*=*)
      usage "Unrecognized option ${1%%=*}"
      exit 1
      ;;
    (--*)
      usage "Options must be specified with '=' signs: $1"
      exit 1
      ;;
    (-*)
      usage "Short-form options are not supported: $1"
      exit 1
      ;;
    (*)
      break
      ;;
  esac
done

[ 0 -eq "$#" ] || usage "Positional arguments are not supported: $1"
[ -n "${CHANGELOG_FILE}" ] || usage "Must specify --changelog_file"
[ -n "${CONTROL_FILE}" ] || usage "Must specify --control_file"
[ -n "${MANIFEST}" ] || usage "Must specify --manifest"
[ -n "${OUTPUT_DIR}" ] || usage "Must specify --output_dir"
[ -n "${OUTPUT_FILELIST}" ] || usage "Must specify --output_filelist"
[ -n "${PACKAGE}" ] || usage "Must specify --package"

PKGDIR="${DEBAZEL_TOOL_TMPDIR}/package"
mkdir -p "${PKGDIR}/DEBIAN"
mkdir -p "${PKGDIR}/usr/share/doc/${PACKAGE}"

# Gzip the debian changelog and stuff it into the package
#
# Native packages (without a `-` in the name) use `changelog.gz`, whereas
# packages with a separate upstream use `changelog.Debian.gz`.
case "$(dpkg-parsechangelog -l"${CHANGELOG_FILE}" -Sversion)" in
  (*-*) SHIPPED_CHANGELOG_NAME="changelog.Debian.gz";;
  (*)   SHIPPED_CHANGELOG_NAME="changelog.gz";;
esac
gzip -9nc <"${CHANGELOG_FILE}" \
  >"${PKGDIR}/usr/share/doc/${PACKAGE}/${SHIPPED_CHANGELOG_NAME}"

# Copy files into the package directory
exec 9<"${MANIFEST}"
while read -r -u 9 -a LINE; do
  case "${LINE[0]}" in
    (CONTROL)
      [ 3 -eq "${#LINE[@]}" ] || usage "Invalid manifest CONTROL: ${LINE[*]}"
      [ "Xcontrol" != "X${LINE[1]}" ] \
        || usage "Cannot overwrite 'control': ${LINE[*]}"
      cp -L -- "${LINE[2]}" "${PKGDIR}/DEBIAN/${LINE[1]}"
      ;;
    (MKDIR)
      [ 5 -eq "${#LINE[@]}" ] || usage "Invalid manifest MKDIR: ${LINE[*]}"
      install -d "${PKGDIR}/${LINE[1]}" \
        -o "${LINE[2]}" -g "${LINE[3]}" -m "${LINE[4]}"
      ;;
    (FILE)
      [ 6 -eq "${#LINE[@]}" ] || usage "Invalid manifest FILE: ${LINE[*]}"
      install -m 0755 -d "$(dirname "${PKGDIR}/${LINE[1]}")"
      cp -Lp -- "${LINE[2]}" "${PKGDIR}/${LINE[1]}"
      chown -- "${LINE[3]}:${LINE[4]}" "${PKGDIR}/${LINE[1]}"
      chmod -- "${LINE[5]}" "${PKGDIR}/${LINE[1]}"
      ;;
    (SYMLINK)
      [ 3 -eq "${#LINE[@]}" ] || usage "Invalid manifest SYMLINK: ${LINE[*]}"
      install -m 0755 -d "$(dirname "${PKGDIR}/${LINE[1]}")"
      ln -s "${LINE[0]}" "${PKGDIR}/${LINE[1]}"
      ;;
    (*)
      usage "Unknown manifest line: ${LINE[*]}"
      ;;
  esac
done
exec 9<&-

# Create an md5sums control file
find "${PKGDIR}" \( -path "${PKGDIR}/DEBIAN" -type d -prune \) \
  -o -type f -printf '%P\0' | LANG=C sort -z | \
  ( cd "${PKGDIR}" && xargs -0r md5sum -- ) \
  >"${PKGDIR}/DEBIAN/md5sums"

# The "dpkg-gencontrol" command uses the "debian/control" file as a lockfile,
# so we need to copy the control file to a writable location first, and then
# make sure we chdir to a temporary directory so it can't find files in the
# normal directory.
WRITABLE_DIR="${DEBAZEL_TOOL_TMPDIR}/gencontrol"
mkdir -p "${WRITABLE_DIR}/debian"
cp "${CHANGELOG_FILE}" "${WRITABLE_DIR}/debian/changelog"
cp "${CONTROL_FILE}" "${WRITABLE_DIR}/debian/control"
( cd "${WRITABLE_DIR}" && \
  dpkg-gencontrol -P"${PKGDIR}" -p"${PACKAGE}" -f"${OUTPUT_FILELIST}" )

mkdir -p "${OUTPUT_DIR}"
exec dpkg-deb -b "${PKGDIR}" "${OUTPUT_DIR}"
