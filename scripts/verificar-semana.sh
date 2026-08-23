#!/usr/bin/env bash
# Autograding del Bootcamp GitLab CE.
#
# Ejecuta las comprobaciones declaradas en bootcamp/week-NN-*/checks.json
# contra la instancia GitLab del estudiante, usando la API v4 real.
#
# Uso:
#   scripts/verificar-semana.sh --doctor
#   scripts/verificar-semana.sh 09 --proyecto <grupo>/<proyecto>
#   scripts/verificar-semana.sh 09              # usa ~/.bc-gitlab
#
# Configuración (~/.bc-gitlab):
#   GITLAB_URL=http://localhost:8888
#   PROYECTO=plataforma-biblioteca/app
#   GITLAB_TOKEN=<token personal con scope api>
#   GITLAB_ADMIN_TOKEN=<opcional; si falta se usa GITLAB_TOKEN>
#
# Formato de checks.json: docs/autograding.md
# Solo lectura: este script nunca modifica nada.

set -u
cd "$(dirname "$0")/.." || exit 1

CONFIG="$HOME/.bc-gitlab"
[ -f "$CONFIG" ] && . "$CONFIG"

GITLAB_URL="${GITLAB_URL:-}"
PROYECTO="${PROYECTO:-}"
GITLAB_TOKEN="${GITLAB_TOKEN:-}"
GITLAB_ADMIN_TOKEN="${GITLAB_ADMIN_TOKEN:-$GITLAB_TOKEN}"

ok()   { printf '\033[32m✅\033[0m %s\n' "$1"; }
bad()  { printf '\033[31m❌\033[0m %s\n' "$1"; }
warn() { printf '\033[33m⚠️\033[0m  %s\n' "$1"; }

# Llama a la API v4. $1 = token, $2 = endpoint relativo.
api() {
  curl -sS --max-time 20 -H "PRIVATE-TOKEN: $1" "$GITLAB_URL/api/v4/$2" 2>/dev/null
}

# ---------------------------------------------------------------- doctor ----
doctor() {
  local fail=0
  echo "== Diagnóstico del entorno =="

  for tool in git curl jq docker; do
    if command -v "$tool" > /dev/null 2>&1; then
      ok "$($tool --version 2>&1 | head -1)"
    else
      bad "$tool no está instalado"
      fail=1
    fi
  done

  # glab no lo usa este script, pero sí las prácticas.
  if command -v glab > /dev/null 2>&1; then
    ok "$(glab --version 2>&1 | head -1)"
  else
    warn "glab no está instalado — las prácticas lo usan (ver docs/setup-entorno.md)"
  fi

  if [ -z "$GITLAB_URL" ]; then
    bad "GITLAB_URL sin definir — crea $CONFIG (ver docs/setup-entorno.md)"
    fail=1
  else
    local version
    version=$(curl -sS --max-time 10 "$GITLAB_URL/api/v4/version" \
                -H "PRIVATE-TOKEN: $GITLAB_TOKEN" 2>/dev/null | jq -r '.version // empty')
    if [ -n "$version" ]; then
      ok "instancia viva en $GITLAB_URL (GitLab $version)"
    else
      bad "no responde $GITLAB_URL/api/v4/version — ¿está levantada? docker compose ps"
      fail=1
    fi
  fi

  if [ -z "$GITLAB_TOKEN" ]; then
    bad "GITLAB_TOKEN sin definir — necesita scope 'api'"
    fail=1
  else
    local login
    login=$(api "$GITLAB_TOKEN" "user" | jq -r '.username // empty')
    if [ -n "$login" ]; then
      ok "token válido, autenticado como $login"
    else
      bad "el token no autentica — revísalo en Preferences > Access tokens"
      fail=1
    fi
  fi

  if [ "$(git config --global commit.gpgsign 2>/dev/null)" = "true" ]; then
    ok "commit.gpgsign activo (formato: $(git config --global gpg.format 2>/dev/null || echo openpgp))"
  else
    warn "commit.gpgsign no está activo — ver docs/setup-entorno.md, sección 5"
  fi

  if [ -n "$PROYECTO" ]; then
    ok "proyecto guardado: $PROYECTO"
  else
    warn "sin proyecto guardado — añade PROYECTO=<grupo>/<proyecto> a $CONFIG"
  fi

  echo
  if [ "$fail" -eq 0 ]; then
    echo "Entorno listo."
  else
    echo "Corrige lo marcado antes de empezar."
  fi
  exit "$fail"
}

