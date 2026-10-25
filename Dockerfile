# Mem0 self-hosted REST server (mem0ai/mem0 server/), pinned to a release tag.
# Upstream publishes no current image (mem0/mem0-api-server on Docker Hub stopped at 2025-09),
# so the server source is fetched at the tag and installed against the matching PyPI release.
FROM python:3.12-slim

ARG MEM0_VERSION=2.2.1

RUN apt-get update \
 && apt-get install -y --no-install-recommends curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN curl -fsSL "https://codeload.github.com/mem0ai/mem0/tar.gz/refs/tags/v${MEM0_VERSION}" \
  | tar -xz --strip-components=2 "mem0-${MEM0_VERSION}/server" \
 && sed -i "s/^mem0ai.*/mem0ai==${MEM0_VERSION}/" requirements.txt \
 && pip install --no-cache-dir -r requirements.txt

COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod +x /usr/local/bin/railway-entrypoint.sh

# Literals live here, not in the template's variable form: templateGenerate publishes any
# literal variable as a blank required field. Telemetry is off by default; history and the
# mem0 config dir sit on the volume at /data.
ENV PYTHONUNBUFFERED=1 \
    MEM0_TELEMETRY=false \
    MEM0_DIR=/data/mem0 \
    HISTORY_DB_PATH=/data/history.db \
    APP_DB_NAME=mem0_app \
    POSTGRES_PORT=5432 \
    POSTGRES_DB=postgres \
    POSTGRES_USER=postgres \
    POSTGRES_COLLECTION_NAME=memories

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
