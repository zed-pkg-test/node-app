#!/usr/bin/env bash
set -euo pipefail

: "${ZED_INTERFACES_REF:?ZED_INTERFACES_REF is required}"
: "${ZED_CLI_REF:?ZED_CLI_REF is required}"
: "${NODE_LIB_REF:?NODE_LIB_REF is required}"

WORKSPACE="${GITHUB_WORKSPACE:-$(pwd)}"
TEMP_ROOT="${RUNNER_TEMP:-${TMPDIR:-/tmp}/zed-pkg-test-node}"
RUN_ID="${GITHUB_SHA:-local}"
CONTEXT="$TEMP_ROOT/zed-docker-context"
REGISTRY="$TEMP_ROOT/zed-registry"
HOME_DIR="$TEMP_ROOT/zed-home"
NODE_LIB="$TEMP_ROOT/node-lib"
IMAGE="zed-pkg-test/node-e2e:$RUN_ID"

clone_at() {
  local repo="$1"
  local ref="$2"
  local destination="$3"
  git init -q "$destination"
  git -C "$destination" remote add origin "$repo"
  git -C "$destination" fetch --depth 1 origin "$ref"
  git -C "$destination" checkout -q --detach FETCH_HEAD
  test "$(git -C "$destination" rev-parse HEAD)" = "$ref"
}

prepare() {
  rm -rf "$CONTEXT" "$REGISTRY" "$HOME_DIR" "$NODE_LIB"
  mkdir -p "$CONTEXT" "$REGISTRY" "$HOME_DIR"
  cd "$WORKSPACE"

  docker run --rm \
    --volume "$WORKSPACE:/work:ro" \
    --workdir /work \
    node:22-bookworm-slim \
    npm run check

  python3 - <<'PY'
import json
import tomllib
from pathlib import Path

native = json.loads(Path("package.json").read_text())
with Path(".zpkg.toml").open("rb") as handle:
    zed = tomllib.load(handle)
package = zed["package"]
assert native["name"] == package["name"]
assert native["version"] == package["version"]
assert native["license"] == package["license"]
assert package["org"] == "zed-pkg-test"
assert zed["dependencies"] == {"zed-pkg-test/node-lib": "^1.0.0"}
PY

  clone_at https://github.com/zed-pkg/zed-interfaces.git \
    "$ZED_INTERFACES_REF" "$CONTEXT/zed-interfaces"
  clone_at https://github.com/zed-pkg/zed-cli.git \
    "$ZED_CLI_REF" "$CONTEXT/zed-cli"

  docker build \
    --file "$WORKSPACE/.github/docker/Dockerfile" \
    --tag "$IMAGE" \
    "$CONTEXT"

  clone_at https://github.com/zed-pkg-test/node-lib.git \
    "$NODE_LIB_REF" "$NODE_LIB"

  docker run --rm \
    --volume "$NODE_LIB:/package:ro" \
    --workdir /package \
    node:22-bookworm-slim \
    node -e 'const {greet}=require("./src"); if(greet("fixture")!=="hello fixture from @zed-pkg-test/node-lib") process.exit(1)'

  test -z "$(git -C "$NODE_LIB" status --porcelain)"
  docker run --rm \
    --volume "$NODE_LIB:/source:ro" \
    --volume "$REGISTRY:/registry" \
    --workdir /tmp \
    "$IMAGE" \
    sh -euc '
      cp -a /source /tmp/package
      chmod -R u+w /tmp/package
      cd /tmp/package
      zed publish --registry file:///registry --skip-vcs-checks
    '
  test -z "$(git -C "$NODE_LIB" status --porcelain)"
  test "$(git -C "$NODE_LIB" rev-parse HEAD)" = "$NODE_LIB_REF"
  if ! find "$REGISTRY" -type f -print -quit | grep -q .; then
    echo "zed publish produced no registry artifact" >&2
    exit 1
  fi
}

symlink_install() {
  cd "$WORKSPACE"
  rm -rf .vendor/.zed node_modules .zed
  docker run --rm \
    --volume "$WORKSPACE:/work" \
    --volume "$REGISTRY:/registry:ro" \
    --volume "$HOME_DIR:/zed-home" \
    --workdir /work \
    "$IMAGE" \
    sh -euc '
      zed install \
        --registry file:///registry \
        --home /zed-home \
        --install-mode symlink
      test -L .vendor/.zed/zed-pkg-test/node-lib
      test -L node_modules/@zed-pkg-test/node-lib
      npm start
    '
}

missing_store() {
  cd "$WORKSPACE"
  if docker run --rm \
    --volume "$WORKSPACE:/work:ro" \
    --workdir /work \
    node:22-bookworm-slim \
    npm start
  then
    echo "expected the unmounted store-backed symlinks to fail" >&2
    exit 1
  fi
}

copy_install() {
  cd "$WORKSPACE"
  docker run --rm \
    --volume "$WORKSPACE:/work" \
    --volume "$REGISTRY:/registry:ro" \
    --volume "$HOME_DIR:/zed-home" \
    --workdir /work \
    "$IMAGE" \
    sh -euc '
      zed install \
        --frozen \
        --registry file:///registry \
        --home /zed-home \
        --install-mode copy
      test ! -L .vendor/.zed/zed-pkg-test/node-lib
      test ! -L node_modules/@zed-pkg-test/node-lib
      test -z "$(find .vendor/.zed node_modules/@zed-pkg-test -type l -print -quit)"
      npm start
    '
}

fresh_copy() {
  cd "$WORKSPACE"
  docker run --rm \
    --volume "$WORKSPACE:/work:ro" \
    --workdir /work \
    node:22-bookworm-slim \
    npm start
}

phase="${1:-all}"
case "$phase" in
  prepare) prepare ;;
  symlink) symlink_install ;;
  missing-store) missing_store ;;
  copy) copy_install ;;
  fresh-copy) fresh_copy ;;
  all)
    prepare
    symlink_install
    missing_store
    copy_install
    fresh_copy
    ;;
  *)
    echo "unknown phase: $phase" >&2
    exit 2
    ;;
esac
