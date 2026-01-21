# https://github.com/casey/just

set dotenv-load := true

uv := "PYTHONPATH=. uv"

################################################################################
## Recipes
################################################################################

_default:
  @just --list --unsorted

_uv_sync:
  {{uv}} sync


################################################################################
### Linting & formatting

# lint one python file (or all by default)
check-python +target=".": _uv_sync
  {{uv}} run ruff check --force-exclude --extend-select I {{target}}
  {{uv}} run ruff format --force-exclude --check {{target}}

# fix one python file (or all by default)
fix-python +target=".": _uv_sync
  {{uv}} run ruff check --force-exclude --extend-select I --fix {{target}}
  {{uv}} run ruff format --force-exclude {{target}}

check-all: check-python

fix-all: fix-python


################################################################################
### Testing

# run tests
test: _uv_sync
  {{uv}} run pytest


################################################################################
### Running

# Run all services; the API is available at http://localhost:8000
run: _build _check
  docker compose up

# Run all services, including the Celery monitor (available on http://localhost:9000)
debug: _build-debug _check
  docker compose --profile debug up

_check:
  @test -n "$BRIGHTWAY2_DIR" || (echo "the BRIGHTWAY2_DIR envvar is not set; see .env.sample" && false)
  @test -n "$EB_OUTPUT_DIR" || (echo "the EB_OUTPUT_DIR envvar is not set; see .env.sample" && false)
  @test -n "$EB_DB_CACHE_DIR" || (echo "the EB_DB_CACHE_DIR envvar is not set; see .env.sample" && false)
  @test -n "$EB_S3_ENDPOINT" || (echo "the EB_S3_ENDPOINT envvar is not set; see .env.sample" && false)
  @test -n "$EB_S3_REGION" || (echo "the EB_S3_REGION envvar is not set; see .env.sample" && false)
  @test -n "$EB_S3_ACCESS_KEY_ID" || (echo "the EB_S3_ACCESS_KEY_ID envvar is not set; see .env.sample" && false)
  @test -n "$EB_S3_SECRET_ACCESS_KEY" || (echo "the EB_S3_SECRET_ACCESS_KEY envvar is not set; see .env.sample" && false)
  @test -n "$EB_S3_BUCKET" || (echo "the EB_S3_BUCKET envvar is not set; see .env.sample" && false)
  @test -n "$EB_S3_DB_PREFIX" || (echo "the EB_S3_DB_PREFIX envvar is not set; see .env.sample" && false)

_build: _check
  @# We want
  @# - the container user (`eb`) to have an UID with read/write access to the
  @#   volumes. By default, we take the host user id.
  @# - to add the host `docker` group id to the `eb` user so that they are
  @#   allowed to launch the sibling container.

  docker compose build \
    --build-arg DOCKER_GID="${DOCKER_GID:-`getent group docker|cut -d: -f3`}" \
    --build-arg USER_ID="${CONTAINER_USER_ID:-`id -u`}"

_build-debug: _check
  docker compose --profile debug build \
    --build-arg DOCKER_GID="${DOCKER_GID:-`getent group docker|cut -d: -f3`}" \
    --build-arg USER_ID="${CONTAINER_USER_ID:-`id -u`}"

# stop all services
stop:
  docker compose down

# stop all services and cleanup orphans and images
clean:
  docker compose down --remove-orphans --rmi all
