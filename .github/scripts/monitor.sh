#!/usr/bin/env bash
set -euo pipefail

# Monitor rollup until block finalization height is reached.
# Usage: RPC_URL=<rpc_url> ./monitor.sh

# Helper function to format key=value pairs
_format_fields() {
  local msg="$1"
  shift
  local fields=""
  for arg in "$@"; do
    fields="$fields $arg"
  done
  echo "$msg$fields"
}

# Logging functions
timestamp() { date +"%Y-%m-%d %H:%M:%S"; }
log_info() { echo "$(timestamp) INFO $(_format_fields "$@")"; }
log_error() { echo "$(timestamp) ERROR $(_format_fields "$@")"; }

default_rpc_url=""
rpc_url=${RPC_URL:-$default_rpc_url}
if [[ -z "${rpc_url}" ]]; then
  log_error "No rpc url provided"
  exit 1
fi
log_info "Using rpc url: ${rpc_url}"
export ETH_RPC_URL="${rpc_url}"

default_target_block=50
target_block=${TARGET_BLOCK:-$default_target_block}
log_info "Target block: ${target_block}"

default_timeout_seconds=900 # 15 minutes
timeout_seconds=${TIMEOUT_SECONDS:-$default_timeout_seconds}
log_info "Timeout: ${timeout_seconds} seconds"

start_time=$(date +%s)
end_time=$((start_time + timeout_seconds))
while true; do
  # Check if the timeout has been reached
  current_time=$(date +%s)
  if ((current_time > end_time)); then
    log_error "Timeout reached"
    exit 1
  fi

  # Get latest, safe, and finalized block numbers
  latest_block=$(cast bn)
  safe_block=$(cast bn safe)
  finalized_block=$(cast bn finalized)
  log_info "Got blocks: latest=${latest_block}, safe=${safe_block}, finalized=${finalized_block}"

  # Check whether we reached the target block for all three types
  if [[ "${latest_block}" -ge "${target_block}" ]] && [[ "${safe_block}" -ge "${target_block}" ]] && [[ "${finalized_block}" -ge "${target_block}" ]]; then
    log_info "Target block ${target_block} reached for all block types (latest, safe, finalized)"
    exit 0
  fi

  sleep 5
done

