bb_create_blast_db() {
    if [[ $# -eq 0 ]]; then
        echo "bb_create_blast_db"
        echo "Create a BLAST database from a FASTA file using makeblastdb."
        echo ""
        echo "Usage:"
        echo "  bb_create_blast_db --input FILE [--outdir DIR] [--db_name NAME] [--title TITLE] [--dry_run] [--quiet] [--force]"
        echo ""
        echo "Options:"
        echo "  --input FILE      Input FASTA file (required)"
        echo "  --outdir DIR      Output directory (default: current directory)"
        echo "  --db_name NAME    Name for the resulting BLAST database (default: based on input)"
        echo "  --title TITLE     Title for the database (default: based on input)"
        echo "  --dry_run         Only print the command that would be executed"
        echo "  --quiet           Suppress informational messages"
        echo "  --force           Overwrite existing output files if necessary"
        return 0
    fi

    # Load core if needed
    if ! declare -f parse_args >/dev/null; then
        . ./biobash_core.sh
    fi

    # Extra options
    local DB_NAME=""
    local TITLE=""
    local DRY_RUN="false"

    # Parse custom arguments
    local args=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --db_name) DB_NAME="$2"; shift 2 ;;
            --title)   TITLE="$2"; shift 2 ;;
            --dry_run) DRY_RUN="true"; shift ;;
            *) args+=("$1"); shift ;;
        esac
    done

    parse_args "${args[@]}"

    # Validations
    if [[ -z "$INPUT" ]]; then
        error "Missing required --input argument"
        return 1
    fi

    check_input "$INPUT"
    check_dependencies makeblastdb bb_guess_sequence_type

    # Default values
    local BASENAME
    BASENAME=$(get_basename "$INPUT")
    DB_NAME="${DB_NAME:-$BASENAME}"
    TITLE="${TITLE:-$BASENAME}"
    OUTDIR="${OUTDIR:-.}"

    # Create output directory if needed
    if ! create_outdir "$OUTDIR"; then
        return 1
    fi

    local FULL_OUTPATH="${OUTDIR%/}/$DB_NAME"

    # Check if database files exist
    if [[ "$FORCE" != "true" ]]; then
        for ext in ".nhr" ".nin" ".nsq" ".phr" ".pin" ".psq"; do
            if [[ -e "$FULL_OUTPATH$ext" ]]; then
                error "Output file '$FULL_OUTPATH$ext' already exists. Use --force to overwrite."
                return 1
            fi
        done
    fi

    # Detect sequence type
    local SEQ_TYPE
    SEQ_TYPE=$(bb_guess_sequence_type --input "$INPUT" --quiet 2>/dev/null)
    case "$SEQ_TYPE" in
        DNA|RNA) SEQ_TYPE="nucl" ;;
        Protein) SEQ_TYPE="prot" ;;
        *)
            error "Unable to determine sequence type. Ensure input is valid FASTA."
            return 1
            ;;
    esac

    # Build command
    local CMD="makeblastdb -in \"$INPUT\" -dbtype $SEQ_TYPE -out \"$FULL_OUTPATH\" -title \"$TITLE\" -parse_seqids"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Command:"
        echo "$CMD"
        return 0
    fi

    info "Creating BLAST database from: $INPUT"
    info "Output prefix: $FULL_OUTPATH"
    info "Sequence type: $SEQ_TYPE"
    info "Title: $TITLE"

    eval "$CMD"
    local status=$?

    if [[ "$status" -ne 0 ]]; then
        error "makeblastdb execution failed"
        return 1
    fi

    info "BLAST database successfully created: $FULL_OUTPATH.*"
    return 0
}

bb_guess_db_type() {
  local db_prefix="$1"
  if [[ -f "${db_prefix}.pin" ]]; then
    echo "prot"
  elif [[ -f "${db_prefix}.nin" ]]; then
    echo "nucl"
  else
    echo "unknown"
  fi
}


