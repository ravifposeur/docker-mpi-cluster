#!/bin/bash

# Benchmark runner
# - Compile pi.c
# - Jalankan untuk tiap NP di BENCHMARK_NP_LIST
# - Simpan hasil ke /results/benchmark.csv

set -e

HOSTFILE=${HOSTFILE:-/config/hostfile}
SRC_DIR=/src
BIN=/shared/pi
RESULT_DIR=/results
CSV="$RESULT_DIR/benchmark.csv"
SAMPLES=${PI_SAMPLES:-100000000}
NP_LIST=${BENCHMARK_NP_LIST:-"1 2 4 8"}

mkdir -p "$RESULT_DIR"

echo "==> Compile $SRC_DIR/pi.c"
make -C "$SRC_DIR" clean all
cp "$SRC_DIR/pi" "$BIN"

# Header CSV
if [ ! -f "$CSV" ]; then
    echo "np,samples,time_seconds,pi_estimate" > "$CSV"
fi

echo "==> Menjalankan benchmark (samples=$SAMPLES)"
for NP in $NP_LIST; do
    echo ""
    echo "----------------------------------------------------"
    echo "  NP = $NP"
    echo "----------------------------------------------------"

    START=$(date +%s.%N)
    OUTPUT=$(mpirun \
        --hostfile "$HOSTFILE" \
        --allow-run-as-root \
        --oversubscribe \
        --mca btl_tcp_if_include eth0 \
        --mca oob_tcp_if_include eth0 \
        -np "$NP" "$BIN" "$SAMPLES" 2>&1)
    END=$(date +%s.%N)

    echo "$OUTPUT"

    ELAPSED=$(echo "$END - $START" | bc)
    PI_EST=$(echo "$OUTPUT" | grep "Pi estimate" | awk '{print $4}')

    echo "$NP,$SAMPLES,$ELAPSED,$PI_EST" >> "$CSV"
    echo ">>> Waktu: ${ELAPSED}s | Pi: $PI_EST"
done

echo ""
echo "==> Hasil tersimpan di $CSV"
