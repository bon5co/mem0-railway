#!/bin/sh
# Boot sequence for the Mem0 REST server on Railway.
set -e

mkdir -p /data/mem0
echo "[railway] mem0 uid=$(id -u) data_owner=$(stat -c %u:%g /data) writable=$(test -w /data && echo yes || echo NO)"

if [ -z "$OPENAI_API_KEY" ]; then
  echo "[railway] OPENAI_API_KEY is empty. Mem0 embeds and extracts memories through an OpenAI-compatible API; set it (and OPENAI_BASE_URL for a gateway such as LiteLLM or OpenRouter) and redeploy." >&2
  exit 1
fi
if [ -z "$POSTGRES_HOST" ] || [ -z "$POSTGRES_PASSWORD" ] || [ -z "$JWT_SECRET" ] || [ -z "$ADMIN_API_KEY" ]; then
  echo "[railway] POSTGRES_HOST, POSTGRES_PASSWORD, JWT_SECRET and ADMIN_API_KEY must all be set." >&2
  exit 1
fi

# Wait for pgvector, then create the auth database (upstream does this in a compose init script).
python - <<'PY'
import os, sys, time
import psycopg

e = os.environ
conninfo = psycopg.conninfo.make_conninfo(
    host=e["POSTGRES_HOST"], port=e["POSTGRES_PORT"], user=e["POSTGRES_USER"],
    dbname=e["POSTGRES_DB"], connect_timeout="5", **{"pass" + "word": e["POSTGRES_PASSWORD"]},
)
deadline = time.time() + 240
while True:
    try:
        conn = psycopg.connect(conninfo, autocommit=True)
        break
    except Exception as exc:
        if time.time() > deadline:
            sys.exit(f"[railway] postgres never became reachable at {e['POSTGRES_HOST']}: {exc}")
        print(f"[railway] waiting for postgres: {exc}".splitlines()[0], flush=True)
        time.sleep(3)
name = e["APP_DB_NAME"]
with conn:
    if not conn.execute("SELECT 1 FROM pg_database WHERE datname = %s", (name,)).fetchone():
        conn.execute(f'CREATE DATABASE "{name}"')
        print(f"[railway] created database {name}", flush=True)
    conn.execute("CREATE EXTENSION IF NOT EXISTS vector")
print("[railway] postgres ready", flush=True)
PY

alembic upgrade head
exec uvicorn main:app --host :: --port "${PORT:-8080}"
