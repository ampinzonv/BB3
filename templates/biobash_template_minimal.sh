#!/usr/bin/env bash

# =====================================
# BIOBASH MINIMAL TEMPLATE (v2)
# For STDIN/STDOUT-based filter scripts
# =====================================

# Load core functions
. ./biobash_core.sh

# Help message
show_help() {
    cat << EOF
Usage: $(basename "$0") --input FILE [OPTIONS]

Required:
  --input FILE         Input file or '-' for STDIN

Optional:
  --quiet              Suppress informational messages
  --force              Allow overwriting if applicable
  --processors N       Number of processors to use (default: 1)
  --help               Show this help message
EOF
}

# === Show help if no arguments ===
if [[ $# -eq 0 ]]; then
    show_help
    exit 0
fi

# === Parse arguments ===
parse_args "$@"

# === Detect OS ===
detect_os
if [[ "$OS_TYPE" == "unsupported" ]]; then
    error "Unsupported operating system"
    exit 1
fi

# === Validate input ===
if [[ -z "$INPUT" ]]; then
    error "Missing required --input argument"
    exit 1
fi

check_input "$INPUT"

# === Determine input stream ===
if is_stdin "$INPUT"; then
    infile="/dev/stdin"
else
    infile="$INPUT"
fi

# === Feedback ===
info "Running $(basename "$0")"
info "Input: $INPUT"
info "Processors: $PROCESSORS"
info "Quiet mode: $QUIET"

# === Main logic ===
# Replace this block with your tool
awk '{ print $0 }' "$infile"

info "Done."

