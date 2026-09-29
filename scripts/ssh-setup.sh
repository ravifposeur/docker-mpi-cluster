#!/bin/bash

# SSH Setup — verifikasi koneksi antar node
# Dijalankan di dalam container master

set -e

NODES=(worker1 worker2 worker3)

echo "==> Cek koneksi SSH ke tiap worker..."
for node in "${NODES[@]}"; do
    if ssh -o ConnectTimeout=5 -o BatchMode=yes "$node" "echo ok" >/dev/null 2>&1; then
        echo "  [OK] $node"
    else
        echo "  [FAIL] $node"
        exit 1
    fi
done

echo "==> Semua node reachable."