bb_run_blast() {
    if [[ $# -eq 0 ]]; then
    echo "bb_run_blast"
    echo "Run a BLAST search using a given query and database."
    echo ""
    echo "Usage:"
    echo "  bb_run_blast --input FILE --db PREFIX --blast_type TYPE [--outfile FILE|DIR] [--strict] [--quiet] [--force]"
    echo ""
    echo "Options:"
    echo "  --input FILE      Query file in FASTA format (required)"
    echo "  --db PREFIX       BLAST database prefix (required)"
    echo "  --blast_type TYPE One of: blastn, blastp, blastx, tblastn, tblastx (required)"
    echo "  --outfile FILE    Output file or directory (default: ./<query>.blastout)"
    echo "  --strict          Return error if no hits are found"
    echo "  --quiet           Suppress messages"
    echo "  --force           Overwrite output file if it exists"
    echo ""
    echo "Output format:"
    echo "  Tabular format (BLAST outfmt 6) with the following columns:"
    echo "    qseqid    sseqid    pident    length    mismatch    gapopen"
    echo "    qstart    qend      sstart    send      evalue      bitscore"
    echo "    qlen      slen"
    echo ""
    return 0
fi


    # Load BIOBASH core and file functions
    if ! declare -f parse_args >/dev/null; then . ./biobash_core.sh; fi
    if ! declare -f bb_guess_sequence_type >/dev/null; then . ./file.sh; fi
    if ! declare -f bb_guess_db_type >/dev/null; then
        error "Missing required function: bb_guess_db_type"
        return 1
    fi

    # Extra options
    local DB=""
    local BLAST_TYPE=""
    local STRICT="false"
    local FORMAT="6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen"

    # Custom args
    local args=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --db) DB="$2"; shift 2 ;;
            --blast_type) BLAST_TYPE="$2"; shift 2 ;;
            --strict) STRICT="true"; shift ;;
            *) args+=("$1"); shift ;;
        esac
    done

    parse_args "${args[@]}"

    if [[ -z "$INPUT" || -z "$DB" || -z "$BLAST_TYPE" ]]; then
        error "Missing required arguments: --input, --db, --blast_type"
        return 1
    fi

    check_input "$INPUT"
    check_dependencies "$BLAST_TYPE"

    local SEQ_TYPE
    SEQ_TYPE=$(bb_guess_sequence_type --input "$INPUT" --quiet 2>/dev/null)

    local DB_TYPE
    DB_TYPE=$(bb_guess_db_type "$DB")

    info "Detected query type: $SEQ_TYPE"
    info "Detected DB type: $DB_TYPE"

    if [[ "$SEQ_TYPE" == "unknown" || "$DB_TYPE" == "unknown" ]]; then
        error "Could not determine query or DB type"
        return 1
    fi

    # Validate type combination
    case "$BLAST_TYPE" in
        blastn)   [[ "$SEQ_TYPE" == "DNA" && "$DB_TYPE" == "nucl" ]] || { error "blastn requires DNA vs nucl"; return 1; } ;;
        blastp)   [[ "$SEQ_TYPE" == "Protein" && "$DB_TYPE" == "prot" ]] || { error "blastp requires Protein vs prot"; return 1; } ;;
        blastx)   [[ "$SEQ_TYPE" == "DNA" && "$DB_TYPE" == "prot" ]] || { error "blastx requires DNA vs prot"; return 1; } ;;
        tblastn)  [[ "$SEQ_TYPE" == "Protein" && "$DB_TYPE" == "nucl" ]] || { error "tblastn requires Protein vs nucl"; return 1; } ;;
        tblastx)  [[ "$SEQ_TYPE" == "DNA" && "$DB_TYPE" == "nucl" ]] || { error "tblastx requires DNA vs nucl"; return 1; } ;;
        *)        error "Unsupported blast_type: $BLAST_TYPE"; return 1 ;;
    esac

    local BASENAME
    BASENAME=$(get_basename "$INPUT")
    local OUTPUT_PATH=""

    if [[ -z "$OUTFILE" ]]; then
        OUTPUT_PATH="${BASENAME}.blastout"
    elif [[ -d "$OUTFILE" ]]; then
        OUTPUT_PATH="${OUTFILE%/}/${BASENAME}.blastout"
    else
        create_outdir "$(dirname "$OUTFILE")" || return 1
        OUTPUT_PATH="$OUTFILE"
    fi

    if ! check_file_exists "$OUTPUT_PATH"; then
        return 1
    fi

    info "Running $BLAST_TYPE"
    info "Query: $INPUT"
    info "Database: $DB"
    info "Output: $OUTPUT_PATH"

    "$BLAST_TYPE" -query "$INPUT" -db "$DB" -out "$OUTPUT_PATH" -outfmt "$FORMAT"
    local status=$?

    if [[ "$status" -ne 0 ]]; then
        error "$BLAST_TYPE failed"
        return 1
    fi

    # Handle empty output case
    if [[ ! -s "$OUTPUT_PATH" || $(wc -l < "$OUTPUT_PATH") -eq 0 ]]; then
        echo "blast: no hits found" > "$OUTPUT_PATH"
        if [[ "$STRICT" == "true" ]]; then
            warn "BLAST completed but returned no hits (strict mode active)"
            return 1
        else
            warn "BLAST completed but returned no hits"
        fi
    else
        info "BLAST completed successfully"
    fi

    return 0
}

