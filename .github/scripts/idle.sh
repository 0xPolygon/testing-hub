#!/usr/bin/env bash
set -euo pipefail

# Idle script to keep the GitHub Actions runner alive.
# Usage: ./idle.sh <duration_in_minutes>

# Source logging library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/log.sh"

duration_minutes=${1:-"60"}
duration_seconds=$((duration_minutes * 60))
log_info "Starting idle script for ${duration_minutes} minutes"

check_interval=$((duration_seconds / 100))
if [[ "${check_interval}" -lt 10 ]]; then
  check_interval=10
fi

start_time=$(date +%s)
while true; do
  current_time=$(date +%s)
  elapsed=$((current_time - start_time))
  if [[ "${elapsed}" -ge "${duration_seconds}" ]]; then
    log_info "Threshold reached, exiting"
    break
  fi

  remaining=$((duration_seconds - elapsed))
  log_info "Time remaining: ${remaining} seconds"

  sleep "${check_interval}"
done
