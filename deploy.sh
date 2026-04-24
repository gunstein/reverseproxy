#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${ROOT_DIR}/../source"
PINBALL_REPO_DIR="${SOURCE_DIR}/Pinball2DMulti"
MYPAGE_REPO_DIR="${SOURCE_DIR}/mypage_server"
BLOKKFLYT_REPO_DIR="${SOURCE_DIR}/blokkflyt"
PRUNE_CACHE=""
REBUILD_ALL=""
for arg in "$@"; do
  case "$arg" in
    delete_podman_cache) PRUNE_CACHE="delete_podman_cache" ;;
    rebuild_all) REBUILD_ALL="rebuild_all" ;;
  esac
done

PINBALL_REPO_URL="https://github.com/gunstein/Pinball2DMulti"
MYPAGE_REPO_URL="https://github.com/gunstein/mypage_server"
BLOKKFLYT_REPO_URL="https://github.com/gunstein/blokkflyt"

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

echo "==> Oppdaterer blokkflyt-kildekode"
if [ -d "${BLOKKFLYT_REPO_DIR}/.git" ]; then
  git -C "${BLOKKFLYT_REPO_DIR}" pull --ff-only
else
  git clone "${BLOKKFLYT_REPO_URL}" "${BLOKKFLYT_REPO_DIR}"
fi

cd "${ROOT_DIR}"

if [ "${REBUILD_ALL}" = "rebuild_all" ]; then
  echo "==> Sletter lokale images for full rebuild"
  podman rmi -f localhost/mypage_server:local localhost/pinball_web:local localhost/pinball_bevy_web:local localhost/pinball_server:local localhost/blokkflyt_web:local localhost/blokkflyt_server:local 2>/dev/null || true
fi

echo "==> Bygger tjenester"
"${COMPOSE_CMD[@]}" build mypage_server pinball_web pinball_bevy_web pinball_server blokkflyt_web blokkflyt_server

echo "==> Restarter tjenester"
"${COMPOSE_CMD[@]}" up -d --force-recreate traefik pinball2d pinball3d mypage_server pinball_web pinball_bevy_web pinball_server blokkflyt_web blokkflyt_server

echo "==> Status"
"${COMPOSE_CMD[@]}" ps

if [ "${PRUNE_CACHE}" = "delete_podman_cache" ]; then
  echo "==> Rydder ubrukte images"
  podman image prune -f
fi

echo "==> Ferdig"
