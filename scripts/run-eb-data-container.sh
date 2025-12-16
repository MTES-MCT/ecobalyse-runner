#!/usr/bin/env bash

EB_DATA_REPOSITORY="https://github.com/MTES-MCT/ecobalyse-data.git"

set -eo pipefail

echo "Running container for commit $*"

TMP_DIR=$(dirname "$(mktemp --dry-run)")
WORK_DIR="$TMP_DIR/eb-runner/$*"

echo "Cloning ecobalyse directory to $WORK_DIR"

# TODO: with git >= 2.49, we could use the --revision argument which would
# make the clone faster, as we could combine it with --depth. But the current
# git version in trixie is lower
#
# git clone "$EB_DATA_REPOSITORY" --revision "$@" --depth 1 "$WORK_DIR" --config advice.detachedHead=false
#
# So for now, just clone everything then checkout
git clone "$EB_DATA_REPOSITORY" "$WORK_DIR"
cd "$WORK_DIR"
git checkout "$@"


export BRIGHTWAY2_DIR=/cache/brightway
export EB_OUTPUT_DIR=/cache/output
export EB_DB_CACHE_DIR=/cache/db-cache

mkdir -p "$BRIGHTWAY2_DIR" "$EB_OUTPUT_DIR" "$EB_DB_CACHE_DIR"


docker compose run --build bw just

echo "done"
