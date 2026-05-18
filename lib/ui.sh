#!/bin/bash
set -euo pipefail

# =============================================================================
# GenPy — lib/ui.sh
#
# Funciones para la interacción con el usuario en la terminal.
# Centralizar los prompts aquí facilita cambiar el idioma o el estilo
# de la interfaz en el futuro sin tocar la lógica de negocio.
# =============================================================================

# -----------------------------------------------------------------------------
# ask_yes_no
#
# Muestra una pregunta de sí/no y espera una respuesta válida.
# Repite la pregunta si el usuario escribe algo que no sea "s" o "n".
#
# Retorna:
#   0 (true)  si el usuario responde "s" o "S"
#   1 (false) si el usuario responde "n" o "N"
#
# Argumentos:
#   $1 — texto de la pregunta a mostrar
#
# Ejemplo:
#   ask_yes_no "¿Usar Docker?" && USE_DOCKER=true || USE_DOCKER=false
# -----------------------------------------------------------------------------
ask_yes_no() {
  local question="$1"

  while true; do
    read -rp "$question (s/n): " user_answer

    case "$user_answer" in
      s|S) return 0 ;;  # sí
      n|N) return 1 ;;  # no
      *)
        echo "  ⚠️  Responde s (sí) o n (no)"
        ;;
    esac
  done
}

