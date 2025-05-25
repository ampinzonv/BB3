#!/usr/bin/env bash

# ============================================
# BIOBASH TEMPLATE SCRIPT (v2)
# For output-producing bioinformatics tools
# ============================================

# Load core functions
. ./biobash_core.sh

# === Help ===
show_help() {
    cat << EOF
Usage: $(basename "$0") --input FILE [OPTIONS]

Required:
  --input FILE         Input file or '-' for STDIN

Optional:
  --outfile FILE       Output file (default: STDOUT or auto-named)
  --outdir DIR         Output directory for results
  --jobname NAME       Custom basename for output files
  --processors N       Number of processors to use (default: 1)
  --force              Allow overwriting output files
  --quiet              Suppress informational messages
  --help               Show this help message
EOF
}

# === Show help if called with no arguments ===
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

# === Determine input basename ===
if is_stdin "$INPUT"; then
    BASENAME="STDIN"
else
    BASENAME=$(get_basename "$INPUT")
fi

# === Determine outfile if not provided ===
if [[ -z "$OUTFILE" ]]; then
    OUTFILE=$(auto_outname "$INPUT" "out")
fi

# === Create outdir if needed ===
if [[ -n "$OUTDIR" ]]; then
    create_outdir "$OUTDIR"
    OUTFILE="$OUTDIR/$(basename "$OUTFILE")"
fi

# === Check if outfile already exists ===
check_file_exists "$OUTFILE"

# === Report ===
info "Running $(basename "$0")"
info "Input: $INPUT"
info "Output: $OUTFILE"
info "Processors: $PROCESSORS"
info "Quiet mode: $QUIET"

# === Main logic ===
# Replace this with your tool-specific logic
cat "$INPUT" > "$OUTFILE"

info "Done."
