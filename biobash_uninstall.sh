#!/usr/bin/env bash

# =========================================
# BIOBASH UNINSTALLER
# Removes BioBASH and environment variables
# =========================================

INSTALLER_NAME="BioBASH Uninstaller"

function print_header() {
    echo -e "\033[1;31m$INSTALLER_NAME\033[0m"
    echo "Running on $(uname -s) ($(uname -m))"
    echo
}

function detect_profiles() {
    local profiles=()
    [[ -f "$HOME/.bashrc" ]] && profiles+=("$HOME/.bashrc")
    [[ -f "$HOME/.bash_profile" ]] && profiles+=("$HOME/.bash_profile")
    [[ -f "$HOME/.zshrc" ]] && profiles+=("$HOME/.zshrc")
    [[ -f "$HOME/.profile" ]] && profiles+=("$HOME/.profile")
    
    # Return unique items
    echo "${profiles[@]}" | tr ' ' '\n' | sort -u
}

function remove_profile_entries() {
    local profiles
    read -a profiles <<< "$(detect_profiles)"

    for profile_file in "${profiles[@]}"; do
        if grep -q "BioBASH" "$profile_file" 2>/dev/null; then
            echo "[INFO] Removing BioBASH environment entries from $profile_file"
            cp "$profile_file" "${profile_file}.bak"

            local temp_file
            temp_file=$(mktemp)
            
            # Remove any line between # BioBASH and export PATH, etc.
            # Using grep -v with a pattern matches the exact lines our installer added
            grep -v "# BioBASH integration" "$profile_file" | 
            grep -v "# BioBASH PATH integration" | 
            grep -v "source \$BIOBASH_HOME/load_biobash.sh" | 
            grep -v 'export BIOBASH_HOME=' | 
            grep -v 'export PATH="\$BIOBASH_HOME:\$PATH"' |
            grep -v 'export PATH="\$PATH:\$BIOBASH_HOME"' > "$temp_file"
            
            mv "$temp_file" "$profile_file"
            echo "[INFO] Cleaned up $profile_file"
        fi
    done
}

function get_installed_location() {
    local location=""
    if [[ -n "$BIOBASH_HOME" ]]; then
        location="$BIOBASH_HOME"
    else
        # Try to find it if BIOBASH_HOME is not set but they run uninstaller
        # Assume it's in the same directory as the uninstaller script
        location="$(dirname "$(realpath "$0")")"
    fi
    echo "$location"
}

function remove_installation() {
    local target_dir
    target_dir=$(get_installed_location)

    if [[ ! -d "$target_dir" ]]; then
        echo "[ERROR] Directory $target_dir does not exist or has already been removed."
        exit 1
    fi

    echo "[INFO] BioBASH installation detected in: $target_dir"
    read -p "Are you sure you want to permanently delete this BIOBASH installation directory? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -rf "$target_dir"
        echo "[INFO] Deleted BioBASH directory: $target_dir"
        echo -e "\n\033[1;32mBioBASH was successfully uninstalled.\033[0m"
        echo "Please restart your terminal to fully clear any loaded paths."
    else
        echo "[INFO] Aborted. BioBASH directory was not removed."
    fi
}

# ---------------------- MAIN -------------------------------

print_header
remove_profile_entries
remove_installation
echo ""