bb_blast_best_hit() {
    if [[ $# -eq 0 ]]; then
        echo "bb_blast_best_hit"
        echo "Extract the best BLAST hit per (qseqid, sseqid) pair based on:"
        echo "- lowest e-value (column 11)"
        echo "- highest bitscore (column 12) in case of tie"
        echo ""
        echo "Usage:"
        echo "  bb_blast_best_hit --input FILE [--outfile FILE] [--quiet] [--force]"
        echo ""
        echo "Required:"
        echo "  --input FILE       BLAST output file in outfmt 6 with 14 columns, or '-' for STDIN"
        echo ""
        echo "Optional:"
        echo "  --outfile FILE     Output file (default: STDOUT)"
        echo "  --quiet            Suppress informational messages"
        echo "  --force            Overwrite output file if it exists"
        echo "  --help             Show this help message"
        echo ""
        echo "Input format must include the following 14 columns (BLAST outfmt 6):"
        echo "  qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen"
        echo ""
        echo "The function returns one line per unique (qseqid, sseqid) pair."
        return 0
    fi

    # Load core
    if ! declare -f parse_args >/dev/null; then . ./biobash_core.sh; fi

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
            error "Cannot create output directory for $(dirname "$OUTFILE")"
            [[ -n "$stdin_tmp" ]] && rm -f "$stdin_tmp"
            return 1
        }
        outstream="$OUTFILE"
    fi

    info "Selecting best hit per (qseqid, sseqid) from: $INPUT"
    info "Output: ${OUTFILE:-STDOUT}"

    local tmp_output
    tmp_output=$(mktemp)

    awk '
    NF == 0 { next }  # skip blank lines
    {
        if (NF < 14) {
            print "[ERROR] Expected 14 columns in input, found " NF > "/dev/stderr"
            exit 1
        }

        qid = $1
        sid = $2
        key = qid "|" sid
        evalue = $11 + 0
        bitscore = $12 + 0

        if (!(key in best_e) || evalue < best_e[key] || (evalue == best_e[key] && bitscore > best_b[key])) {
            best_line[key] = $0
            best_e[key] = evalue
            best_b[key] = bitscore
        }
    }
    END {
        for (k in best_line) print best_line[k]
    }
    ' "$INPUT" > "$tmp_output"

    local status=$?
    if [[ "$status" -ne 0 ]]; then
        rm -f "$tmp_output"
        error "Aborted due to invalid input format"
        [[ -n "$stdin_tmp" ]] && rm -f "$stdin_tmp"
        return 1
    fi

    cat "$tmp_output" > "$outstream"
    rm -f "$tmp_output"
    [[ -n "$stdin_tmp" ]] && rm -f "$stdin_tmp"

    info "Done."
    return 0
}

bb_blast_summary() {
    if [[ $# -eq 0 ]]; then
        echo "bb_blast_summary"
        echo "Generate summary statistics from a BLAST tabular file (outfmt 6) with qlen and slen."
        echo ""
        echo "Usage:"
        echo "  bb_blast_summary --input FILE [--outfile FILE] [--quiet] [--force]"
        echo ""
        echo "Options:"
        echo "  --input FILE      BLAST outfmt6 file with 14 columns (required)"
        echo "  --outfile FILE    Output file (default: STDOUT)"
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

    info "Generating BLAST summary from: $INPUT"
    info "Output: ${OUTFILE:-STDOUT}"

    LC_NUMERIC=C awk '
    {
        total_hits++
        qid = $1
        sid = $2
        ident = $3
        qstart = $7; qend = $8
        sstart = $9; send = $10
        evalue = $11
        qlen = $13 + 0
        slen = $14 + 0

        qcov = (qend > qstart) ? qend - qstart + 1 : qstart - qend + 1
        scov = (send > sstart) ? send - sstart + 1 : sstart - send + 1
        qcov_pct = (qlen > 0) ? (qcov / qlen) * 100 : 0
        scov_pct = (slen > 0) ? (scov / slen) * 100 : 0

        total_ident += ident
        total_qcov += qcov_pct
        total_scov += scov_pct
        total_evalue += evalue + 0  # asegurar que es numérico
        if ((evalue + 0) <= 1e-5) significant++

        queries[qid] = 1
        targets[sid] = 1
        hits_per_query[qid]++
    }

    END {
        num_queries = length(queries)
        num_targets = length(targets)
        queries_with_hits = length(hits_per_query)

        avg_ident = (total_hits > 0) ? total_ident / total_hits : 0
        avg_qcov = (total_hits > 0) ? total_qcov / total_hits : 0
        avg_scov = (total_hits > 0) ? total_scov / total_hits : 0
        avg_eval = (total_hits > 0) ? total_evalue / total_hits : 0
        sig_pct = (total_hits > 0) ? (significant / total_hits) * 100 : 0

        printf "BLAST Summary:\n"
        printf "  Total alignments:               %d\n", total_hits
        printf "  Unique queries:                 %d\n", num_queries
        printf "  Unique targets:                 %d\n", num_targets
        printf "  Queries with hits:              %d\n", queries_with_hits
        printf "  Avg identity:                   %.2f%%\n", avg_ident
        printf "  Avg query coverage:             %.2f%%\n", avg_qcov
        printf "  Avg target coverage:            %.2f%%\n", avg_scov
        printf "  Avg e-value:                    %.2e\n", avg_eval
        printf "  %% of hits with e<=1e-5:         %.2f%%\n", sig_pct
        print ""
        print "Top 5 query IDs with most hits:"
        for (q in hits_per_query)
            print hits_per_query[q] "\t" q | "sort -nr | head -n 5"
    }
    ' "$INPUT" > "$outstream"

    [[ -n "$stdin_tmp" ]] && rm -f "$stdin_tmp"
    info "Done."
}

bb_blast_on_the_fly() {
    if [[ $# -eq 0 ]]; then
        echo "bb_blast_on_the_fly"
        echo "Run a temporary BLAST search with automatic database creation."
        echo ""
        echo "Usage:"
        echo "  bb_blast_on_the_fly --query FILE --db FILE --blast_type TYPE [--outfile FILE] [--quiet] [--force]"
        echo ""
        echo "Options:"
        echo "  --query FILE        Query FASTA file (required)"
        echo "  --db FILE           Subject FASTA file (required)"
        echo "  --blast_type TYPE   One of: blastn, blastp, blastx, tblastn, tblastx (required)"
        echo "  --outfile FILE      Output file (default: query.blastout)"
        echo "  --quiet             Suppress log messages"
        echo "  --force             Overwrite output file if it exists"
        return 0
    fi

    # Cargar núcleo si es necesario
    if ! declare -f parse_args >/dev/null; then
        . ./biobash_core.sh
        . ./file.sh
        . ./blast.sh
    fi

    # Por defecto: verbose (solo se silencia con --quiet)
    QUIET="false"

    local QUERY=""
    local DB=""
    local BLAST_TYPE=""
    local args=()

    # Parseo manual de argumentos especiales
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --query) QUERY="$2"; shift 2 ;;
            --db) DB="$2"; shift 2 ;;
            --blast_type) BLAST_TYPE="$2"; shift 2 ;;
            --quiet) QUIET="true"; shift ;;
            *) args+=("$1"); shift ;;
        esac
    done

    parse_args "${args[@]}"

    # Validaciones
    if [[ -z "$QUERY" || -z "$DB" || -z "$BLAST_TYPE" ]]; then
        error "Missing required arguments: --query, --db, or --blast_type"
        return 1
    fi

    if [[ ! -r "$QUERY" ]]; then
        error "Query file not found or unreadable: $QUERY"
        return 1
    fi

    if [[ ! -r "$DB" ]]; then
        error "Database file not found or unreadable: $DB"
        return 1
    fi

    local QUERY_BASENAME
    QUERY_BASENAME=$(get_basename "$QUERY")
    local DEFAULT_OUT="${QUERY_BASENAME}.blastout"
    local FINAL_OUT="${OUTFILE:-$DEFAULT_OUT}"

    if ! check_file_exists "$FINAL_OUT"; then
        return 1
    fi

    local OUTDIR
    OUTDIR=$(dirname "$FINAL_OUT")
    if ! create_outdir "$OUTDIR"; then
        return 1
    fi

    local TMPDIR
    TMPDIR=$(mktemp -d)
    if [[ ! -d "$TMPDIR" ]]; then
        error "Failed to create temporary directory"
        return 1
    fi

    info "Creating temporary BLAST database"
    if ! bb_create_blast_db --input "$DB" --outdir "$TMPDIR" --db_name tempdb --title "OnTheFlyDB"; then
        error "Failed to create BLAST database"
        rm -rf "$TMPDIR"
        return 1
    fi

    info "Running BLAST search"
    if ! bb_run_blast --input "$QUERY" --db "$TMPDIR/tempdb" --blast_type "$BLAST_TYPE" --outfile "$TMPDIR"; then
        error "BLAST execution failed"
        rm -rf "$TMPDIR"
        return 1
    fi

    local TMP_OUT="$TMPDIR/${QUERY_BASENAME}.blastout"
    mv "$TMP_OUT" "$FINAL_OUT"

    # Evaluar si hubo hits
    if grep -q "no hits found" "$FINAL_OUT"; then
        warn "BLAST completed but returned no hits"
        [[ "$QUIET" != "true" ]] && echo "⚠️  No BLAST hits were found for the input query."
    else
        info "BLAST result saved to: $FINAL_OUT"

        # Mostrar resumen si está disponible
        if declare -f bb_blast_summary >/dev/null; then
            if [[ "$QUIET" == "true" ]]; then
                bb_blast_summary --input "$FINAL_OUT" --quiet
            else
                bb_blast_summary --input "$FINAL_OUT"
            fi
        else
            warn "Summary skipped: bb_blast_summary not found"
        fi
    fi

    rm -rf "$TMPDIR"
    info "Temporary files cleaned up"
}

