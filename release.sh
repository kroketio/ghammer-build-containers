#!/usr/bin/env bash
# Zips every build-<platform>-<arch> into ghammer-<version>-<platform>-<arch>.zip:
# one folder of the same name with ghammer_client, ghammer_server and README.txt.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
src="$here/../ghammer"
version="$(tr -d '[:space:]' < "$src/VERSION")"
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

for build in "$here"/build-*-*/; do
  build="${build%/}"
  name="ghammer-$version-${build##*/build-}"
  ext=""; [[ "$name" == *-windows-* ]] && ext=".exe"
  mkdir "$stage/$name"
  cp "$build/bin/ghammer_client$ext" "$build/bin/ghammer_server$ext" "$stage/$name/"
  cp "$here/RELEASE_README.txt" "$stage/$name/README.txt"
  (cd "$stage" && zip -qr -X "$name.zip" "$name")
  mv -f "$stage/$name.zip" "$here/$name.zip"
  echo "$here/$name.zip"
done
