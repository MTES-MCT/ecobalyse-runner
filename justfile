# https://github.com/casey/just

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
