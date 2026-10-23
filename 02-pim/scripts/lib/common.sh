#!/usr/bin/env bash

require_cli() {
  command -v az >/dev/null 2>&1 || {
    echo "Azure CLI is required." >&2
    exit 1
  }
}

info() {
  echo "[INFO] $*"
}

ok() {
  echo "[OK] $*"
}

warn() {
  echo "[WARN] $*" >&2
}

confirm() {
  read -r -p "$1 [y/N] " answer
  [[ "$answer" =~ ^[Yy]$ ]]
}
