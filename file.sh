bb_get_fasta_header() {
    # Show help if no arguments
    if [[ $# -eq 0 ]]; then
        echo "🧬 bb_get_fasta_header"
        echo "Extract FASTA headers from a file or from STDIN."
        echo ""
        echo "Usage:"
        echo "  bb_get_fasta_header --input FILE [--outfile FILE] [--quiet] [--force]"
        echo ""
        echo "Options:"
        echo "  --input FILE      Input FASTA file or '-' for STDIN (required)"
        echo "  --outfile FILE    Output file (optional; default: STDOUT)"
        echo "  --quiet           Suppress log messages"
        echo "  --force           Overwrite output file if it exists"
        return 0
    fi

    # Load BIOBASH core if not already loaded
    if ! declare -f parse_args >/dev/null; then
        . ./biobash_core.sh
    fi

    # Parse standard arguments
    parse_args "$@"

    # Validate input
    if [[ -z "$INPUT" ]]; then
        error "Missing required --input argument"
        return 1
    fi
    check_input "$INPUT"

    # Determine input file
    local infile
    if is_stdin "$INPUT"; then
        infile="/dev/stdin"
        BASENAME="STDIN"
    else
        infile="$INPUT"
        BASENAME=$(get_basename "$INPUT")
    fi

    # Determine output stream
    local outstream="/dev/stdout"
    if [[ -n "$OUTFILE" ]]; then
        if ! check_file_exists "$OUTFILE"; then
            return 1
        fi
        mkdir -p "$(dirname "$OUTFILE")" 2>/dev/null || {
            error "Cannot create directory for output: $(dirname "$OUTFILE")"
            return 1
        }
        outstream="$OUTFILE"
    fi

    # Log info
    info "Extracting FASTA headers from: $INPUT"
    info "Output: ${OUTFILE:-STDOUT}"

    # Perform the extraction
    grep '^>' "$infile" > "$outstream"

    info "Done."
}


bb_get_fasta_id() {
    # Show help if no arguments
    if [[ $# -eq 0 ]]; then
        echo "bb_get_fasta_id"
        echo "Extract sequence IDs from FASTA headers (first word after '>')."
        echo ""
        echo "Usage:"
        echo "  bb_get_fasta_id --input FILE [--outfile FILE] [--quiet] [--force]"
        echo ""
        echo "Options:"
        echo "  --input FILE      Input FASTA file or '-' for STDIN (required)"
        echo "  --outfile FILE    Output file (optional; default: STDOUT)"
        echo "  --quiet           Suppress log messages"
        echo "  --force           Overwrite output file if it exists"
        return 0
    fi

    # Load core functions if needed
    if ! declare -f parse_args >/dev/null; then
        . ./biobash_core.sh
    fi

    # Parse arguments
    parse_args "$@"

    # Validate input
    if [[ -z "$INPUT" ]]; then
        error "Missing required --input argument"
        return 1
    fi
    check_input "$INPUT"

    # Determine input source
    local infile
    if is_stdin "$INPUT"; then
        infile="/dev/stdin"
        BASENAME="STDIN"
    else
        infile="$INPUT"
        BASENAME=$(get_basename "$INPUT")
    fi

    # Determine output stream
    local outstream="/dev/stdout"
    if [[ -n "$OUTFILE" ]]; then
        if ! check_file_exists "$OUTFILE"; then
            return 1
        fi
        mkdir -p "$(dirname "$OUTFILE")" 2>/dev/null || {
            error "Cannot create directory for output: $(dirname "$OUTFILE")"
            return 1
        }
        outstream="$OUTFILE"
    fi

    # Log info
    info "Extracting FASTA IDs from: $INPUT"
    info "Output: ${OUTFILE:-STDOUT}"

    # Processing
    grep '^>' "$infile" | cut -d ' ' -f1 | sed 's/^>//' > "$outstream"

    info "Done."
}


bb_get_fasta_seq() {
    if [[ $# -eq 0 ]]; then
        echo "bb_get_fasta_seq"
        echo "Extract only sequence lines from a FASTA file (excluding headers)."
        echo ""
        echo "Usage:"
        echo "  bb_get_fasta_seq --input FILE [--outfile FILE] [--quiet] [--force]"
        echo ""
        echo "Options:"
        echo "  --input FILE      Input FASTA file or '-' for STDIN (required)"
        echo "  --outfile FILE    Output file (optional; default: STDOUT)"
        echo "  --quiet           Suppress log messages"
        echo "  --force           Overwrite output file if it exists"
        return 0
    fi

    # Load BIOBASH core if needed
    if ! declare -f parse_args >/dev/null; then
        . ./biobash_core.sh
    fi

    # Parse arguments
    parse_args "$@"

    # Validate input
    if [[ -z "$INPUT" ]]; then
        error "Missing required --input argument"
        return 1
    fi
    check_input "$INPUT"

    # Determine input source
    local infile
    if is_stdin "$INPUT"; then
        infile="/dev/stdin"
        BASENAME="STDIN"
    else
        infile="$INPUT"
        BASENAME=$(get_basename "$INPUT")
    fi

    # Determine output
    local outstream="/dev/stdout"
    if [[ -n "$OUTFILE" ]]; then
        if ! check_file_exists "$OUTFILE"; then
            return 1
        fi
        mkdir -p "$(dirname "$OUTFILE")" 2>/dev/null || {
            error "Cannot create directory for output: $(dirname "$OUTFILE")"
            return 1
        }
        outstream="$OUTFILE"
    fi

    # Info
    info "Extracting FASTA sequences from: $INPUT"
    info "Output: ${OUTFILE:-STDOUT}"

    # Core logic: remove lines starting with '>'
    grep -v '^>' "$infile" > "$outstream"

    info "Done."
}

bb_get_fasta_length() {
    if [[ $# -eq 0 ]]; then
        echo "bb_get_fasta_length"
        echo "Report sequence lengths from a FASTA file."
        echo ""
        echo "Usage:"
        echo "  bb_get_fasta_length --input FILE [--outfile FILE] [--quiet] [--force]"
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

    parse_args "$@"

    if [[ -z "$INPUT" ]]; then
        error "Missing required --input argument"
        return 1
    fi
    check_input "$INPUT"

    local infile
    if is_stdin "$INPUT"; then
        infile="/dev/stdin"
        BASENAME="STDIN"
    else
        infile="$INPUT"
        BASENAME=$(get_basename "$INPUT")
    fi

    local outstream="/dev/stdout"
    if [[ -n "$OUTFILE" ]]; then
        if ! check_file_exists "$OUTFILE"; then
            return 1
        fi
        mkdir -p "$(dirname "$OUTFILE")" 2>/dev/null || {
            error "Cannot create directory for output: $(dirname "$OUTFILE")"
            return 1
        }
        outstream="$OUTFILE"
    fi

    info "Calculating sequence lengths from: $INPUT"
    info "Output: ${OUTFILE:-STDOUT}"

    awk '
        /^>/ {
            if (id != "") {
                print id "\t" length(seq)
            }
            id = substr($1, 2)
            seq = ""
            next
        }
        {
            gsub(/[ \t\r\n]/, "", $0)
            seq = seq $0
        }
        END {
            if (id != "") {
                print id "\t" length(seq)
            }
        }
    ' "$infile" > "$outstream"

    info "Done."
}

bb_fastq_to_fasta() {
    if [[ $# -eq 0 ]]; then
        echo "bb_fastq_to_fasta"
        echo "Convert a FASTQ file to FASTA format."
        echo ""
        echo "Usage:"
        echo "  bb_fastq_to_fasta --input FILE [--outfile FILE] [--quiet] [--force]"
        echo ""
        echo "Options:"
        echo "  --input FILE      Input FASTQ file or '-' for STDIN (required)"
        echo "  --outfile FILE    Output file (optional; default: STDOUT)"
        echo "  --quiet           Suppress log messages"
        echo "  --force           Overwrite output file if it exists"
        return 0
    fi

    if ! declare -f parse_args >/dev/null; then
        . ./biobash_core.sh
    fi

    parse_args "$@"

    if [[ -z "$INPUT" ]]; then
        error "Missing required --input argument"
        return 1
    fi
    check_input "$INPUT"

    local infile
    if is_stdin "$INPUT"; then
        infile="/dev/stdin"
        BASENAME="STDIN"
    else
        infile="$INPUT"
        BASENAME=$(get_basename "$INPUT")
    fi

    local outstream="/dev/stdout"
    if [[ -n "$OUTFILE" ]]; then
        if ! check_file_exists "$OUTFILE"; then
            return 1
        fi
        mkdir -p "$(dirname "$OUTFILE")" 2>/dev/null || {
            error "Cannot create directory for output: $(dirname "$OUTFILE")"
            return 1
        }
        outstream="$OUTFILE"
    fi

    info "Converting FASTQ to FASTA from: $INPUT"
    info "Output: ${OUTFILE:-STDOUT}"

    awk 'NR % 4 == 1 { printf(">%s\n", substr($0, 2)) }
         NR % 4 == 2 { print }
        ' "$infile" > "$outstream"

    info "Done."
}

bb_split_multiple_fasta() {
    if [[ $# -eq 0 ]]; then
        echo "bb_split_multiple_fasta"
        echo "Split a multi-FASTA file into individual files (1 per entry)."
        echo ""
        echo "Usage:"
        echo "  bb_split_multiple_fasta --input FILE [--outdir DIR] [--quiet] [--force]"
        echo ""
        echo "Options:"
        echo "  --input FILE      Multi-FASTA file or '-' for STDIN (required)"
        echo "  --outdir DIR      Output directory (default: current directory)"
        echo "  --quiet           Suppress log messages"
        echo "  --force           Overwrite output files if they exist"
        return 0
    fi

    # Load BIOBASH core functions if not already loaded
    if ! declare -f parse_args >/dev/null; then
        . ./biobash_core.sh
    fi

    # Parse standard BIOBASH arguments
    parse_args "$@"

    # Validate input
    if [[ -z "$INPUT" ]]; then
        error "Missing required --input argument"
        return 1
    fi
    check_input "$INPUT"

    # Define input stream
    local infile
    if is_stdin "$INPUT"; then
        infile="/dev/stdin"
    else
        infile="$INPUT"
    fi

    # Determine and create output directory
    # Determine and create output directory
    local target_dir="${OUTDIR:-.}"
    if ! create_outdir "$target_dir"; then
        return 1
    fi



    info "Splitting FASTA entries from: $INPUT"
    info "Output directory: $target_dir"

    # Use awk to split entries
    awk -v outdir="$target_dir" -v force="$FORCE" '
        /^>/ {
            if (filename) close(filename)
            id = substr($1, 2)
            filename = outdir "/" id ".fasta"
            if ((force != "true") && (system("[ -e \"" filename "\" ]") == 0)) {
                print "[ERROR] File " filename " already exists. Use --force to overwrite." > "/dev/stderr"
                exit 1
            }
            print $0 > filename
            next
        }
        {
            print $0 > filename
        }
    ' "$infile"

    info "Done."
}


bb_get_fasta_entry() {
    if [[ $# -eq 0 ]]; then
        echo "bb_get_fasta_entry"
        echo "Extract one or multiple entries from a FASTA file by ID."
        echo ""
        echo "Usage:"
        echo "  bb_get_fasta_entry --input FILE (--entry ID | --entry-file FILE) [--outfile FILE] [--quiet] [--force]"
        echo ""
        echo "Options:"
        echo "  --input FILE        FASTA file or '-' for STDIN (required)"
        echo "  --entry ID          Single ID to extract"
        echo "  --entry-file FILE   File with one ID per line (mutually exclusive with --entry)"
        echo "  --outfile FILE      Output file (default: STDOUT)"
        echo "  --quiet             Suppress messages"
        echo "  --force             Overwrite output file if it exists"
        return 0
    fi

    if ! declare -f parse_args >/dev/null; then
        . ./biobash_core.sh
    fi

    local ENTRY_ID=""
    local ENTRY_FILE=""
    local args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --entry) ENTRY_ID="$2"; shift 2 ;;
            --entry-file) ENTRY_FILE="$2"; shift 2 ;;
            *) args+=("$1"); shift ;;
        esac
    done

    parse_args "${args[@]}"

    # Validaciones
    if [[ -z "$INPUT" ]]; then
        error "Missing required --input argument"
        return 1
    fi
    check_input "$INPUT"

    if [[ -n "$ENTRY_ID" && -n "$ENTRY_FILE" ]]; then
        error "Use either --entry or --entry-file, not both."
        return 1
    fi

    if [[ -z "$ENTRY_ID" && -z "$ENTRY_FILE" ]]; then
        error "You must specify --entry or --entry-file."
        return 1
    fi

    if [[ -n "$ENTRY_FILE" && ! -r "$ENTRY_FILE" ]]; then
        error "Cannot read entry file: $ENTRY_FILE"
        return 1
    fi

    local infile
    if is_stdin "$INPUT"; then
        infile="/dev/stdin"
    else
        infile="$INPUT"
    fi

    local outstream="/dev/stdout"
    if [[ -n "$OUTFILE" ]]; then
        if ! check_file_exists "$OUTFILE"; then
            return 1
        fi
        mkdir -p "$(dirname "$OUTFILE")" 2>/dev/null || {
            error "Cannot create directory for output: $(dirname "$OUTFILE")"
            return 1
        }
        outstream="$OUTFILE"
    fi

    info "Extracting entries from: $INPUT"
    info "Output: ${OUTFILE:-STDOUT}"

    awk -v single="$ENTRY_ID" -v list="$ENTRY_FILE" -v quiet="$QUIET" '
        BEGIN {
            found_any = 0
            if (single != "") {
                ids[single] = 0
            } else {
                while ((getline id < list) > 0) {
                    gsub(/[\r\n\t ]/, "", id)
                    if (id != "") {
                        ids[id] = 0
                    }
                }
                close(list)
            }
        }

        /^>/ {
            header = substr($1, 2)
            print_entry = 0
            if (header in ids) {
                print_entry = 1
                ids[header] = 1
                found_any = 1
                print $0
                next
            }
    }


        {
            if (print_entry) print
        }

        END {
            for (id in ids) {
                if (ids[id] == 0 && quiet != "true") {
                    print "[WARN] Entry ID \"" id "\" not found." > "/dev/stderr"
                }
            }
            if (!found_any && quiet != "true") {
                print "[WARN] No entries found in input." > "/dev/stderr"
            }
        }
    ' "$infile" > "$outstream"

    info "Done."
}

bb_get_fasta_range() {
    if [[ $# -eq 0 ]]; then
        echo "bb_get_fasta_range"
        echo "Extract a subsequence range from a FASTA entry by ID and coordinates."
        echo ""
        echo "Usage:"
        echo "  bb_get_fasta_range --input FILE [--entry ID] --start INT --end INT [--outfile FILE] [--quiet] [--force]"
        echo ""
        echo "Options:"
        echo "  --input FILE      Input FASTA file or '-' for STDIN (required)"
        echo "  --entry ID        Entry ID to extract (optional if file has one sequence)"
        echo "  --start INT       Start position (1-based, inclusive)"
        echo "  --end INT         End position (1-based, inclusive)"
        echo "  --outfile FILE    Output file (default: STDOUT)"
        echo "  --quiet           Suppress messages"
        echo "  --force           Overwrite output file if it exists"
        return 0
    fi

    if ! declare -f parse_args >/dev/null; then
        . ./biobash_core.sh
    fi

    local ENTRY_ID=""
    local START=""
    local END=""
    local args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --entry) ENTRY_ID="$2"; shift 2 ;;
            --start) START="$2"; shift 2 ;;
            --end)   END="$2"; shift 2 ;;
            *) args+=("$1"); shift ;;
        esac
    done

    parse_args "${args[@]}"

    if [[ -z "$INPUT" || -z "$START" || -z "$END" ]]; then
        error "Missing required arguments. Must specify --input, --start, and --end."
        return 1
    fi

    if ! [[ "$START" =~ ^[0-9]+$ && "$END" =~ ^[0-9]+$ ]]; then
        error "--start and --end must be positive integers"
        return 1
    fi

    if (( START > END )); then
        error "--start cannot be greater than --end"
        return 1
    fi

    local stdin_tmp=""
    if is_stdin "$INPUT"; then
        stdin_tmp=$(mktemp)
        cat - > "$stdin_tmp"
        INPUT="$stdin_tmp"
    fi

    # Autodetect ID if not provided
    if [[ -z "$ENTRY_ID" ]]; then
        local count
        count=$(grep -c '^>' "$INPUT")
        if [[ "$count" -eq 1 ]]; then
            ENTRY_ID=$(grep '^>' "$INPUT" | head -n1 | cut -d ' ' -f1 | sed 's/^>//')
            [[ "$QUIET" != "true" ]] && echo "[INFO]  Auto-detected single entry ID: $ENTRY_ID" >&2
        else
            error "--entry is required when the input contains more than one sequence"
            [[ -n "$stdin_tmp" ]] && rm -f "$stdin_tmp"
            return 1
        fi
    fi

    local outstream="/dev/stdout"
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
        outstream="$OUTFILE"
    fi

    info "Extracting range $START-$END from entry $ENTRY_ID in $INPUT"
    info "Output: ${OUTFILE:-STDOUT}"

    awk -v id="$ENTRY_ID" -v start="$START" -v end="$END" -v quiet="$QUIET" '
        BEGIN { found=0; seq=""; header="" }
        /^>/ {
            if (found) exit
            cur_id = substr($1, 2)
            if (cur_id == id) {
                found = 1
                header = $0
                next
            }
        }
        {
            if (found) {
                gsub(/[^A-Za-z]/, "", $0)
                seq = seq $0
            }
        }
        END {
            if (!found) {
                if (quiet != "true") {
                    print "[WARN] Entry ID \"" id "\" not found." > "/dev/stderr"
                }
                exit 0
            }

            if (length(seq) < end) {
                if (quiet != "true") {
                    print "[WARN] End position exceeds sequence length." > "/dev/stderr"
                }
                exit 0
            }

            print header
            print substr(seq, start, end - start + 1)
        }
    ' "$INPUT" > "$outstream"

    [[ -n "$stdin_tmp" ]] && rm -f "$stdin_tmp"
    info "Done."
}

bb_fasta_stats() {
    if [[ $# -eq 0 ]]; then
        echo "bb_fasta_stats"
        echo "Generate basic FASTA statistics including N50."
        echo ""
        echo "Usage:"
        echo "  bb_fasta_stats --input FILE [--outfile FILE] [--quiet] [--force]"
        echo ""
        echo "Options:"
        echo "  --input FILE      Input FASTA file or '-' for STDIN (required)"
        echo "  --outfile FILE    Output file (default: STDOUT)"
        echo "  --quiet           Suppress messages"
        echo "  --force           Overwrite output file if it exists"
        return 0
    fi

    if ! declare -f parse_args >/dev/null; then
        . ./biobash_core.sh
    fi

    parse_args "$@"

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

    local outstream="/dev/stdout"
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
        outstream="$OUTFILE"
    fi

    info "Generating FASTA stats from: $INPUT"
    info "Output: ${OUTFILE:-STDOUT}"

    LC_NUMERIC=C awk '
        BEGIN {
            seq = ""; count = 0; total_len = 0; min = 1e9; max = 0;
        }
        /^>/ {
            if (seq != "") {
                len = length(seq);
                lengths[count++] = len;
                total_len += len;
                if (len > max) max = len;
                if (len < min) min = len;
                seq = "";
            }
            next;
        }
        {
            gsub(/[^A-Za-z]/, "", $0);
            seq = seq $0;
        }
        
        END {
            if (seq != "") {
                len = length(seq);
                lengths[count++] = len;
                total_len += len;
                if (len > max) max = len;
                if (len < min) min = len;
            }

            if (count == 0) {
                print "[WARN] No sequences found." > "/dev/stderr";
                exit 0;
            }

            avg = total_len / count;

            # N50 calculation
            n = count;
            for (i = 0; i < n-1; i++) {
                for (j = i+1; j < n; j++) {
                    if (lengths[i] < lengths[j]) {
                        tmp = lengths[i];
                        lengths[i] = lengths[j];
                        lengths[j] = tmp;
                    }
                }
            }

            half = total_len / 2;
            sum = 0;
            N50 = 0;
            for (i = 0; i < n; i++) {
                sum += lengths[i];
                if (sum >= half) {
                    N50 = lengths[i];
                    break;
                }
            }

            print "STATISTIC        VALUE"
            print "---------------- ----------------"
            printf "Total sequences: %d\n", count
            printf "Total length:    %d\n", total_len
            printf "Minimum length:  %d\n", min
            printf "Maximum length:  %d\n", max
            printf "Average length:  %.2f\n", avg
            printf "N50:             %d\n", N50
        }
    ' "$INPUT" > "$outstream"

    [[ -n "$stdin_tmp" ]] && rm -f "$stdin_tmp"
    info "Done."
}


bb_guess_sequence_type() {
    if [[ $# -eq 0 ]]; then
        echo "bb_guess_sequence_type"
        echo "Guess whether a FASTA file contains DNA, RNA or Protein sequences."
        echo ""
        echo "Usage:"
        echo "  bb_guess_sequence_type --input FILE [--outfile FILE] [--quiet] [--force]"
        echo ""
        echo "Options:"
        echo "  --input FILE      Input FASTA file or '-' for STDIN (required)"
        echo "  --outfile FILE    Output file (default: STDOUT)"
        echo "  --quiet           Suppress messages"
        echo "  --force           Overwrite output file if it exists"
        return 0
    fi

    if ! declare -f parse_args >/dev/null; then
        . ./biobash_core.sh
    fi

    parse_args "$@"

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

    # FASTQ detection (first line '@' and third line '+')
    if awk 'NR==1 && /^@/ { getline; getline; if (/^\+$/) exit 1; else exit 0 }' "$INPUT"; then
        true  # Not a FASTQ
    else
        error "Input appears to be a FASTQ file, not a FASTA"
        [[ -n "$stdin_tmp" ]] && rm -f "$stdin_tmp"
        return 1
    fi

    local outstream="/dev/stdout"
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
        outstream="$OUTFILE"
    fi

    info "Guessing sequence type from: $INPUT"
    info "Output: ${OUTFILE:-STDOUT}"

    local result

    result=$(awk '
        BEGIN { dna=0; rna=0; prot=0 }
        /^>/ { next }
        {
            seq = toupper($0)
            gsub(/[^A-Z]/, "", seq)
            if (seq ~ /^[ACGTN]+$/) dna++
            else if (seq ~ /^[ACGUN]+$/ && seq !~ /T/) rna++
            else prot++
        }
        END {
            if (dna > rna && dna > prot) print "DNA"
            else if (rna > dna && rna > prot) print "RNA"
            else print "Protein"
        }
    ' "$INPUT")

    echo "$result" > "$outstream"

    [[ -n "$stdin_tmp" ]] && rm -f "$stdin_tmp"
    info "Done."
}

#======
bb_fastq_stats() {
    if [[ $# -eq 0 ]]; then
        echo "bb_fastq_stats"
        echo "Generate basic statistics from a FASTQ file (supports random subsampling)."
        echo ""
        echo "Usage:"
        echo "  bb_fastq_stats --input FILE [--outfile FILE] [--sample_size PCT] [--quiet] [--force]"
        echo ""
        echo "Options:"
        echo "  --input FILE       FASTQ file or '-' for STDIN (required)"
        echo "  --outfile FILE     Output file (default: STDOUT)"
        echo "  --sample_size PCT  Percent of reads to sample randomly (default: 10)"
        echo "  --quiet            Suppress informational messages"
        echo "  --force            Overwrite output file if it exists"
        return 0
    fi

    local SAMPLE_SIZE=10
    local stdin_tmp=""
    local args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --sample_size) SAMPLE_SIZE="$2"; shift 2 ;;
            *) args+=("$1"); shift ;;
        esac
    done

    if ! declare -f parse_args >/dev/null; then . ./biobash_core.sh; fi
    parse_args "${args[@]}"
    check_input "$INPUT"

    if [[ "$SAMPLE_SIZE" -lt 1 || "$SAMPLE_SIZE" -gt 100 ]]; then
        error "--sample_size must be a percentage between 1 and 100"
        return 1
    fi

    local infile="$INPUT"
    if is_stdin "$INPUT"; then
        stdin_tmp=$(mktemp)
        cat - > "$stdin_tmp"
        infile="$stdin_tmp"
    fi

    local total_lines
    total_lines=$(wc -l < "$infile")
    local total_reads=$((total_lines / 4))
    local sampled_reads=$((total_reads * SAMPLE_SIZE / 100))
    [[ "$sampled_reads" -lt 1 ]] && sampled_reads=1

    [[ "$QUIET" != "true" ]] && info "Total reads in file: $total_reads"
    [[ "$QUIET" != "true" ]] && info "Sampling $sampled_reads reads (${SAMPLE_SIZE}%)"

    local sampled_tmp
    sampled_tmp=$(mktemp)

    shuf -i 0-$((total_reads - 1)) -n "$sampled_reads" | sort -n | awk -v infile="$infile" '
        BEGIN { getline_cmd = "cat " infile }
        {
            start = ($1 * 4) + 1
            for (i = 0; i < 4; i++) lines[start + i] = 1
        }
        END {
            close(getline_cmd)
            while ((getline line < infile) > 0) {
                line_num++
                if (line_num in lines) print line
            }
        }
    ' > "$sampled_tmp"

    local outstream="/dev/stdout"
    if [[ -n "$OUTFILE" ]]; then
        if ! check_file_exists "$OUTFILE"; then
            [[ -n "$stdin_tmp" ]] && rm -f "$stdin_tmp"
            rm -f "$sampled_tmp"
            return 1
        fi
        mkdir -p "$(dirname "$OUTFILE")" 2>/dev/null || {
            error "Cannot create output directory for: $(dirname "$OUTFILE")"
            [[ -n "$stdin_tmp" ]] && rm -f "$stdin_tmp"
            rm -f "$sampled_tmp"
            return 1
        }
        outstream="$OUTFILE"
    fi

    [[ "$QUIET" != "true" ]] && info "Generating FASTQ stats from sample..."

    LC_NUMERIC=C awk -v file="$INPUT" -v total_reads="$total_reads" '
        BEGIN {
            count = 0
            total_len = 0
            min = 1e9
            max = 0
            total_qual = 0
            qual_count = 0
            q20 = 0
            q30 = 0
            s = " !\"#$%&'\''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
        }
        NR % 4 == 2 {
            len = length($0)
            total_len += len
            if (len < min) min = len
            if (len > max) max = len
            count++
        }
        NR % 4 == 0 {
            for (i = 1; i <= length($0); i++) {
                c = substr($0, i, 1)
                phred = index(s, c) - 1
                total_qual += phred
                qual_count++
                if (phred >= 20) q20++
                if (phred >= 30) q30++
            }
        }
        END {
            avg_len = (count > 0) ? total_len / count : 0
            avg_qual = (qual_count > 0) ? total_qual / qual_count : 0
            q20_pct = (qual_count > 0) ? 100 * q20 / qual_count : 0
            q30_pct = (qual_count > 0) ? 100 * q30 / qual_count : 0

            printf "#   File name      numseqs  sumlen   minlen   avg_len   maxlen   Q20(%%)   Q30(%%)\n"
            printf "    %-15s", file
            printf " %7d", total_reads
            printf "  %7d", total_len
            printf "  %7d", min
            printf "   %7.2f", avg_len
            printf "  %7d", max
            printf "   %7.2f", q20_pct
            printf "  %7.2f\n", q30_pct
}

    ' "$sampled_tmp" > "$outstream"

    [[ "$QUIET" != "true" ]] && info "Done."

    rm -f "$sampled_tmp"
    [[ -n "$stdin_tmp" ]] && rm -f "$stdin_tmp"
}


#====
bb_fastq_subsampling() {
    if [[ $# -eq 0 ]]; then
        echo "bb_fastq_subsampling"
        echo "Randomly subsample a percentage of sequences from a FASTQ file."
        echo ""
        echo "Usage:"
        echo "  bb_fastq_subsampling --input FILE [--sample_size PCT] [--outfile FILE] [--quiet] [--force]"
        echo ""
        echo "Options:"
        echo "  --input FILE       FASTQ file or '-' for STDIN (required)"
        echo "  --sample_size PCT  Percentage of reads to subsample (1–100, default: 10)"
        echo "  --outfile FILE     Output FASTQ file (default: STDOUT)"
        echo "  --quiet            Suppress informational messages"
        echo "  --force            Overwrite output file if it exists"
        return 0
    fi

    if ! declare -f parse_args >/dev/null; then . ./biobash_core.sh; fi

    local SAMPLE_SIZE=10
    local args=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --sample_size) SAMPLE_SIZE="$2"; shift 2 ;;
            *) args+=("$1"); shift ;;
        esac
    done

    if [[ "$SAMPLE_SIZE" -lt 1 || "$SAMPLE_SIZE" -gt 100 ]]; then
        error "--sample_size must be a percentage between 1 and 100"
        return 1
    fi

    parse_args "${args[@]}"
    check_input "$INPUT"

    local stdin_tmp=""
    local DECOMP_CMD=""
    local infile="$INPUT"

    # Descomprimir si viene de .gz
    if [[ "$INPUT" == *.gz ]]; then
        detect_os
        case "$OS_TYPE" in
            macos)
                if ! command -v gzcat &>/dev/null; then
                    error "gzcat not found on macOS to handle .gz files"
                    return 1
                fi
                DECOMP_CMD="gzcat"
                ;;
            linux)
                if ! command -v zcat &>/dev/null; then
                    error "zcat not found on Linux to handle .gz files"
                    return 1
                fi
                DECOMP_CMD="zcat"
                ;;
            *)
                error "Unsupported OS for compressed FASTQ handling"
                return 1
                ;;
        esac

        stdin_tmp=$(mktemp)
        if ! $DECOMP_CMD "$INPUT" > "$stdin_tmp"; then
            error "Failed to decompress input file: $INPUT"
            rm -f "$stdin_tmp"
            return 1
        fi
        infile="$stdin_tmp"
    elif is_stdin "$INPUT"; then
        stdin_tmp=$(mktemp)
        cat - > "$stdin_tmp"
        infile="$stdin_tmp"
    fi

    local total_lines
    total_lines=$(wc -l < "$infile")
    local total_reads=$((total_lines / 4))
    local sampled_reads=$((total_reads * SAMPLE_SIZE / 100))
    [[ "$sampled_reads" -lt 1 ]] && sampled_reads=1

    [[ "$QUIET" != "true" ]] && info "Total reads: $total_reads"
    [[ "$QUIET" != "true" ]] && info "Sampling $sampled_reads reads (${SAMPLE_SIZE}%)"

    local outstream="/dev/stdout"
    if [[ -n "$OUTFILE" ]]; then
        if ! check_file_exists "$OUTFILE"; then
            [[ -n "$stdin_tmp" ]] && rm -f "$stdin_tmp"
            return 1
        fi
        mkdir -p "$(dirname "$OUTFILE")" 2>/dev/null || {
            error "Cannot create output directory: $(dirname "$OUTFILE")"
            [[ -n "$stdin_tmp" ]] && rm -f "$stdin_tmp"
            return 1
        }
        outstream="$OUTFILE"
    fi

    local sampled_tmp
    sampled_tmp=$(mktemp)

    shuf -i 0-$((total_reads - 1)) -n "$sampled_reads" | sort -n | awk -v infile="$infile" '
        {
            start = ($1 * 4) + 1
            for (i = 0; i < 4; i++) lines[start + i] = 1
        }
        END {
            while ((getline line < infile) > 0) {
                line_num++
                if (line_num in lines) print line
            }
        }
    ' > "$sampled_tmp"

    cat "$sampled_tmp" > "$outstream"
    rm -f "$sampled_tmp"
    [[ -n "$stdin_tmp" ]] && rm -f "$stdin_tmp"
    [[ "$QUIET" != "true" ]] && info "Subsample written to: ${OUTFILE:-STDOUT}"
}















