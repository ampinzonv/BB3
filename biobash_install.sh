#!/usr/bin/env bash

# ---------------------- CONFIGURATION ----------------------

BIOBASH_FILES=("biobash_core.sh" "blast.sh" "file.sh" "load_biobash.sh" "plot_ascii.sh" "test_biobash_core.sh" "utility.sh" "biobash_uninstall.sh")
INSTALLER_NAME="BioBASH Installer"

# ---------------------- FUNCTIONS --------------------------

function print_header() {
    echo -e "\033[1;34m$INSTALLER_NAME\033[0m"
    echo "Running on $(uname -s) ($(uname -m))"
    echo
}

function check_shell() {
    if [ -z "$BASH_VERSION" ]; then
        echo "BioBASH requires BASH. You're not running this script with bash."
        echo "Please use: bash install_biobash.sh"
        exit 1
    fi
}

function check_dependencies() {
    local deps=("blastn" "zcat" "awk" "sed" "grep")
    echo "Checking required dependencies..."
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: Required command '$cmd' not found. Please install it before proceeding."
            exit 1
        else
            echo "Checking $cmd "
            sleep 0.5
            echo -e "\033[1;32mOK\033[0m"
        
        fi
    done
    echo "All dependencies are satisfied."
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
    [[ "$reply" =~ ^[Yy]$ ]] || exit 0
}

function get_install_dir() {
    default_prefix="/usr/local/bin"
    read -p "Enter installation directory prefix [default: $default_prefix]: " user_prefix
    install_prefix="${user_prefix:-$default_prefix}"
    BIOBASH_HOME="$install_prefix/biobash-$BIOBASH_VERSION"
    export BIOBASH_HOME
}


function check_permissions() {
    if [[ -d "$BIOBASH_HOME" && ! -w "$BIOBASH_HOME" ]]; then
        echo "Error: You do not have write permissions for $BIOBASH_HOME."
        exit 1
    fi

    if [[ ! -d "$BIOBASH_HOME" ]]; then
        mkdir -p "$BIOBASH_HOME" || {
            echo "Error: Failed to create $BIOBASH_HOME"
            exit 1
        }
    fi
}

function install_files() {
    echo "Installing files to $BIOBASH_HOME..."
    for file in "${BIOBASH_FILES[@]}"; do
        cp "$file" "$BIOBASH_HOME/" || {
            echo "Error copying $file"
            exit 1
        }
    done
    echo "Files successfully installed."
}

function update_bashrc() {
    local bash_file

    if [[ "$OSTYPE" == "darwin"* ]]; then
        bash_file="$HOME/.bash_profile"
    else
        bash_file="$HOME/.bashrc"
    fi

    if [[ -f "$bash_file" ]]; then
        cp "$bash_file" "${bash_file}.bak"
    else
        touch "$bash_file"
    fi

    # Once here means that we are working with a correct bash file
    if ! grep -q "source \$BIOBASH_HOME/load_biobash.sh" "$bash_file"; then
        {
            echo ""
            echo "# BioBASH integration"
            echo "export BIOBASH_HOME=\"$BIOBASH_HOME\""
            echo "source \$BIOBASH_HOME/load_biobash.sh"
        } >> "$bash_file"
    fi

    echo "Updated $bash_file to load BioBASH at startup."
}

# ---------------------- MAIN -------------------------------

print_header

echo ""
echo "STEP 1. Checking environment..."

check_shell
check_dependencies
read_version
sleep 0.5

echo""
echo "STEP 2. Confirming installation and installation directory"

confirm_install
get_install_dir
check_permissions
sleep 0.4

echo ""
echo "STEP 3. Installing BioBASH files"
install_files
sleep 0.4

echo""
echo "STEP 4. Updating bash configuration file"
update_bashrc
sleep 0.4



if [[ "$OSTYPE" == "darwin"* ]]; then
        bash_file="$HOME/.bash_profile"
else
        bash_file="$HOME/.bashrc"
fi

echo ""
echo -e "\n\033[1;32mBioBASH installed successfully!\033[0m Please RESTART your terminal or run:"
echo "source ${bash_file}" 
echo""