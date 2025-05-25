#!/usr/bin/env bash

# Ensure biobash_core.sh is loaded (only once)
if ! declare -f parse_args >/dev/null; then
    . ../biobash_core.sh
fi

bb_get_list() {
    if [[ $# -eq 0 ]]; then
        echo "bb_get_list"
        echo "Processes a list of items (one per line) and returns:"
        echo "- a sorted non-redundant list (default)"
        echo "- or item frequency and percentage with --frequency"
        echo ""
        echo "Usage:"
        echo "  bb_get_list --input FILE [--outfile FILE] [--frequency] [--quiet] [--force]"
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




