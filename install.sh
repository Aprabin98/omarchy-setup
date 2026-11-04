#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
if [[ $# -eq 0 ]]; then set -- install; fi
exec "$ROOT/bin/omarchy-setup" "$@"
