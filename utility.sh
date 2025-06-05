#!/usr/bin/env bash

# Ensure biobash_core.sh is loaded (only once)
if ! declare -f parse_args >/dev/null; then
    . ./biobash_core.sh
fi

bb_get_list() {
    if [[ $# -eq 0 ]]; then
        echo "bb_get_list"
        echo "Processes a list of items (one per line) and returns:"
        echo ""
        echo "Usage:"
        echo "  bb_get_list --input FILE [--outfile FILE] [--frequency] [--quiet] [--force]"
        echo ""
        echo "Options:"
        echo "  --input FILE      Input FASTA file or '-' for STDIN (required)"
        echo "  --outfile FILE    Output file (optional; default: STDOUT)"
        echo "  --quiet           Suppress log messages"
        echo "  --force           Overwrite output file if it exists"
        
        return 0
    fi

    if ! declare -f parse_args >/dev/null; then
        . ./biobash_core.sh
    fi

    local FREQUENCY=false
    local args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --frequency) FREQUENCY=true; shift ;;
            *) args+=("$1"); shift ;;
        esac
    done

    parse_args "${args[@]}"

    if [[ -z "$INPUT" ]]; then
        error "Missing required --input argument"
        return 1
    fi

    check_input "$INPUT"

    local stdin_tmp=""
    if is_stdin "$INPUT"; then
        stdin_tmp=$(mktemp)
        cat - > "$stdin_tmp"
        INPUT="$stdin_tmp"
    fi

    local output_stream="/dev/stdout"
    if [[ -n "$OUTFILE" ]]; then
        if ! check_file_exists "$OUTFILE"; then
            [[ -n "$stdin_tmp" ]] && rm -f "$stdin_tmp"
            return 1
        fi
        mkdir -p "$(dirname "$OUTFILE")" 2>/dev/null || {
            error "Cannot create directory for output: $(dirname "$OUTFILE")"
            [[ -n "$stdin_tmp" ]] && rm -f "$stdin_tmp"
            return 1
        }
        output_stream="$OUTFILE"
    fi

    info "bb_get_list processing input: $INPUT"
    info "Output: ${OUTFILE:-stdout}"

    if [[ "$FREQUENCY" == true ]]; then
        awk 'NF' "$INPUT" |
        awk '
            { count[$0]++; total++ }
            END {
                for (item in count) {
                    freq = count[item];
                    pct = (freq / total) * 100;
                    printf "%s\t%d\t%.0f\n", item, freq, pct;
                }
            }
        ' | LC_ALL=C sort > "$output_stream"
    else
        awk 'NF' "$INPUT" | sort | uniq | LC_ALL=C sort > "$output_stream"
    fi

    info "bb_get_list finished. Output: ${OUTFILE:-stdout}"
    [[ -n "$stdin_tmp" ]] && rm -f "$stdin_tmp"
    return 0
}

bb_project_setup() {
    if [[ $# -eq 0 ]]; then
        echo "
=== bb_project_setup ===

Set up a directory structure for a bioinformatics project.

Usage:
  bb_project_setup --project_name NAME [--quiet] [--force]

Options:
  --project_name NAME   Name of the project (no spaces allowed) [required]
  --quiet               Suppress informational output
  --force               Overwrite existing project directory
"
        return 0
    fi

    local PROJECT_NAME=""
    local args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project_name) PROJECT_NAME="$2"; shift 2 ;;
            --quiet) QUIET="true"; shift ;;
            --force) FORCE="true"; shift ;;
            *) args+=("$1"); shift ;;
        esac
    done

    if [[ -z "$PROJECT_NAME" ]]; then
        error "Missing required --project_name argument"
        return 1
    fi

    local mydate actualDate rootDir
    actualDate=$(date)
    mydate=$(date +"%Y%m%d")
    rootDir="${mydate}-${PROJECT_NAME}"

    if [[ -d "$rootDir" && "$FORCE" != "true" ]]; then
        warn "Directory '$rootDir' already exists. Use --force to overwrite."
        return 1
    fi

    [[ -d "$rootDir" && "$FORCE" == "true" ]] && rm -rf "$rootDir"

    mkdir -p "$rootDir" || {
        error "Failed to create project root directory"
        return 1
    }

    cd "$rootDir" || return 1
    info "Creating project structure in $rootDir"

    # Create main files
    echo "#                      PROJECT'S NOTEBOOK

## $actualDate: Initial steps
------------------------------
Copied files from NCBI to raw data directory

## $actualDate: General quality analysis
------------------------------
Performed a simple *Fastqc analysis* over raw data. Everything was saved to Analysis folder.
The command was:
> fastqc raw_data/*fq
" > notebook.md

    echo "#                      ABOUT THIS PROJECT

* Project started on: $actualDate

## GENERAL OBJECTIVE

## COLLABORATORS

## RELATED INFO
" > about.md

    local readme_content
    readme_content="# README

## $actualDate
First files copied here

## $actualDate
Other important info related to this particular folder"

    # Create directory structure
    for dir in sandbox data tmp tools docs results manuscript analysis; do
        mkdir -p "$dir"
        echo "$readme_content" > "$dir/README.${dir}.md"
    done

    mkdir -p analysis/{01,02,03,04}
    mkdir -p tools/{scripts,soft}
    mkdir -p data/{raw_data,other_data}

    info "Project directory created successfully."

    echo "
=== DONE! ===
Environment created at: $rootDir
Tip: Protect raw data with: chmod -R -w $rootDir/data/raw_data
=============="
}





