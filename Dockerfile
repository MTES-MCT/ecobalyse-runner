
FROM ghcr.io/astral-sh/uv:trixie-slim AS uv

ARG USER_ID
RUN test -n "$USER_ID" || (echo "USER_ID not set" && false)

RUN useradd -u "$USER_ID" -m -s /bin/bash -d /app eb

RUN DEBIAN_FRONTEND="noninteractive" && \
  apt-get update -y && \
  apt-get upgrade -y

USER eb
WORKDIR /app

COPY pyproject.toml uv.lock* ./
RUN uv sync --no-dev  --locked --compile-bytecode

# ------------------------------------------------------------------------------
FROM uv AS worker

USER root
RUN DEBIAN_FRONTEND="noninteractive" && \
  apt-get install -y git docker-cli docker-buildx docker-compose

ARG DOCKER_GID
RUN test -n "$DOCKER_GID" || (echo "DOCKER_GID  not set" && false)

RUN addgroup --gid ${DOCKER_GID} docker
RUN usermod -aG docker eb

USER eb
WORKDIR /app
RUN uv sync --no-dev --group celery --locked --compile-bytecode

COPY tasks.py scripts ./
COPY scripts scripts ./scripts/


# ------------------------------------------------------------------------------
FROM uv AS monitor

USER eb
WORKDIR /app
RUN uv sync --no-dev --group flower --locked --compile-bytecode
COPY tasks.py ./

# ------------------------------------------------------------------------------
FROM uv AS web

USER eb
WORKDIR /app
RUN uv sync --no-dev --group web --locked --compile-bytecode

COPY tasks.py app.py ./
COPY assets ./assets
