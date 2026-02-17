#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${ROOT_DIR}/../source"
PINBALL_REPO_DIR="${SOURCE_DIR}/Pinball2DMulti"
MYPAGE_REPO_DIR="${SOURCE_DIR}/mypage_server"

PINBALL_REPO_URL="https://github.com/gunstein/Pinball2DMulti"
MYPAGE_REPO_URL="https://github.com/gunstein/mypage_server"

if command -v podman-compose >/dev/null 2>&1; then
  COMPOSE_CMD=(podman-compose)
elif command -v podman >/dev/null 2>&1; then
  COMPOSE_CMD=(podman compose)
else
  echo "Fant ikke podman-compose eller podman compose." >&2
  exit 1
fi

echo "==> Oppdaterer reverseproxy-repo"
git -C "${ROOT_DIR}" pull --ff-only

mkdir -p "${SOURCE_DIR}"

echo "==> Oppdaterer mypage_server-kildekode"
if [ -d "${MYPAGE_REPO_DIR}/.git" ]; then
  git -C "${MYPAGE_REPO_DIR}" pull --ff-only
else
  git clone "${MYPAGE_REPO_URL}" "${MYPAGE_REPO_DIR}"
fi

echo "==> Oppdaterer Pinball2DMulti-kildekode"
if [ -d "${PINBALL_REPO_DIR}/.git" ]; then
  git -C "${PINBALL_REPO_DIR}" pull --ff-only
else
  git clone "${PINBALL_REPO_URL}" "${PINBALL_REPO_DIR}"
fi

cd "${ROOT_DIR}"

echo "==> Bygger tjenester"
"${COMPOSE_CMD[@]}" build mypage_server pinball_web pinball_bevy_web pinball_server

echo "==> Restarter tjenester"
"${COMPOSE_CMD[@]}" up -d --force-recreate traefik mypage_server pinball_web pinball_bevy_web pinball_server

echo "==> Rydder ubrukte images"
podman image prune -f

echo "==> Status"
"${COMPOSE_CMD[@]}" ps

echo "==> Ferdig"
