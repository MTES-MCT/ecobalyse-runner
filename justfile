# https://github.com/casey/just

set dotenv-load := true

uv := "PYTHONPATH=. uv"

################################################################################
## Recipes
################################################################################

default:
  @just --list



################################################################################
### Linting & formatting

check-python +target=".":
  {{uv}} run ruff check --force-exclude --extend-select I {{target}}
  {{uv}} run ruff format --force-exclude --check {{target}}

fix-python +target=".":
  {{uv}} run ruff check --force-exclude --extend-select I --fix {{target}}
  {{uv}} run ruff format --force-exclude {{target}}

check-all: check-python

fix-all: fix-python


################################################################################
### Testing

test:
  {{uv}} run pytest


################################################################################
### Running

run: build
  docker compose up

build:
  # We want
  # - the container user (`eb`) to have an UID with read/write access to the
  #   volumes. By default, we take the host user id.
  # - to add the host `docker` group id to the `eb` user so that they are
  #   allowed to launch the sibling container.

  docker compose build \
    --build-arg DOCKER_GID="${DOCKER_GID:-`getent group docker|cut -d: -f3`}" \
    --build-arg USER_ID="${CONTAINER_USER_ID:-`id -u`}"

stop:
  docker compose down

clean:
  docker compose down --remove-orphans --rmi all