bb_reciprocal_blast() {
    if [[ $# -eq 0 ]]; then
        echo "bb_reciprocal_blast"
        echo "Run reciprocal BLAST to identify orthologous hits between two FASTA datasets."
        echo ""
        echo "Usage:"
        echo "  bb_reciprocal_blast --query FILE --subject FILE --blast_type TYPE [--outfile PREFIX] [--min_identity PCT] [--min_coverage PCT] [--processors N] [--quiet] [--force]"
        echo ""
        echo "Options:"
        echo "  --query FILE         Query FASTA file (required)"
        echo "  --subject FILE       Subject FASTA file (required)"
        echo "  --blast_type TYPE    BLAST algorithm to use (e.g., blastn, blastp, etc.) (required)"
        echo "  --outfile PREFIX     Prefix for output files (default: based on query filename)"
        echo "  --min_identity PCT   Minimum percent identity (default: 0)"
        echo "  --min_coverage PCT   Minimum query coverage (default: 0)"
        echo "  --processors N       Number of processors for BLAST (default: 1)"
        echo "  --quiet              Suppress informational messages"
        echo "  --force              Overwrite output files if they exist"
        return 0
    fi

    if ! declare -f parse_args >/dev/null; then . ./biobash_core.sh; fi
    if ! declare -f bb_blast_on_the_fly >/dev/null; then . ./blast.sh; fi

    local QUERY=""
    local SUBJECT=""
    local BLAST_TYPE=""
    local MIN_IDENTITY=0
    local MIN_COVERAGE=0
    local OUT_PREFIX=""
    local args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --query) QUERY="$2"; shift 2 ;;
            --subject) SUBJECT="$2"; shift 2 ;;
            --blast_type) BLAST_TYPE="$2"; shift 2 ;;
            --min_identity) MIN_IDENTITY="$2"; shift 2 ;;
            --min_coverage) MIN_COVERAGE="$2"; shift 2 ;;
            --outfile) OUT_PREFIX="$2"; shift 2 ;;
            *) args+=("$1"); shift ;;
        esac
    done

    parse_args "${args[@]}"

    if [[ -z "$QUERY" || -z "$SUBJECT" || -z "$BLAST_TYPE" ]]; then
        error "Missing required arguments: --query, --subject, or --blast_type"
        return 1
    fi

    check_input "$QUERY" || return 1
    check_input "$SUBJECT" || return 1

    local BASENAME_Q BASENAME_S
    BASENAME_Q=$(get_basename "$QUERY")
    BASENAME_S=$(get_basename "$SUBJECT")
    local PREFIX="${OUT_PREFIX:-${BASENAME_Q}_${BASENAME_S}}"

    local FILE_A_VS_B="${PREFIX}.A_vs_B.blast"
    local FILE_B_VS_A="${PREFIX}.B_vs_A.blast"
    local FILE_RECIP="${PREFIX}.reciprocal.tsv"

    for f in "$FILE_A_VS_B" "$FILE_B_VS_A" "$FILE_RECIP"; do
        if ! check_file_exists "$f"; then return 1; fi
    done

    local TMPDIR
    TMPDIR=$(mktemp -d)
    [[ ! -d "$TMPDIR" ]] && { error "Failed to create temporary directory"; return 1; }

    info "Running A vs B BLAST..."
    local args_A=(--query "$QUERY" --db "$SUBJECT" --blast_type "$BLAST_TYPE" --outfile "$FILE_A_VS_B" --processors "$PROCESSORS")
    [[ "$QUIET" == "true" ]] && args_A+=("--quiet")
    [[ "$FORCE" == "true" ]] && args_A+=("--force")
    bb_blast_on_the_fly "${args_A[@]}" || { rm -rf "$TMPDIR"; return 1; }

    info "Running B vs A BLAST..."
    local args_B=(--query "$SUBJECT" --db "$QUERY" --blast_type "$BLAST_TYPE" --outfile "$FILE_B_VS_A" --processors "$PROCESSORS")
    [[ "$QUIET" == "true" ]] && args_B+=("--quiet")
    [[ "$FORCE" == "true" ]] && args_B+=("--force")
    bb_blast_on_the_fly "${args_B[@]}" || { rm -rf "$TMPDIR"; return 1; }

    local A_BEST="$TMPDIR/A_best.tsv"
    local B_BEST="$TMPDIR/B_best.tsv"
    bb_blast_best_hit --input "$FILE_A_VS_B" --outfile "$A_BEST" --quiet --force= || return 1
    bb_blast_best_hit --input "$FILE_B_VS_A" --outfile "$B_BEST" --quiet --force= || return 1

    info "Computing reciprocal best hits..."
    awk -v id="$MIN_IDENTITY" -v cov="$MIN_COVERAGE" '
        BEGIN { FS=OFS="\t" }
        FNR==NR {
            aln_len = ($8 > $7) ? $8 - $7 + 1 : $7 - $8 + 1
            cov_pct = ($13 > 0) ? (100 * aln_len / $13) : 0
            if ($3 >= id && cov_pct >= cov) best[$1] = $2
            next
        }
        {
            aln_len = ($8 > $7) ? $8 - $7 + 1 : $7 - $8 + 1
            cov_pct = ($13 > 0) ? (100 * aln_len / $13) : 0
            if ($3 >= id && cov_pct >= cov) {
                if (best[$2] == $1) print $1, $2
            }
        }
    ' "$A_BEST" "$B_BEST" > "$FILE_RECIP"

    info "Reciprocal BLAST complete."
    info "Output files:"
    info "  A vs B: $FILE_A_VS_B"
    info "  B vs A: $FILE_B_VS_A"
    info "  Reciprocal hits: $FILE_RECIP"

    rm -rf "$TMPDIR"
    return 0
}




