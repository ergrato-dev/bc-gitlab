#!/bin/sh
# Comando forzado de cada clave en authorized_keys:
#   command="/usr/local/bin/desplegar <patrón>",restrict ssh-ed25519 AAAA… staging
# El patrón ('staging', 'review-*') limita qué entornos puede tocar esa clave.
# Lo que pidió el cliente llega en SSH_ORIGINAL_COMMAND:
#   desplegar <slug> <sha> <entorno>   el paquete .tgz llega por la entrada estándar
#   parar <slug>
#   estado
set -eu
PATRON=${1:?falta el patrón de entornos de esta clave}
RAIZ=/srv/entornos
set -f  # sin comodines: la orden del cliente no se expande contra el disco
# shellcheck disable=SC2086
set -- ${SSH_ORIGINAL_COMMAND:-}
set +f
ORDEN=${1:-}

permitido() {
  printf '%s' "$1" | grep -qE '^[a-z0-9][a-z0-9-]{0,62}$' || return 1
  case "$1" in $PATRON) return 0 ;; *) return 1 ;; esac
}

case "$ORDEN" in
desplegar)
  SLUG=${2:?falta el slug}; SHA=${3:?falta el SHA}; ENTORNO=${4:?falta el entorno}
  permitido "$SLUG" || { echo "esta clave no despliega en '$SLUG'" >&2; exit 3; }
  printf '%s' "$SHA" | grep -qE '^[0-9a-f]{40}$' || { echo "SHA no válido" >&2; exit 2; }
  DESTINO="$RAIZ/$SLUG/versiones/$SHA"
  rm -rf "$DESTINO.tmp" && mkdir -p "$DESTINO.tmp"
  tar -xzf - -C "$DESTINO.tmp" --strip-components=1
  printf '{"entorno":"%s","sha":"%s","desplegado":"%s"}\n' \
    "$ENTORNO" "$SHA" "$(date -u +%FT%TZ)" > "$DESTINO.tmp/despliegue.json"
  rm -rf "$DESTINO" && mv "$DESTINO.tmp" "$DESTINO"
  # El cambio de versión es atómico: un enlace nuevo que sustituye al viejo con rename(2).
  ln -sfn "versiones/$SHA" "$RAIZ/$SLUG/actual.nuevo"
  mv -T "$RAIZ/$SLUG/actual.nuevo" "$RAIZ/$SLUG/actual"
  # Se conservan las cinco últimas versiones; las demás se borran.
  ls -1t "$RAIZ/$SLUG/versiones" | tail -n +6 | while read -r v; do rm -rf "$RAIZ/$SLUG/versiones/$v"; done
  echo "$SLUG -> $SHA"
  ;;
parar)
  SLUG=${2:?falta el slug}
  permitido "$SLUG" || { echo "esta clave no para '$SLUG'" >&2; exit 3; }
  rm -rf "${RAIZ:?}/$SLUG"
  echo "$SLUG parado"
  ;;
estado)
  for d in "$RAIZ"/*/; do
    [ -e "$d/actual" ] || continue
    s=$(basename "$d")
    if permitido "$s"; then cat "$d/actual/despliegue.json"; fi
  done
  ;;
*)
  echo "uso: desplegar <slug> <sha> <entorno> | parar <slug> | estado" >&2; exit 2 ;;
esac
