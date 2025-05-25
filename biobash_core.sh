#!/usr/bin/env bash

# === BIOBASH CORE LIBRARY ===
# Internal utility functions for all BIOBASH scripts
# These functions are not prefixed with "bb_" to keep user-facing namespace clean

#############################################
# Detect the operating system
# Exports a global variable: OS_TYPE
# Possible values: linux, macos, unsupported
#############################################
detect_os() {
    local uname_out
    uname_out=$(uname -s)
    case "${uname_out}" in
        Linux*)   OS_TYPE="linux" ;;
        Darwin*)  OS_TYPE="macos" ;;
        *)        OS_TYPE="unsupported" ;;
    esac
    export OS_TYPE
}

#############################################
# Print an error message
# Honors the global QUIET variable
# Usage: error "Your message"
#############################################
error() {
    [[ "$QUIET" == "true" ]] && return
    echo -e "[ERROR] $*" >&2
}

#############################################
# Print an info message
# Usage: info "Your message"
#############################################
info() {
    [[ "$QUIET" == "true" ]] && return
    echo -e "[INFO]  $*" >&2
}

#############################################
# Print a warning message
# Usage: warn "Your message"
#############################################
warn() {
    [[ "$QUIET" == "true" ]] && return
    echo -e "[WARN]  $*" >&2
}

#############################################
# Check if a file already exists
# Usage: check_file_exists <file_path>
# Honors global FORCE variable: if not true, abort if file exists
#############################################
check_file_exists() {
    local file="$1"
    if [[ -e "$file" && "$FORCE" != "true" ]]; then
        error "File '$file' already exists. Use --force to overwrite."
        return 1
    fi
}

#############################################
# Check if input file is valid
# Allows "-" to indicate STDIN
# Aborts if file does not exist
# Usage: check_input <file_path>
#############################################
check_input() {
    local file="$1"
    if [[ "$file" == "-" ]]; then
        return 0  # STDIN is valid
    elif [[ -r "$file" ]]; then
        return 0  # File exists and is readable
    else
        error "Input file '$file' not found or not readable."
        return 1
    fi
}

#############################################
# Generate automatic output file name
# Usage: auto_outname <input_file> <extension>
# Example: auto_outname "reads.fasta" "png" -> "reads.png"
#          auto_outname "-" "png"           -> "STDIN.png"
#############################################
auto_outname() {
    local input="$1"
    local ext="$2"
    local base

    if [[ "$input" == "-" ]]; then
        base="STDIN"
    else
        base=$(basename "$input")
        base="${base%.*}"  # remove extension
    fi

    echo "${base}.${ext}"
}

#############################################
# Create output directory if it doesn't exist
# Usage: create_outdir <dir_path>
# Respects QUIET variable for messaging
#############################################
create_outdir() {
    local outdir="$1"
    if [[ -z "$outdir" ]]; then
        outdir="."  # default to current directory
    fi

    # Check if path exists as a file
    if [[ -e "$outdir" && ! -d "$outdir" ]]; then
        error "'$outdir' exists and is not a directory."
        return 1
    fi

    if [[ ! -d "$outdir" ]]; then
        if mkdir -p "$outdir" 2>/dev/null; then
            [[ "$QUIET" != "true" ]] && echo "[INFO]  Created output directory: $outdir"
            return 0
        else
            error "Could not create output directory: $outdir. Check if a directoy or file already exist with the same name"
            return 1
        fi
    fi

    return 0
}


#############################################
# Get base name without path or extension
# Usage: get_basename <input_file>
# Example: /path/to/reads.fasta -> reads
#############################################
get_basename() {
    local input="$1"
    local base

    base=$(basename "$input")
    echo "${base%.*}"
}


#############################################
# Check if input is from STDIN
# Usage: is_stdin <input_arg>
# Returns 0 if input is "-", 1 otherwise
#############################################
is_stdin() {
    local input="$1"
    [[ "$input" == "-" ]]
}

show_help() {
    echo "Help message placeholder"
}

#############################################
# Check that required commands are available
# Usage: check_dependencies cmd1 cmd2 ...
# If any is missing, show error and exit
#############################################
check_dependencies() {
    local missing=()
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required dependencies: ${missing[*]}"
        return 1
    fi
}


#############################################
# Parse standard BIOBASH arguments
# Usage: parse_args "$@"
# Sets global variables:
#   INPUT, OUTFILE, OUTDIR, JOBNAME, FORCE, QUIET
#############################################
parse_args() {
    # Reset globals in case they're reused
    INPUT=""
    OUTFILE=""
    OUTDIR=""
    JOBNAME=""
    PROCESSORS=1
    FORCE="false"
    QUIET="false"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --input)
                INPUT="$2"; shift 2 ;;
            --outfile)
                OUTFILE="$2"; shift 2 ;;
            --outdir)
                OUTDIR="$2"; shift 2 ;;
            --jobname)
                JOBNAME="$2"; shift 2 ;;
            --processors)
                PROCESSORS="$2"
                # Validate that it's a positive integer
                if ! [[ "$PROCESSORS" =~ ^[0-9]+$ ]] || [[ "$PROCESSORS" -lt 1 ]]; then
                    error "Invalid value for --processors: $PROCESSORS"
                    return 1
                fi
                shift 2 ;;
            --force)
                FORCE="true"; shift ;;
            --quiet)
                QUIET="true"; shift ;;
            --help)
                show_help; return 0 ;;
            *)
                error "Unknown argument: $1"; return 1 ;;
        esac
    done
}


