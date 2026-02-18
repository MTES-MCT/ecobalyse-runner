# ecobalyse-runner

## Pre-requisites

- [Just](https://github.com/casey/just) to run project commands (at least v1.28)
- [uv](https://docs.astral.sh/uv/) to manage Python installs

## Configuration

Copy the `.env.sample` file to `.env`, and adapt it to your usage. If you have
configured the .env file for the ecobalyse-project, you could use it mostly
unchanged.

## Usage

For development:

- run `uv sync --all-groups` to install the python dependencies
- run `just` to see the list of commands available

On a server:

- run `just run` to launch the container

On a client:

- you have to POST to `/check/<git_commit_hash>/`, and pass the `AUTH_KEY` that you
defined in your `.env` file in the `Authorization` header.

  Ex. with httpie:
  ```sh
  http POST <HOSTNAME>/check/<git_commit_hash>/ "Authorization: Bearer <AUTH_KEY>"
  ```

  Ex. with cURL:
  ```sh
  curl -X POST -H "Authorization: Bearer <AUTH_KEY>" https://<HOSTNAME>/check/<git_commit_hash>/
  ```
