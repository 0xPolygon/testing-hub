#!/usr/bin/env bash
set -euo pipefail

# Run chaos-utils scenarios against a Kurtosis enclave
# Usage: ./run-chaos-tests.sh <enclave_name> <scenarios...>

# Source logging library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/log.sh"

enclave_name=${1:-""}
if [[ -z "${enclave_name}" ]]; then
  log_error "No enclave name provided"
  log_info "Usage: $0 <enclave_name> <scenario1> [scenario2] [...]"
  exit 1
fi
shift

scenarios=("$@")
if [[ ${#scenarios[@]} -eq 0 ]]; then
  log_error "No scenarios provided"
  log_info "Usage: $0 <enclave_name> <scenario1> [scenario2] [...]"
  exit 1
fi

log_info "Running chaos tests against enclave: ${enclave_name}"
log_info "Scenarios: ${scenarios[*]}"

# Verify enclave exists
if ! kurtosis enclave inspect "${enclave_name}" > /dev/null 2>&1; then
  log_error "Enclave '${enclave_name}' does not exist"
  exit 1
fi

# Create reports directory
reports_dir="${GITHUB_WORKSPACE:-$(pwd)}/chaos-reports"
mkdir -p "${reports_dir}"
log_info "Reports will be saved to: ${reports_dir}"

# Track test results
total_tests=${#scenarios[@]}
passed_tests=0
failed_tests=0
failed_scenarios=()

# Run each scenario
for scenario in "${scenarios[@]}"; do
  scenario_name=$(basename "${scenario}" .yaml)
  log_info "=========================================="
  log_info "Running scenario: ${scenario_name}"
  log_info "=========================================="

  # Run chaos-runner and capture exit code
  if /usr/local/bin/chaos-runner run --scenario "${scenario}" --enclave "${enclave_name}"; then
    log_info "✅ Scenario '${scenario_name}' passed"
    ((passed_tests++))
  else
    log_error "❌ Scenario '${scenario_name}' failed"
    ((failed_tests++))
    failed_scenarios+=("${scenario_name}")
  fi

  # Copy the scenario report if it exists
  if [[ -f "reports/${scenario_name}.json" ]]; then
    cp "reports/${scenario_name}.json" "${reports_dir}/"
    log_info "Report saved: ${reports_dir}/${scenario_name}.json"
  fi

  echo ""
done

# Print summary
log_info "=========================================="
log_info "Chaos Testing Summary"
log_info "=========================================="
log_info "Total scenarios: ${total_tests}"
log_info "Passed: ${passed_tests}"
log_info "Failed: ${failed_tests}"

if [[ ${failed_tests} -gt 0 ]]; then
  log_error "Failed scenarios:"
  for failed in "${failed_scenarios[@]}"; do
    log_error "  - ${failed}"
  done
  exit 1
fi

log_info "✅ All chaos tests passed!"
exit 0
