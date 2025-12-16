FROM ghcr.io/astral-sh/uv:trixie-slim as uv
RUN DEBIAN_FRONTEND="noninteractive" && \
  apt-get update -y && apt-get upgrade -y

COPY pyproject.toml /app/

WORKDIR /app

RUN uv sync --no-dev

# ------------------------------------------------------------------------------
FROM uv as worker
RUN DEBIAN_FRONTEND="noninteractive" && \
  apt-get install -y git docker-cli docker-compose

RUN uv sync --group celery

COPY tasks.py /app/
COPY scripts /app/scripts/

# ------------------------------------------------------------------------------
FROM uv as monitor

RUN uv sync --group flower
COPY tasks.py /app/

# ------------------------------------------------------------------------------
FROM uv as web

RUN uv sync --group web

COPY tasks.py app.py /app/
COPY assets /app/assets
