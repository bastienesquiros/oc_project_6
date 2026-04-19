#!/usr/bin/env bash
set -uo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/test-results"

log_info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_success() { echo -e "${GREEN}[PASS]${NC}  $*"; }
log_error()   { echo -e "${RED}[FAIL]${NC}  $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }

cd "$SCRIPT_DIR"

# Check dependencies
if ! command -v npm &>/dev/null; then
  log_error "npm not found"
  exit 1
fi

if ! command -v node &>/dev/null; then
  log_error "node not found"
  exit 1
fi

log_info "Node $(node --version) / npm $(npm --version)"

# Clean previous results
rm -rf "$RESULTS_DIR"
mkdir -p "$RESULTS_DIR"

# Install dependencies if needed
if [[ ! -d "node_modules" ]]; then
  log_warn "node_modules missing — running npm ci..."
  npm ci
fi

# Run tests (karma outputs JUnit XML to reports/ via karma.conf.js)
log_info "Running Angular unit tests..."
npm test
EXIT_CODE=$?

# Copy JUnit XML reports to test-results/
if [[ -d "reports" ]]; then
  find reports -name "*.xml" -exec cp {} "$RESULTS_DIR/" \; 2>/dev/null || true
  log_info "JUnit reports copied to $RESULTS_DIR"
fi

if [[ $EXIT_CODE -eq 0 ]]; then
  log_success "All tests passed!"
else
  log_error "Tests failed! (exit code: $EXIT_CODE)"
fi

exit $EXIT_CODE
