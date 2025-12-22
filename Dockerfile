FROM ghcr.io/astral-sh/uv:trixie-slim as uv

RUN useradd -m -s /bin/bash -d /app eb

RUN DEBIAN_FRONTEND="noninteractive" && \
  apt-get update -y && \
  apt-get upgrade -y

USER eb
WORKDIR /app

COPY pyproject.toml uv.lock* ./
RUN uv sync --no-dev  --locked --compile-bytecode

# ------------------------------------------------------------------------------
FROM uv as worker

USER root
RUN DEBIAN_FRONTEND="noninteractive" && \
  apt-get install -y git docker-cli docker-compose

USER eb
WORKDIR /app
RUN uv sync --no-dev --group celery --locked --compile-bytecode

COPY tasks.py scripts ./
COPY scripts scripts ./scripts/


# ------------------------------------------------------------------------------
FROM uv as monitor

USER eb
WORKDIR /app
RUN uv sync --no-dev --group flower --locked --compile-bytecode
COPY tasks.py ./

# ------------------------------------------------------------------------------
FROM uv as web

USER eb
WORKDIR /app
RUN uv sync --no-dev --group web --locked --compile-bytecode

COPY tasks.py app.py ./
COPY assets ./assets
