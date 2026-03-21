#!/usr/bin/env bash

# ---------------------- CONFIGURATION ----------------------

# We now include the "biobash" dispatcher script
BIOBASH_FILES=("biobash" "biobash_core.sh" "blast.sh" "file.sh" "plot_ascii.sh" "utility.sh" "test_biobash_core.sh" "biobash_uninstall.sh")
INSTALLER_NAME="BioBASH Installer"

# ---------------------- FUNCTIONS --------------------------

function print_header() {
    echo -e "\033[1;34m$INSTALLER_NAME\033[0m"
    echo "Running on $(uname -s) ($(uname -m))"
    echo
}

function check_shell() {
    if [ -z "$BASH_VERSION" ]; then
        echo "BioBASH installer requires BASH to run."
        echo "Please use: bash biobash_install.sh"
        exit 1
    fi
}

function check_dependencies() {
    local deps=("awk" "sed" "grep")
    # Removed blastn and zcat as strict requirements for installation,
    # as they might be installed later, but we can keep checking them to warn.
    local recommended=("blastn" "zcat")
    
    echo "Checking core dependencies..."
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: Required core command '$cmd' not found."
            exit 1
        else
            echo -e "Checking $cmd \033[1;32mOK\033[0m"
        fi
    done
    
    echo "Checking optional dependencies..."
    for cmd in "${recommended[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo -e "Checking $cmd \033[1;33mMISSING (Recommended)\033[0m"
        else
            echo -e "Checking $cmd \033[1;32mOK\033[0m"
        fi
    done
    echo "Core dependencies are satisfied."
}

function read_version() {
    if [[ -f version ]]; then
        BIOBASH_VERSION=$(cat version)
    else
        echo "Error: version file not found."
        exit 1
    fi
}

function confirm_install() {
    echo -e "BioBASH version: \033[1;32m$BIOBASH_VERSION\033[0m"
    read -p "Do you want to proceed with the installation? [y/N] " reply
    [[ "$reply" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
}

function get_install_dir() {
    local default_prefix="$HOME/.biobash"
    echo "Where do you want to install BioBASH?"
    echo "  (Press ENTER to use the default path: $default_prefix)"
    read -p "Path: " user_prefix
    
    BIOBASH_HOME="${user_prefix:-$default_prefix}"
    # Expanding ~ if the user typed it
    BIOBASH_HOME="${BIOBASH_HOME/#\~/$HOME}"
    export BIOBASH_HOME
}

function check_permissions() {
    if [[ ! -d "$BIOBASH_HOME" ]]; then
        mkdir -p "$BIOBASH_HOME" || {
            echo "Error: Failed to create $BIOBASH_HOME"
            echo "Tip: Try a location where you have write permissions (e.g., $HOME/.biobash)"
            exit 1
        }
    fi
    
    if [[ ! -w "$BIOBASH_HOME" ]]; then
        echo "Error: You do not have write permissions for $BIOBASH_HOME."
        exit 1
    fi
}

function install_files() {
    echo "Installing files to $BIOBASH_HOME..."
    for file in "${BIOBASH_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            cp "$file" "$BIOBASH_HOME/" || {
                echo "Error copying $file"
                exit 1
            }
        else
            echo "Warning: File $file not found in current directory. Skipping."
        fi
    done
    
    # Ensure the dispatcher is executable
    if [[ -f "$BIOBASH_HOME/biobash" ]]; then
        chmod +x "$BIOBASH_HOME/biobash"
    fi
    # Also ensure the uninstaller is executable
    if [[ -f "$BIOBASH_HOME/biobash_uninstall.sh" ]]; then
        chmod +x "$BIOBASH_HOME/biobash_uninstall.sh"
    fi
    
    echo "Files successfully installed."
}

function detect_user_profile() {
    local profile=""
    local user_shell=$(basename "$SHELL")
    
    if [[ "$user_shell" == "zsh" ]]; then
        profile="$HOME/.zshrc"
    elif [[ "$user_shell" == "bash" ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS bash users typically use .bash_profile
            if [[ -f "$HOME/.bash_profile" ]]; then
                profile="$HOME/.bash_profile"
            else
                profile="$HOME/.bashrc"
            fi
        else
            profile="$HOME/.bashrc"
        fi
    else
        # Fallback
        profile="$HOME/.profile"
    fi
    
    echo "$profile"
}

function update_profile_path() {
    local profile_file
    profile_file=$(detect_user_profile)

    if [[ ! -f "$profile_file" ]]; then
        touch "$profile_file"
    else
        cp "$profile_file" "${profile_file}.bak"
    fi

    # Add BioBASH to PATH if not already there
    if ! grep -q "export PATH=.*\$BIOBASH_HOME" "$profile_file" && ! grep -q "export PATH=.*${BIOBASH_HOME}" "$profile_file"; then
        {
            echo ""
            echo "# BioBASH PATH integration"
            echo "export BIOBASH_HOME=\"$BIOBASH_HOME\""
            echo "export PATH=\"\$BIOBASH_HOME:\$PATH\""
        } >> "$profile_file"
        echo "Updated $profile_file to include BioBASH in your PATH."
    else
        echo "BioBASH is already in your PATH in $profile_file."
    fi
}

# ---------------------- MAIN -------------------------------

print_header

echo "STEP 1. Checking environment..."
check_shell
check_dependencies
read_version

echo ""
echo "STEP 2. Confirming installation"
confirm_install
get_install_dir
check_permissions

echo ""
echo "STEP 3. Installing BioBASH files"
install_files

echo ""
echo "STEP 4. Updating shell configuration"
update_profile_path

profile_file=$(detect_user_profile)

echo ""
echo -e "\n\033[1;32mBioBASH installed successfully!\033[0m"
echo "You can now use the 'biobash' command directly from any terminal."
echo "Please RESTART your terminal or run this command to update your current session:"
echo "  source ${profile_file}"
echo ""