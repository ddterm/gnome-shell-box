#!/bin/bash

export LOG_LEVEL="${LOG_LEVEL:-info}"
export RENOVATE_REPORT_TYPE="${RENOVATE_REPORT_TYPE:-logging}"

exec podman run \
  --rm -it \
  --userns=keep-id \
  -e LOG_LEVEL \
  -e GITHUB_COM_TOKEN \
  -e RENOVATE_REPORT_TYPE \
  -v "$PWD:$PWD" \
  -w "$PWD" \
  ghcr.io/renovatebot/renovate \
  --platform=local \
  "$@"
