#!/usr/bin/env bash

# =========================================
# BIOBASH UNINSTALLER
# Removes BioBASH and environment variables
# =========================================

INSTALLER_NAME="BioBASH Uninstaller"
BIOBASH_PATTERN="source \$BIOBASH_HOME/load_biobash.sh"

function print_header() {
    echo -e "\033[1;31m$INSTALLER_NAME\033[0m"
    echo "Running on $(uname -s) ($(uname -m))"
    echo
}

function detect_bash_file() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "$HOME/.bash_profile"
    else
        echo "$HOME/.bashrc"
    fi
}

function remove_bashrc_entry() {
    local bash_file
    bash_file=$(detect_bash_file)

    if [[ ! -f "$bash_file" ]]; then
        echo "[WARN] No bash configuration file found."
        return
    fi

    echo "[INFO] Removing BioBASH environment entries from $bash_file"
    cp "$bash_file" "${bash_file}.bak"

    # Crear archivo temporal para hacer el trabajo
    local temp_file
    temp_file=$(mktemp)
    
    # Filtrar las líneas que queremos eliminar
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - usamos grep inverso para eliminar líneas
        grep -v "# BioBASH integration" "$bash_file" | 
        grep -v "source \$BIOBASH_HOME/load_biobash.sh" | 
        grep -v "export BIOBASH_HOME=" > "$temp_file"
    else
        # Linux - podemos usar sed normalmente
        sed '/# BioBASH integration/d' "$bash_file" |
        sed '/source \$BIOBASH_HOME\/load_biobash.sh/d' |
        sed '/export BIOBASH_HOME=/d' > "$temp_file"
    fi
    
    # Reemplazar el archivo original con el filtrado
    mv "$temp_file" "$bash_file"
    
    echo "[INFO] BioBASH environment variables removed from $bash_file"
}

function remove_installation() {
    if [[ -z "$BIOBASH_HOME" ]]; then
        echo "[ERROR] BIOBASH_HOME environment variable is not set. Cannot determine installation path."
        exit 1
    fi

    if [[ ! -d "$BIOBASH_HOME" ]]; then
        echo "[ERROR] Directory $BIOBASH_HOME does not exist."
        exit 1
    fi

    echo "[INFO] BioBASH is installed in: $BIOBASH_HOME"
    read -p "Are you sure you want to permanently delete BIOBASHH installation directory? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -rf "$BIOBASH_HOME"
        echo "[INFO] Deleted BioBASH directory: $BIOBASH_HOME"
        echo -e "\n\033[1;32mBioBASH was successfully uninstalled.\033[0m Please restart your terminal or run:"
    echo "source ~/.bashrc   # or ~/.bash_profile on macOS"
  
    else
        echo "[INFO] Aborted. BioBASH directory was not removed."
    fi
}

# ---------------------- MAIN -------------------------------

print_header
remove_bashrc_entry
remove_installation
  echo ""
    echo ""


