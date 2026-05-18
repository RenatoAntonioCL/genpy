#!/bin/bash
set -euo pipefail

# =============================================================================
# GenPy — lib/validate.sh
#
# Funciones de validación de entrada del usuario.
# =============================================================================

# -----------------------------------------------------------------------------
# is_valid_name
#
# Verifica que el nombre de un proyecto sea seguro para usar como:
#   - nombre de carpeta en el sistema de archivos
#   - nombre de repositorio en GitHub
#   - nombre de imagen en Docker
#
# Caracteres permitidos: letras (a-z, A-Z), números (0-9), guion (-), guion bajo (_)
# Caracteres prohibidos: espacios, barras, puntos, y cualquier carácter especial
#
# Retorna:
#   0 (true)  si el nombre es válido
#   1 (false) si contiene caracteres no permitidos
#
# Argumentos:
#   $1 — nombre a validar
# -----------------------------------------------------------------------------
is_valid_name() {
  local name="$1"

  # El operador =~ compara contra una expresión regular extendida.
  # ^ y $ aseguran que toda la cadena cumpla la regla, no solo parte de ella.
  [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]
}

