#!/bin/bash

# Entrypoint MPI Node
# - Nyalakan SSH daemon
# - Siapkan dir
# - Keep container alive

set -e

echo "[entrypoint] Hostname : $(hostname)"
echo "[entrypoint] Starting SSH daemon..."

mkdir -p /shared /results /src /config

exec /usr/sbin/sshd -D
