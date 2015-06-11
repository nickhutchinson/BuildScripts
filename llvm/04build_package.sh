#!/bin/bash
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/_common.sh"

run find "$STAGING" -type f | xargs strip --strip-debug || true

fpm_args=(
    -s dir
    -t rpm
    --rpm-compression=xz
    --rpm-auto-add-directories
    --maintainer "Nick Hutchinson <nick.hutchinson@thefoundry.co.uk>"

    -n "$PACKAGE_NAME"
    -v "$PACKAGE_VERSION"
    --epoch "$PACKAGE_EPOCH"
)
run fpm "${fpm_args[@]}" -C "$STAGING" .