# ------------------------------------------------------------ argumentos ----
[ $# -eq 0 ] && { echo "Uso: $0 <NN> [--proyecto <grupo>/<proyecto>] | --doctor"; exit 2; }
[ "$1" = "--doctor" ] && doctor

WEEK="$1"; shift
while [ $# -gt 0 ]; do
  case "$1" in
    --proyecto) PROYECTO="${2:-}"; shift 2 ;;
    *) echo "Argumento desconocido: $1"; exit 2 ;;
  esac
done

if [ -z "$GITLAB_URL" ] || [ -z "$GITLAB_TOKEN" ]; then
  echo "Falta GITLAB_URL o GITLAB_TOKEN. Crea $CONFIG — ver docs/setup-entorno.md"
  exit 2
fi

if [ -z "$PROYECTO" ]; then
  echo "Falta el proyecto. Usa --proyecto <grupo>/<proyecto> o añade PROYECTO= a $CONFIG"
  exit 2
fi

GRUPO="${PROYECTO%%/*}"
NOMBRE="${PROYECTO##*/}"
# La API v4 acepta el path completo URL-encoded como ID de proyecto.
PROYECTO_ENC="${PROYECTO//\//%2F}"

CHECKS=$(find bootcamp -path "*week-${WEEK}-*/checks.json" | head -1)
if [ -z "$CHECKS" ]; then
  echo "No existe checks.json para la semana $WEEK"
  exit 2
fi

# ------------------------------------------------------------ ejecución ----
echo "== Semana $(jq -r .semana "$CHECKS") — $(jq -r .titulo "$CHECKS") =="
echo "   instancia: $GITLAB_URL"
echo "   proyecto:  $PROYECTO"
echo

total=0
passed=0

while IFS= read -r check; do
  total=$((total + 1))
  desc=$(printf '%s' "$check" | jq -r .descripcion)
  expr=$(printf '%s' "$check" | jq -r .jq)
  pista=$(printf '%s' "$check" | jq -r '.pista // ""')
  endpoint=$(printf '%s' "$check" | jq -r '.api // ""')
  query=$(printf '%s' "$check" | jq -r '.graphql // ""')
  ambito=$(printf '%s' "$check" | jq -r '.token // "proyecto"')

  if [ "$ambito" = "admin" ]; then
    TOKEN="$GITLAB_ADMIN_TOKEN"
  else
    TOKEN="$GITLAB_TOKEN"
  fi

  if [ -n "$endpoint" ]; then
    endpoint="${endpoint//\{proyecto\}/$PROYECTO_ENC}"
    endpoint="${endpoint//\{grupo\}/$GRUPO}"
    endpoint="${endpoint//\{nombre\}/$NOMBRE}"
    result=$(api "$TOKEN" "$endpoint" | jq -r "$expr" 2>/dev/null)
  elif [ -n "$query" ]; then
    body=$(jq -nc --arg q "$query" --arg fullPath "$PROYECTO" --arg grupo "$GRUPO" \
             '{query: $q, variables: {fullPath: $fullPath, grupo: $grupo}}')
    result=$(curl -sS --max-time 20 -X POST "$GITLAB_URL/api/graphql" \
               -H "PRIVATE-TOKEN: $TOKEN" -H "Content-Type: application/json" \
               -d "$body" 2>/dev/null | jq -r "$expr" 2>/dev/null)
  else
    bad "$desc"
    echo "   (check mal formado: falta 'api' o 'graphql')"
    continue
  fi

  if [ "$result" = "true" ]; then
    ok "$desc"
    passed=$((passed + 1))
  else
    bad "$desc"
    [ -n "$pista" ] && echo "   → $pista"
  fi
done < <(jq -c '.checks[]' "$CHECKS")

echo
echo "$passed de $total verificaciones superadas."
[ "$passed" -eq "$total" ] || exit 1
