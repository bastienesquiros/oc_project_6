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

cd "$SCRIPT_DIR"

# Check dependencies
if ! command -v java &>/dev/null; then
  log_error "java not found"
  exit 1
fi

if [[ ! -x "./gradlew" ]]; then
  log_error "gradlew not found or not executable"
  exit 1
fi

log_info "Java $(java -version 2>&1 | head -1)"

# Clean previous results
rm -rf "$RESULTS_DIR"
mkdir -p "$RESULTS_DIR"

# Run tests
log_info "Running Gradle unit tests..."
./gradlew clean test --no-daemon
EXIT_CODE=$?

# Copy JUnit XML reports to test-results/
if [[ -d "build/test-results/test" ]]; then
  cp build/test-results/test/*.xml "$RESULTS_DIR/" 2>/dev/null || true
  log_info "JUnit reports copied to $RESULTS_DIR"
fi

if [[ $EXIT_CODE -eq 0 ]]; then
  log_success "All tests passed!"
else
  log_error "Tests failed! (exit code: $EXIT_CODE)"
fi

exit $EXIT_CODE
