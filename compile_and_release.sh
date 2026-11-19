#!/usr/bin/env bash
# Compiles Linux and Windows in the build images, then zips both.
set -euo pipefail
cd "$(dirname "$0")"
src="$(realpath ../ghammer)"

docker run --rm -u "$(id -u):$(id -g)" -v "$src":/src -v "$PWD":/out ghammer_amd64
docker run --rm -u "$(id -u):$(id -g)" -v "$src":/src -v "$PWD":/out ghammer_win64
./release.sh
