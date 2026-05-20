#!/usr/bin/env bash
set -euo pipefail

# Vox Studio: Bootstrap frontend and backend dev servers concurrently
# Usage: ./scripts/start-dev.sh

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)

echo "[dev] Starting backend (backend/dev)..."
BACKEND_DIR="$ROOT_DIR/backend"
(cd "$BACKEND_DIR" && npm run dev) &
BACKEND_PID=$!

echo "[dev] Starting frontend (frontend/vox)..."
FRONTEND_DIR="$ROOT_DIR/frontend/vox"
(cd "$FRONTEND_DIR" && npm run dev) &
FRONTEND_PID=$!

cleanup() {
  echo "[dev] Stopping processes..."
  (kill "$BACKEND_PID" 2>/dev/null) || true
  (kill "$FRONTEND_PID" 2>/dev/null) || true
}

trap 'cleanup; exit 0' SIGINT SIGTERM EXIT

echo "[dev] Backend PID: $BACKEND_PID | Frontend PID: $FRONTEND_PID"
echo "[dev] Booting in parallel. Use Ctrl-C to stop."

wait "$BACKEND_PID" "$FRONTEND_PID"
