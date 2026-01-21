#!/usr/bin/env bash

COMMIT_HASH="$*"

EB_DATA_REPOSITORY="https://github.com/MTES-MCT/ecobalyse-data.git"
set -eo pipefail

echo "Running container for commit $COMMIT_HASH"

TMP_DIR=$(dirname "$(mktemp --dry-run)")
WORK_DIR="$TMP_DIR/eb-runner/$COMMIT_HASH"

echo "Cloning ecobalyse directory to $WORK_DIR"

# TODO: with git >= 2.49, we could use the --revision argument which would
# make the clone faster, as we could combine it with --depth. But the current
# git version in trixie is lower
#
# git clone "$EB_DATA_REPOSITORY" --revision "$@" --depth 1 "$WORK_DIR" --config advice.detachedHead=false
#
# So for now, just clone everything then detach the commit
git clone "$EB_DATA_REPOSITORY" "$WORK_DIR"
cd "$WORK_DIR"
git switch --detach "$COMMIT_HASH"


echo "BRIGHTWAY2_DIR is $BRIGHTWAY2_DIR"
echo "EB_DB_CACHE_DIR is $EB_DB_CACHE_DIR"

# For now, generate the files in a subfolder of the usual EB_OUTPUT_DIR.
# It’s temporary until we define the whole workflow.
export EB_OUTPUT_DIR="$EB_OUTPUT_DIR/$COMMIT_HASH"
echo "EB_OUTPUT_DIR is $EB_OUTPUT_DIR"

mkdir -p "/cache/output/$COMMIT_HASH/{components,food,object,textile,veli}"

docker compose run --build bw just import-all export-all

# TODO: generate an appropriate error message if there’s a diff
diff "/cache/output/$COMMIT_HASH/processes.json" "/cache/output/processes.json"

echo "done"
