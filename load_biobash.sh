
#!/usr/bin/env bash

# Script para cargar los archivos principales de BioBASH
# Autor: Andrés Pinzón
# Fecha: 28 de mayo de 2025

# Definir la ubicación base de BioBASH (asumiendo que estamos en el directorio BB3)
BIOBASH_HOME="$(pwd)"

# Función para verificar la existencia de archivos
check_files() {
    local missing=0
    for file in "$@"; do
        if [[ ! -f "$file" ]]; then
            echo -e "\033[0;31m[ERROR]\033[0m File not found: $file"
            missing=1
        fi
    done
    
    if [[ $missing -eq 1 ]]; then
        echo "Please run this script from the BioBASH main directory."
        exit 1
    fi
}

# Verificar que los archivos existan
check_files "$BIOBASH_HOME/biobash_core.sh" \
            "$BIOBASH_HOME/file.sh" \
            "$BIOBASH_HOME/blast.sh" \
            "$BIOBASH_HOME/plot_ascii.sh" \
            "$BIOBASH_HOME/utility.sh"

# Cargar los archivos en el orden correcto
# Comenzando con biobash_core.sh que contiene funciones fundamentales
echo "Loading BioBASH components..."

# biobash_core.sh debe cargarse primero ya que contiene funciones básicas
echo " - Loading core functions (biobash_core.sh)"
source "$BIOBASH_HOME/biobash_core.sh"

# Cargar los módulos principales
echo " - Loading file utilities (file.sh)"
source "$BIOBASH_HOME/file.sh"

echo " - Loading BLAST functions (blast.sh)"
source "$BIOBASH_HOME/blast.sh"

echo " - Loading plotting functions (plot_ascii.sh)"
source "$BIOBASH_HOME/plot_ascii.sh"

echo " - Loading utility functions (utility.sh)"
source "$BIOBASH_HOME/utility.sh"

# Mostrar información de BioBASH cargado
echo -e "\033[0;32m[SUCCESS]\033[0m BioBASH environment loaded successfully!"
echo "BioBASH components are now available in your current shell."
echo "Available modules:"
echo " - Core functions"
echo " - File utilities"
echo " - BLAST tools"
echo " - ASCII plotting tools"
echo " - General utilities"
echo ""
echo "Run any BioBASH function with '--help' for usage information."