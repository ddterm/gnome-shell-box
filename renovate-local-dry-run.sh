#!/bin/bash

export LOG_LEVEL="${LOG_LEVEL:-info}"
export RENOVATE_REPORT_TYPE="${RENOVATE_REPORT_TYPE:-logging}"
export RENOVATE_BASE_DIR="${RENOVATE_BASE_DIR:-$PWD/.renovate}"
export RENOVATE_PLATFORM="${RENOVATE_PLATFORM:-local}"

mkdir -p "$RENOVATE_BASE_DIR"

exec podman run \
  --rm -it \
  --userns=keep-id:uid=12021,gid=0 \
  -e LOG_CONTEXT \
  -e LOG_FILE \
  -e LOG_FILE_LEVEL \
  -e LOG_FORMAT \
  -e LOG_LEVEL \
  -e GITHUB_COM_TOKEN \
  -e 'RENOVATE_*' \
  -v "$PWD:$PWD:ro" \
  -v "$RENOVATE_BASE_DIR:$RENOVATE_BASE_DIR:U,rw" \
  -w "$PWD" \
  ghcr.io/renovatebot/renovate \
  "$@"
