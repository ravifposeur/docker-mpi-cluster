#!/bin/bash

# Ambil snapshot metrik dari Prometheus

set -e

PROM=${PROM_URL:-http://prometheus:9090}
OUT=${OUT_DIR:-/results}

mkdir -p "$OUT"

echo "==> Query CPU usage..."
curl -s "${PROM}/api/v1/query?query=rate(container_cpu_usage_seconds_total[1m])" \
    -o "$OUT/metrics_cpu.json"

echo "==> Query memory usage..."
curl -s "${PROM}/api/v1/query?query=container_memory_usage_bytes" \
    -o "$OUT/metrics_mem.json"

echo "==> Query network RX..."
curl -s "${PROM}/api/v1/query?query=rate(container_network_receive_bytes_total[1m])" \
    -o "$OUT/metrics_net_rx.json"

echo "==> Selesai. Hasil di $OUT/"
