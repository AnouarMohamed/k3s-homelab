#!/usr/bin/env bash
set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
postgres_image="$(
  sed -n 's/^POSTGRES_TEST_IMAGE=//p' \
    "${repository_root}/apps/sentinel/dependencies.env"
)"
container_name="sentinel-integration-$$"

cleanup() {
  docker rm --force "${container_name}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker run --detach --rm \
  --name "${container_name}" \
  --env POSTGRES_DB=sentinel \
  --env POSTGRES_USER=sentinel \
  --env POSTGRES_PASSWORD=integration-only \
  --publish 127.0.0.1:0:5432 \
  "${postgres_image}" >/dev/null

host_port="$(docker port "${container_name}" 5432/tcp | sed 's/.*://')"
export DATABASE_URL="postgres://sentinel:integration-only@127.0.0.1:${host_port}/sentinel?sslmode=disable"

cd "${repository_root}/apps/sentinel"
go test -race -tags=integration ./internal/database
