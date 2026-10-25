"""Serve the Mem0 app on both an IPv4 and an IPv6 socket.

Railway's healthcheck and public edge reach the container over IPv4 while the private
network may be IPv6-only, and a single `--host ::` socket was not reachable by the
healthcheck (no request ever logged). uvicorn 0.34 accepts one --host, so open the sockets here.
"""
import os
import socket

import uvicorn

port = int(os.environ.get("PORT", "8080"))

sockets = []
v4 = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
v4.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
v4.bind(("0.0.0.0", port))
sockets.append(v4)

try:
    v6 = socket.socket(socket.AF_INET6, socket.SOCK_STREAM)
    v6.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    v6.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 1)
    v6.bind(("::", port))
    sockets.append(v6)
except OSError as exc:
    print(f"[railway] no IPv6 socket ({exc}); serving IPv4 only", flush=True)

print(f"[railway] listening on port {port} with {len(sockets)} socket(s)", flush=True)
uvicorn.Server(uvicorn.Config("main:app", log_level="info")).run(sockets=sockets)
