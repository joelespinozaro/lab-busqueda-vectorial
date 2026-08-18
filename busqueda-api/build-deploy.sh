#!/usr/bin/env bash
# =============================================================================
# build-deploy.sh — Empaquetado y despliegue de busqueda-api (Python) en GCP.
#
# Uso:
#   ./build-deploy.sh
#
# Pre-requisitos:
#   - gcloud CLI instalado y autenticado con la cuenta de despliegue.
#   - Docker instalado y en ejecución.
#   - Archivo .env presente en el mismo directorio que este script.
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# Variables del proyecto — ajusta estos valores antes de ejecutar el script.
# ---------------------------------------------------------------------------
GCP_PROJECT="project-6c8e3774-833d-451c-b3e"
COMPONENT_NAME="busqueda-api"
REPOSITORY_NAME="docker"
GCP_REGION="us-central1"

# ---------------------------------------------------------------------------
# Variables derivadas (no modificar)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
IMAGE_TAG="$(date +%Y%m%d-%H%M%S)"
IMAGE_NAME="${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT}/${REPOSITORY_NAME}/${COMPONENT_NAME}"
FULL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

# ---------------------------------------------------------------------------
# Variables excluidas del despliegue en Cloud Run.
# Separadas por '|' para construir el patrón de grep.
# ---------------------------------------------------------------------------
EXCLUDED_VARS="LOCAL_DEV_EMAIL|FIRESTORE_EMULATOR_HOST|PORT"

# ---------------------------------------------------------------------------
# Funciones auxiliares
# ---------------------------------------------------------------------------
log()  { echo "[$(date +%H:%M:%S)] $*"; }
step() { echo; echo "──────────────────────────────────────────"; log "▶ $*"; echo "──────────────────────────────────────────"; }
fail() { echo "[ERROR] $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Validaciones previas
# ---------------------------------------------------------------------------
step "Validando pre-requisitos"

[[ -f "${ENV_FILE}" ]] || fail "No se encontró el archivo .env en: ${ENV_FILE}"
command -v gcloud  &>/dev/null || fail "gcloud CLI no está instalado."
command -v docker  &>/dev/null || fail "Docker no está instalado."
command -v python3 &>/dev/null || fail "python3 no está instalado."

log "Pre-requisitos OK"
log "  Proyecto GCP : ${GCP_PROJECT}"
log "  Componente   : ${COMPONENT_NAME}"
log "  Repositorio  : ${REPOSITORY_NAME}"
log "  Región       : ${GCP_REGION}"
log "  Imagen       : ${FULL_IMAGE}"

# ---------------------------------------------------------------------------
# 1. Generación de la imagen Docker
# ---------------------------------------------------------------------------
step "1/3 — Construyendo imagen Docker: ${FULL_IMAGE}"

docker build \
  --platform linux/amd64 \
  --tag "${FULL_IMAGE}" \
  "${SCRIPT_DIR}"

log "Imagen construida correctamente."

# ---------------------------------------------------------------------------
# 2. Publicación de la imagen en Artifact Registry
# ---------------------------------------------------------------------------
step "2/3 — Publicando imagen en Artifact Registry"

gcloud auth configure-docker "${GCP_REGION}-docker.pkg.dev" --quiet

docker push "${FULL_IMAGE}"

log "Imagen publicada en: ${FULL_IMAGE}"

# ---------------------------------------------------------------------------
# 3. Construcción del bloque de variables de entorno para Cloud Run.
#    Se leen desde .env, se omiten comentarios, líneas vacías y las variables
#    excluidas definidas en EXCLUDED_VARS.
#    Se usa el delimitador '^|^' para evitar conflictos con comas en valores.
# ---------------------------------------------------------------------------
step "3/3 — Desplegando en Cloud Run: ${COMPONENT_NAME}"

log "Leyendo variables de entorno desde: ${ENV_FILE}"

env_vars=""
while IFS= read -r line || [[ -n "${line}" ]]; do
  # Ignorar líneas vacías y comentarios
  [[ -z "${line}" || "${line}" =~ ^[[:space:]]*# ]] && continue

  # Ignorar variables comentadas parcialmente (por si acaso)
  key="${line%%=*}"
  [[ -z "${key}" ]] && continue

  # Ignorar variables excluidas
  if echo "${key}" | grep -qE "^(${EXCLUDED_VARS})$"; then
    log "  [omitida] ${key}"
    continue
  fi

  if [[ -z "${env_vars}" ]]; then
    env_vars="${line}"
  else
    env_vars="${env_vars}|${line}"
  fi
done < "${ENV_FILE}"

log "Variables de entorno preparadas (${#env_vars} caracteres)."

gcloud run deploy "${COMPONENT_NAME}" \
  --image="${FULL_IMAGE}" \
  --region="${GCP_REGION}" \
  --project="${GCP_PROJECT}" \
  --platform=managed \
  --set-env-vars="^|^${env_vars}" \
  --no-allow-unauthenticated \
  --quiet

# ---------------------------------------------------------------------------
# Resumen final
# ---------------------------------------------------------------------------
echo
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Despliegue completado exitosamente                          ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf  "║  Servicio  : %-48s║\n" "${COMPONENT_NAME}"
printf  "║  Imagen    : %-48s║\n" "${IMAGE_TAG}"
printf  "║  Proyecto  : %-48s║\n" "${GCP_PROJECT}"
printf  "║  Región    : %-48s║\n" "${GCP_REGION}"
echo "╚══════════════════════════════════════════════════════════════╝"
