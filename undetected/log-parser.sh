#!/bin/bash

LOG_DIR="./logs"
TOTAL_MB=0

echo "[*] Parsing logs from $LOG_DIR..."

# Iterate through all log files in the logs directory
for f in $LOG_DIR/bgmi-*.log; do
  while IFS= read -r line; do
    # Look for lines indicating traffic benchmarks
    if [[ "$line" == *"Benchmarking to"* ]]; then
      RATE=$(echo "$line" | grep -oP '\d+(?=MBps)')
      DUR=$(echo "$line" | grep -oP '\d+(?=s)' | tail -1)
      TOTAL_MB=$((TOTAL_MB + RATE * DUR))
    fi
  done < "$f"
done

echo "=========================================="
echo "[✓] Estimated total transfer: $TOTAL_MB MB"
echo "[✓] Approx: $((TOTAL_MB / 1024)) GB"
echo "=========================================="
