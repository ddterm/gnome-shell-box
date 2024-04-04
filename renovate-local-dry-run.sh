#!/bin/bash

export LOG_LEVEL="${LOG_LEVEL:-debug}"

exec podman run \
  --rm -it \
  --userns=keep-id \
  -e LOG_LEVEL \
  -e GITHUB_COM_TOKEN \
  -v "$PWD:$PWD" \
  -w "$PWD" \
  ghcr.io/renovatebot/renovate:slim \
  --platform=local \
  "$@"
