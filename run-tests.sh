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

# Clean previous results
rm -rf "$RESULTS_DIR"
mkdir -p "$RESULTS_DIR"

BACKEND_EXIT=0
FRONTEND_EXIT=0

# ── Backend ────────────────────────────────────────────────────────────────────
log_info "=== Backend tests ==="

if ! command -v java &>/dev/null; then
  log_error "java not found — skipping backend tests"
  BACKEND_EXIT=1
elif [[ ! -x "$SCRIPT_DIR/backend/gradlew" ]]; then
  log_error "backend/gradlew not found or not executable — skipping backend tests"
  BACKEND_EXIT=1
else
  log_info "Java $(java -version 2>&1 | head -1)"
  (
    cd "$SCRIPT_DIR/backend"
    log_info "Running Gradle unit tests..."
    ./gradlew clean test --no-daemon
  )
  BACKEND_EXIT=$?

  if [[ -d "$SCRIPT_DIR/backend/build/test-results/test" ]]; then
    cp "$SCRIPT_DIR/backend/build/test-results/test/"*.xml "$RESULTS_DIR/" 2>/dev/null || true
    log_info "Backend JUnit reports copied to $RESULTS_DIR"
  fi

  if [[ $BACKEND_EXIT -eq 0 ]]; then
    log_success "Backend tests passed!"
  else
    log_error "Backend tests failed! (exit code: $BACKEND_EXIT)"
  fi
fi

echo ""

# ── Frontend ───────────────────────────────────────────────────────────────────
log_info "=== Frontend tests ==="

if ! command -v npm &>/dev/null; then
  log_error "npm not found — skipping frontend tests"
  FRONTEND_EXIT=1
elif ! command -v node &>/dev/null; then
  log_error "node not found — skipping frontend tests"
  FRONTEND_EXIT=1
else
  log_info "Node $(node --version) / npm $(npm --version)"
  (
    cd "$SCRIPT_DIR/frontend"
    if [[ ! -d "node_modules" ]]; then
      log_warn "node_modules missing — running npm ci..."
      npm ci
    fi
    log_info "Running Angular unit tests..."
    npm test
  )
  FRONTEND_EXIT=$?

  if [[ -d "$SCRIPT_DIR/frontend/reports" ]]; then
    find "$SCRIPT_DIR/frontend/reports" -name "*.xml" -exec cp {} "$RESULTS_DIR/" \; 2>/dev/null || true
    log_info "Frontend JUnit reports copied to $RESULTS_DIR"
  fi

  if [[ $FRONTEND_EXIT -eq 0 ]]; then
    log_success "Frontend tests passed!"
  else
    log_error "Frontend tests failed! (exit code: $FRONTEND_EXIT)"
  fi
fi

echo ""

# ── Summary ────────────────────────────────────────────────────────────────────
log_info "=== Summary ==="
[[ $BACKEND_EXIT -eq 0 ]]  && log_success "Backend:  PASS" || log_error "Backend:  FAIL"
[[ $FRONTEND_EXIT -eq 0 ]] && log_success "Frontend: PASS" || log_error "Frontend: FAIL"

if [[ $BACKEND_EXIT -eq 0 && $FRONTEND_EXIT -eq 0 ]]; then
  log_success "All tests passed!"
  exit 0
else
  log_error "Some tests failed!"
  exit 1
fi
