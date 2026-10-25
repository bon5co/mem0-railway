# mem0-railway

Wrapper image for the [Mem0](https://github.com/mem0ai/mem0) self-hosted REST server, for the Railway template
"Mem0". Upstream's compose file builds from source and its Docker Hub image is stale, so this builds `server/`
at a release tag against the matching `mem0ai` PyPI release.

Differences from upstream's compose setup: telemetry off, no `--reload`, no dashboard container, history DB and
config on a volume at `/data`, the `mem0_app` auth database and the `vector` extension created at boot, and
migrations run before the server starts. Image: `ghcr.io/bon5co/mem0-railway`.
