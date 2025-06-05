
bb_plot_blast_hits_txt() {
    if [[ $# -eq 0 ]]; then
        echo "bb_plot_blast_hits_txt"
        echo "Visualize BLAST HSP alignments as scaled bars in plain text."
        echo ""
        echo "Usage:"
        echo "  bb_plot_blast_hits_txt --input FILE [--top_hits_number N] [--outfile FILE] [--quiet] [--force]"
        echo ""
        echo "Options:"
        echo "  --input FILE         BLAST outfmt 6 file with 14 columns (required)"
        echo "  --top_hits_number N  Number of top hits to visualize (by bitscore)"
        echo "  --outfile FILE       Output file (default: STDOUT)"
        echo "  --quiet              Suppress informational messages"
        echo "  --force              Overwrite output file if it exists"
        return 0
    fi

    local INPUT=""
    local OUTFILE=""
    local QUIET="false"
    local FORCE="false"
    local TOP_HITS=""
    local LINE_WIDTH=50

    local args=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --top_hits_number) TOP_HITS="$2"; shift 2 ;;
            *) args+=("$1"); shift ;;
        esac
    done

    # Load core
    if ! declare -f parse_args >/dev/null; then . ./biobash_core.sh; fi
    parse_args "${args[@]}"
    check_input "$INPUT"

    local BASENAME="STDIN"
    local infile
    if is_stdin "$INPUT"; then
        infile=$(mktemp)
        cat - > "$infile"
    else
        infile="$INPUT"
        BASENAME=$(get_basename "$INPUT")
    fi

    local ncols
    ncols=$(awk 'NF {print NF; exit}' "$infile")
    if (( ncols < 14 )); then
        error "Se requieren al menos 14 columnas en el archivo (incluyendo qlen y slen)."
        [[ "$infile" != "$INPUT" ]] && rm -f "$infile"
        return 1
    fi

    [[ "$QUIET" != "true" ]] && info "Generando gráfico de HSPs de BLAST ($BASENAME)"

    local tmp_best
    tmp_best=$(mktemp)

    if [[ -n "$TOP_HITS" ]]; then
        bb_blast_best_hit --input "$infile" | sort -k12,12nr | head -n "$TOP_HITS" > "$tmp_best"
    else
        bb_blast_best_hit --input "$infile" | sort -k12,12nr > "$tmp_best"
    fi

    local output
    output=$(awk -v width="$LINE_WIDTH" '
    {
        qid = $1
        sid = $2
        sstart = $9 + 0
        send = $10 + 0
        slen = $14 + 0

        if (sstart > send) { tmp = sstart; sstart = send; send = tmp }

        hsp_len = send - sstart + 1
        coverage = (slen > 0) ? (hsp_len / slen) * 100 : 0

        bar = ""
        for (i = 1; i <= width; i++) bar = bar "-"

        hsp_start_scaled = int((sstart / slen) * width)
        hsp_end_scaled   = int((send / slen) * width)

        if (hsp_start_scaled < 0) hsp_start_scaled = 0
        if (hsp_end_scaled >= width) hsp_end_scaled = width - 1

        prefix = substr(bar, 1, hsp_start_scaled)
        middle = ""
        for (i = hsp_start_scaled + 1; i <= hsp_end_scaled + 1; i++) middle = middle "="
        suffix = substr(bar, hsp_end_scaled + 2)
        bar = prefix middle suffix

        printf "%-15s %-25s %s  %d (%d-%d) [%.1f%%]\n", qid, sid, bar, slen, sstart, send, coverage
    }
    ' "$tmp_best")

    if [[ -n "$OUTFILE" ]]; then
        if [[ -e "$OUTFILE" && "$FORCE" != "true" ]]; then
            error "El archivo de salida '$OUTFILE' ya existe. Use --force para sobrescribir."
            rm -f "$tmp_best"
            [[ "$infile" != "$INPUT" ]] && rm -f "$infile"
            return 1
        fi
        echo "$output" > "$OUTFILE"
        [[ "$QUIET" != "true" ]] && info "Resultado guardado en: $OUTFILE"
    else
        echo "$output"
    fi

    rm -f "$tmp_best"
    [[ "$infile" != "$INPUT" ]] && rm -f "$infile"
}

bb_plot_histogram_txt() {
    if [[ $# -eq 0 ]]; then
        echo "bb_plot_histogram_txt"
        echo "Draw a horizontal histogram using two-column input (label value)."
        echo ""
        echo "Usage:"
        echo "  bb_plot_histogram_txt --input FILE [--outfile FILE] [--char SYM] [--log N] [--quiet] [--force]"
        echo ""
        echo "Options:"
        echo "  --input FILE      Input file with 2 columns or '-' for STDIN (required)"
        echo "  --outfile FILE    Output file (default: STDOUT)"
        echo "  --char SYM        Character to use for the bars (default: '=')"
        echo "  --log N           Apply log base N to values before plotting"
        echo "  --quiet           Suppress informational messages"
        echo "  --force           Overwrite output file if it exists"
        return 0
    fi

    local CHAR="="
    local QUIET="false"
    local FORCE="false"
    local LOG_BASE=""
    local INPUT=""
    local OUTFILE=""
    local args=()

    # Captura argumentos personalizados
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --char) CHAR="$2"; shift 2 ;;
            --log)  LOG_BASE="$2"; shift 2 ;;
            *) args+=("$1"); shift ;;
        esac
    done

    # Cargar funciones núcleo y parsear argumentos estándar
    if ! declare -f parse_args >/dev/null; then . ./biobash_core.sh; fi
    parse_args "${args[@]}"
    check_input "$INPUT"

    local infile
    if is_stdin "$INPUT"; then
        infile=$(mktemp)
        cat - > "$infile"
    else
        infile="$INPUT"
    fi

    [[ "$QUIET" != "true" ]] && info "Generating histogram from: $INPUT"

    local MAX_WIDTH=50
    local output
    output=$(awk -v width="$MAX_WIDTH" -v sym="$CHAR" -v logbase="$LOG_BASE" '
    function logn(x, base) {
        return log(x) / log(base)
    }
    BEGIN {
        apply_log = (logbase != "" && logbase + 0 > 0) ? 1 : 0
    }
    {
        label = $1
        value = $2 + 0

        if (apply_log) {
            if (value <= 0) {
                printf "[WARN] Skipping non-positive value (%s %s) for log\n", label, $2 > "/dev/stderr"
                next
            }
            value = logn(value, logbase)
        }

        labels[NR] = label
        values[NR] = value
        if (value > maxval) maxval = value
        count++
    }
    END {
        for (i = 1; i <= count; i++) idx[i] = i
        for (i = 1; i <= count - 1; i++) {
            for (j = i + 1; j <= count; j++) {
                if (values[idx[j]] > values[idx[i]]) {
                    tmp = idx[i]; idx[i] = idx[j]; idx[j] = tmp
                }
            }
        }

        printf "Histogram%s (max: %.2f)\n\n", (apply_log ? " [log base " logbase "]" : ""), maxval
        for (k = 1; k <= count; k++) {
            i = idx[k]
            scaled = int(values[i] / maxval * width)
            bar = ""
            for (j = 0; j < scaled; j++) bar = bar sym
            printf "%-12s | %s %6.2f\n", labels[i], bar, values[i]
        }
    }' "$infile")

    if [[ -n "$OUTFILE" ]]; then
        if [[ -e "$OUTFILE" && "$FORCE" != "true" ]]; then
            error "Output file '$OUTFILE' already exists. Use --force to overwrite."
            [[ "$infile" != "$INPUT" ]] && rm -f "$infile"
            return 1
        fi
        echo "$output" > "$OUTFILE"
        [[ "$QUIET" != "true" ]] && info "Output written to: $OUTFILE"
    else
        echo "$output"
    fi

    [[ "$infile" != "$INPUT" ]] && rm -f "$infile"
}



bb_plot_quality_distribution() {

    if [[ $# -eq 0 ]]; then
        echo "bb_plot_quality_distribution"
        echo "Plot ASCII histogram of average quality per read from a FASTQ file."
        echo ""
        echo "Usage:"
        echo "  bb_plot_quality_distribution --input FILE [--sample_size PCT] [--phred_offset N] [--outfile FILE] [--quiet] [--force]"
        echo ""
        echo "Options:"
        echo "  --input FILE       FASTQ file or '-' for STDIN (required)"
        echo "  --sample_size PCT  Percent of reads to sample randomly (optional)"
        echo "  --phred_offset N   ASCII offset for quality encoding (default: 33)"
        echo "  --outfile FILE     Output text file (default: STDOUT)"
        echo "  --quiet            Suppress messages"
        echo "  --force            Overwrite output file if it exists"
        return 0
    fi

    if ! declare -f parse_args >/dev/null; then . ./biobash_core.sh; fi

    
    local SAMPLE_SIZE="10"
    local PHRED_OFFSET="33"
    local args=()

    # Parse custom arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --sample_size) SAMPLE_SIZE="$2"; shift 2 ;;
            --phred_offset) PHRED_OFFSET="$2"; shift 2 ;;
            *) args+=("$1"); shift ;;
        esac
    done

    parse_args "${args[@]}"
    check_input "$INPUT"

    local temp_input=""
    local infile="$INPUT"

    #If sample size is not empty, subsample the input
    [[ "$QUIET" != "true" ]] && info "Using sample size: $SAMPLE_SIZE%"

    if [[ -v "$SAMPLE_SIZE" ]]; then
        temp_input=$(mktemp)
        bb_fastq_subsampling --input "$INPUT" --sample_size "$SAMPLE_SIZE" --outfile "$temp_input" --force ${QUIET:+--quiet}
        if [[ $? -ne 0 || ! -s "$temp_input" ]]; then
            error "Subsampling failed or returned empty result"
            rm -f "$temp_input"
            return 1
        fi
        infile="$temp_input"
    elif is_stdin "$INPUT"; then
        temp_input=$(mktemp)
        cat - > "$temp_input"
        infile="$temp_input"
    fi

    [[ "$QUIET" != "true" ]] && info "Calculating average quality per read..."

    local awk_output=""
    if [[ "$infile" == "-" ]]; then
        awk_output=$(cat | awk -v offset="$PHRED_OFFSET" '
        BEGIN {
            s = " !\"#$%&'\''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
            split("0-9 10-19 20-29 30-39 40-49 50-59 60-69", ranges);
            for (r in ranges) bins[ranges[r]] = 0;
            total_reads = 0;
        }
        NR % 4 == 0 {
            sum = 0;
            for (i = 1; i <= length($0); i++) {
                c = substr($0, i, 1);
                q = index(s, c) - 1;
                # Restar el offset Phred aquí
                q = q - offset;
                sum += q;
            }
            avg = sum / length($0);
            total_reads++;

            if (avg < 10)        bins["0-9"]++;
            else if (avg < 20)   bins["10-19"]++;
            else if (avg < 30)   bins["20-29"]++;
            else if (avg < 40)   bins["30-39"]++;
            else if (avg < 50)   bins["40-49"]++;
            else if (avg < 60)   bins["50-59"]++;
            else                 bins["60-69"]++;
        }
        END {
            max = 0;
            for (r in bins) if (bins[r] > max) max = bins[r];

            for (ridx = 1; ridx <= 7; ridx++) {
                r = ranges[ridx];
                count = bins[r];
                len = (max > 0 && count > 0) ? int((count / max) * 40) : 0;
                if (count > 0 && len == 0) len = 1;
                pct = (total_reads > 0) ? int((count * 100) / total_reads) : 0;
                bar = "";
                for (i = 0; i < len; i++) bar = bar "=";
                line = sprintf("%-8s | %s %d", r, bar, count);
                line = line " (" pct "%)";
                print line;
            }
        }')
    elif [[ "$infile" == *.gz ]]; then
        awk_output=$(gunzip -c "$infile" | awk -v offset="$PHRED_OFFSET" '
        BEGIN {
            s = " !\"#$%&'\''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
            split("0-9 10-19 20-29 30-39 40-49 50-59 60-69", ranges);
            for (r in ranges) bins[ranges[r]] = 0;
            total_reads = 0;
        }
        NR % 4 == 0 {
            sum = 0;
            for (i = 1; i <= length($0); i++) {
                c = substr($0, i, 1);
                q = index(s, c) - 1;
                # Restar el offset Phred aquí
                q = q - offset;
                sum += q;
            }
            avg = sum / length($0);
            total_reads++;

            if (avg < 10)        bins["0-9"]++;
            else if (avg < 20)   bins["10-19"]++;
            else if (avg < 30)   bins["20-29"]++;
            else if (avg < 40)   bins["30-39"]++;
            else if (avg < 50)   bins["40-49"]++;
            else if (avg < 60)   bins["50-59"]++;
            else                 bins["60-69"]++;
        }
        END {
            max = 0;
            for (r in bins) if (bins[r] > max) max = bins[r];

            for (ridx = 1; ridx <= 7; ridx++) {
                r = ranges[ridx];
                count = bins[r];
                len = (max > 0 && count > 0) ? int((count / max) * 40) : 0;
                if (count > 0 && len == 0) len = 1;
                pct = (total_reads > 0) ? int((count * 100) / total_reads) : 0;
                bar = "";
                for (i = 0; i < len; i++) bar = bar "=";
                line = sprintf("%-8s | %s %d", r, bar, count);
                line = line " (" pct "%)";
                print line;
            }
        }')
    else
        awk_output=$(awk -v offset="$PHRED_OFFSET" '
        BEGIN {
            s = " !\"#$%&'\''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
            split("0-9 10-19 20-29 30-39 40-49 50-59 60-69", ranges);
            for (r in ranges) bins[ranges[r]] = 0;
            total_reads = 0;
        }
        NR % 4 == 0 {
            sum = 0;
            for (i = 1; i <= length($0); i++) {
                c = substr($0, i, 1);
                q = index(s, c) - 1;
                # Restar el offset Phred aquí
                q = q - offset;
                sum += q;
            }
            avg = sum / length($0);
            total_reads++;

            if (avg < 10)        bins["0-9"]++;
            else if (avg < 20)   bins["10-19"]++;
            else if (avg < 30)   bins["20-29"]++;
            else if (avg < 40)   bins["30-39"]++;
            else if (avg < 50)   bins["40-49"]++;
            else if (avg < 60)   bins["50-59"]++;
            else                 bins["60-69"]++;
        }
        END {
            max = 0;
            for (r in bins) if (bins[r] > max) max = bins[r];

            for (ridx = 1; ridx <= 7; ridx++) {
                r = ranges[ridx];
                count = bins[r];
                len = (max > 0 && count > 0) ? int((count / max) * 40) : 0;
                if (count > 0 && len == 0) len = 1;
                pct = (total_reads > 0) ? int((count * 100) / total_reads) : 0;
                bar = "";
                for (i = 0; i < len; i++) bar = bar "=";
                line = sprintf("%-8s | %s %d", r, bar, count);
                line = line " (" pct "%)";
                print line;
            }
        }' "$infile")
    fi

    if [[ -n "$OUTFILE" ]]; then
        if ! check_file_exists "$OUTFILE"; then
            [[ -n "$temp_input" ]] && rm -f "$temp_input"
            return 1
        fi
        echo "$awk_output" > "$OUTFILE"
        [[ "$QUIET" != "true" ]] && info "Results saved to: $OUTFILE"
    else
        echo "$awk_output"
    fi

    [[ "$QUIET" != "true" ]] && info "Plot complete. Output: ${OUTFILE:-STDOUT}"
    [[ -n "$temp_input" ]] && rm -f "$temp_input"
}


# Specific awk script for quality distribution. Intended to be used internally
awk_script_quality_distribution() {
    awk '
    BEGIN {
        s = " !\"#$%&'\''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
        phred_offset = 33  # Valor estándar para FASTQ Sanger/Illumina 1.8+
        split("0-9 10-19 20-29 30-39 40-49 50-59 60-69", ranges)
        for (r in ranges) bins[ranges[r]] = 0
        total_reads = 0
    }
    NR % 4 == 0 {
        sum = 0
        for (i = 1; i <= length($0); i++) {
            c = substr($0, i, 1)
            q = index(s, c) - 1
            # Restar el offset Phred aquí
            q = q - phred_offset
            sum += q
        }
        avg = sum / length($0)
        total_reads++

        if (avg < 10)        bins["0-9"]++
        else if (avg < 20)   bins["10-19"]++
        else if (avg < 30)   bins["20-29"]++
        else if (avg < 40)   bins["30-39"]++
        else if (avg < 50)   bins["40-49"]++
        else if (avg < 60)   bins["50-59"]++
        else                 bins["60-69"]++
    }
    END {
        max = 0
        for (r in bins) if (bins[r] > max) max = bins[r]

        for (ridx = 1; ridx <= 7; ridx++) {
            r = ranges[ridx]
            count = bins[r]
            len = (max > 0 && count > 0) ? int((count / max) * 40) : 0
            if (count > 0 && len == 0) len = 1
            pct = (total_reads > 0) ? int((count * 100) / total_reads) : 0
            bar = ""
            for (i = 0; i < len; i++) bar = bar "="
            line = sprintf("%-8s | %s %d", r, bar, count)
            line = line " (" pct "%)"
            print line
        }
    }'
}


bb_plot_quality_per_base() {
    # Mostrar ayuda si no hay argumentos
    if [[ $# -eq 0 ]]; then
        echo "bb_plot_quality_per_base"
        echo "Plot ASCII histogram of average quality per base position from a FASTQ file."
        echo ""
        echo "Usage:"
        echo "  bb_plot_quality_per_base --input FILE [--sample_size PCT] [--phred_offset N] [--outfile FILE] [--quiet] [--force]"
        echo ""
        echo "Options:"
        echo "  --input FILE        FASTQ file or '-' for STDIN (required)"
        echo "  --sample_size PCT   Percent of reads to sample randomly (default: 10)"
        echo "  --phred_offset N    ASCII offset for quality encoding (default: 33)"
        echo "  --outfile FILE      Output file for histogram (default: STDOUT)"
        echo "  --quiet             Suppress messages"
        echo "  --force             Overwrite existing output file"
        return 0
    fi

    # Cargar funciones core
    if ! declare -f parse_args >/dev/null; then 
        . ./biobash_core.sh
    fi

    # Variables predeterminadas
    local SAMPLE_SIZE="10"
    local PHRED_OFFSET="33"
    local args=()
    
    # Parsear argumentos personalizados
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --sample_size) SAMPLE_SIZE="$2"; shift 2 ;;
            --phred_offset) PHRED_OFFSET="$2"; shift 2 ;;
            *) args+=("$1"); shift ;;
        esac
    done

    # Parsear argumentos estándar
    parse_args "${args[@]}"
    
    # Validar entrada
    if [[ -z "$INPUT" ]]; then
        error "Missing required --input argument"
        return 1
    fi
    check_input "$INPUT"

    # Preparar archivos temporales
    local infile="$INPUT"
    local temp_file=$(mktemp)

    # Calcular la calidad directamente con un solo comando AWK
    [[ "$QUIET" != "true" ]] && info "Calculating quality per base position..."

    # Primera fase: recopilar estadísticas de calidad de las bases en un archivo temporal
    if is_stdin "$INPUT"; then
        cat | awk -v pct="$SAMPLE_SIZE" -v offset="$PHRED_OFFSET" -v quiet="$QUIET" '
        BEGIN {
            srand();
            max_pct = pct / 100;
            phred = " !\"#$%&'\''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
            read_count = 0;
            sampled_count = 0;
        }
        
        # Solo procesar líneas de calidad (línea 4 de cada registro FASTQ)
        NR % 4 == 0 {
            read_count++;
            if (rand() <= max_pct) {  # Muestreo aleatorio
                sampled_count++;
                len = length($0);
                for (i = 1; i <= len; i++) {
                    c = substr($0, i, 1);
                    q = index(phred, c) - 1;
                    qual = q - offset;
                    pos[i] += qual;
                    count[i]++;
                }
            }
        }
        
        END {
            if (quiet != "true") 
                printf "[INFO]  Processed %d reads, sampled %d (%.1f%%)\n", read_count, sampled_count, (sampled_count/read_count)*100 > "/dev/stderr";
            
            # Crear un array con las posiciones para ordenarlas manualmente
            n = 0;
            for (i in pos) {
                sorted_keys[n] = i + 0;  # Convertir a número
                n++;
            }
            
            # Ordenar las posiciones numéricamente (algoritmo simple de burbuja)
            for (i = 0; i < n - 1; i++) {
                for (j = i + 1; j < n; j++) {
                    if (sorted_keys[i] > sorted_keys[j]) {
                        temp = sorted_keys[i];
                        sorted_keys[i] = sorted_keys[j];
                        sorted_keys[j] = temp;
                    }
                }
            }
            
            # Almacenar posición y calidad promedio
            for (idx = 0; idx < n; idx++) {
                i = sorted_keys[idx];
                if (count[i] > 0) {
                    qual = pos[i] / count[i];
                    printf "%d\t%.2f\n", i, qual;
                }
            }
        }' > "$temp_file"
    elif [[ "$infile" == *.gz ]]; then
        gunzip -c "$infile" | awk -v pct="$SAMPLE_SIZE" -v offset="$PHRED_OFFSET" -v quiet="$QUIET" '
        BEGIN {
            srand();
            max_pct = pct / 100;
            phred = " !\"#$%&'\''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
            read_count = 0;
            sampled_count = 0;
        }
        
        # Solo procesar líneas de calidad (línea 4 de cada registro FASTQ)
        NR % 4 == 0 {
            read_count++;
            if (rand() <= max_pct) {  # Muestreo aleatorio
                sampled_count++;
                len = length($0);
                for (i = 1; i <= len; i++) {
                    c = substr($0, i, 1);
                    q = index(phred, c) - 1;
                    qual = q - offset;
                    pos[i] += qual;
                    count[i]++;
                }
            }
        }
        
        END {
            if (quiet != "true") 
                printf "[INFO]  Processed %d reads, sampled %d (%.1f%%)\n", read_count, sampled_count, (sampled_count/read_count)*100 > "/dev/stderr";
            
            # Crear un array con las posiciones para ordenarlas manualmente
            n = 0;
            for (i in pos) {
                sorted_keys[n] = i + 0;  # Convertir a número
                n++;
            }
            
            # Ordenar las posiciones numéricamente (algoritmo simple de burbuja)
            for (i = 0; i < n - 1; i++) {
                for (j = i + 1; j < n; j++) {
                    if (sorted_keys[i] > sorted_keys[j]) {
                        temp = sorted_keys[i];
                        sorted_keys[i] = sorted_keys[j];
                        sorted_keys[j] = temp;
                    }
                }
            }
            
            # Almacenar posición y calidad promedio
            for (idx = 0; idx < n; idx++) {
                i = sorted_keys[idx];
                if (count[i] > 0) {
                    qual = pos[i] / count[i];
                    printf "%d\t%.2f\n", i, qual;
                }
            }
        }' > "$temp_file"
    else
        awk -v pct="$SAMPLE_SIZE" -v offset="$PHRED_OFFSET" -v quiet="$QUIET" '
        BEGIN {
            srand();
            max_pct = pct / 100;
            phred = " !\"#$%&'\''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
            read_count = 0;
            sampled_count = 0;
        }
        
        # Solo procesar líneas de calidad (línea 4 de cada registro FASTQ)
        NR % 4 == 0 {
            read_count++;
            if (rand() <= max_pct) {  # Muestreo aleatorio
                sampled_count++;
                len = length($0);
                for (i = 1; i <= len; i++) {
                    c = substr($0, i, 1);
                    q = index(phred, c) - 1;
                    qual = q - offset;
                    pos[i] += qual;
                    count[i]++;
                }
            }
        }
        
        END {
            if (quiet != "true") 
                printf "[INFO]  Processed %d reads, sampled %d (%.1f%%)\n", read_count, sampled_count, (sampled_count/read_count)*100 > "/dev/stderr";
            
            # Crear un array con las posiciones para ordenarlas manualmente
            n = 0;
            for (i in pos) {
                sorted_keys[n] = i + 0;  # Convertir a número
                n++;
            }
            
            # Ordenar las posiciones numéricamente (algoritmo simple de burbuja)
            for (i = 0; i < n - 1; i++) {
                for (j = i + 1; j < n; j++) {
                    if (sorted_keys[i] > sorted_keys[j]) {
                        temp = sorted_keys[i];
                        sorted_keys[i] = sorted_keys[j];
                        sorted_keys[j] = temp;
                    }
                }
            }
            
            # Almacenar posición y calidad promedio
            for (idx = 0; idx < n; idx++) {
                i = sorted_keys[idx];
                if (count[i] > 0) {
                    qual = pos[i] / count[i];
                    printf "%d\t%.2f\n", i, qual;
                }
            }
        }' "$infile" > "$temp_file"
    fi

    # Segunda fase: Generar el diagrama vertical
    local output=""
    
    # 1. Calcular el mínimo y máximo valor de calidad y posiciones
    local stats=$(awk '
    BEGIN {
        min_qual = 1000; max_qual = -1000;
        min_pos = 1000000; max_pos = -1;
    }
    {
        pos = $1; qual = $2;
        if (qual < min_qual) min_qual = qual;
        if (qual > max_qual) max_qual = qual;
        if (pos < min_pos) min_pos = pos;
        if (pos > max_pos) max_pos = pos;
    }
    END {
        printf "%d %d %.2f %.2f", min_pos, max_pos, min_qual, max_qual;
    }' "$temp_file")
    
    local min_pos=$(echo $stats | cut -d ' ' -f1)
    local max_pos=$(echo $stats | cut -d ' ' -f2)
    local min_qual=$(echo $stats | cut -d ' ' -f3)
    local max_qual=$(echo $stats | cut -d ' ' -f4)
    
    # 2. Generar el diagrama vertical
    local height=20  # Altura máxima del histograma
    
    output=$(awk -v min_qual="$min_qual" -v max_qual="$max_qual" -v height="$height" -v min_pos="$min_pos" -v max_pos="$max_pos" '
    function pos_to_idx(pos) {
        return pos - min_pos;
    }
    
    function qual_to_row(qual) {
        return height - int(((qual - min_qual) / (max_qual - min_qual)) * height);
    }
    
    BEGIN {
        # Inicializar matriz para el gráfico
        for (row = 0; row <= height; row++) {
            for (pos = min_pos; pos <= max_pos; pos++) {
                chart[row, pos] = " ";
            }
        }
        
        # Inicializar array de valores de calidad
        for (pos = min_pos; pos <= max_pos; pos++) {
            qual_values[pos] = 0;
        }
    }
    
    # Leer valores de calidad
    {
        pos = $1;
        qual = $2;
        qual_values[pos] = qual;
        
        # Calcular la fila para este valor de calidad
        row = qual_to_row(qual);
        
        # Colocar un marcador en esa posición
        chart[row, pos] = "*";
        
        # Llenar columnas con "|"
        for (r = row + 1; r <= height; r++) {
            chart[r, pos] = "|";
        }
    }
    
    END {
        # Imprimir encabezado con valores de calidad
        printf "Calidad\n";
        
        # Imprimir escala de calidad en el eje Y
        qual_step = (max_qual - min_qual) / 4;
        for (i = 0; i <= 4; i++) {
            row = qual_to_row(min_qual + i * qual_step);
            qual_label[row] = sprintf("%.1f", min_qual + i * qual_step);
        }
        
        # Imprimir el gráfico fila por fila
        for (row = 0; row <= height; row++) {
            if (row in qual_label) {
                printf "%-5s ", qual_label[row];
            } else {
                printf "      ";
            }
            
            for (pos = min_pos; pos <= max_pos; pos++) {
                printf "%s", chart[row, pos];
            }
            printf "\n";
        }
        
        # Imprimir línea base del eje X
        printf "      ";
        for (pos = min_pos; pos <= max_pos; pos++) {
            printf "-";
        }
        printf "\n";
        
        # Imprimir posiciones en el eje X (cada 10 posiciones)
        printf "      ";
        for (pos = min_pos; pos <= max_pos; pos++) {
            if (pos % 10 == 0) {
                str = "" pos;
                printf "%s", substr(str, 1, 1);
            } else {
                printf " ";
            }
        }
        printf "\n";
        
        # Segunda fila para posiciones de dos dígitos
        printf "      ";
        for (pos = min_pos; pos <= max_pos; pos++) {
            if (pos % 10 == 0 && pos >= 10) {
                str = "" pos;
                printf "%s", substr(str, 2, 1);
            } else {
                printf " ";
            }
        }
        printf "\n";
        
        # Tercera fila para posiciones de tres dígitos
        printf "      ";
        for (pos = min_pos; pos <= max_pos; pos++) {
            if (pos % 10 == 0 && pos >= 100) {
                str = "" pos;
                printf "%s", substr(str, 3, 1);
            } else {
                printf " ";
            }
        }
        printf "\nPosición\n";
    }' "$temp_file")
    
    # Mostrar resultado o guardar en archivo
    if [[ -n "$OUTFILE" ]]; then
        if [[ -e "$OUTFILE" && "$FORCE" != "true" ]]; then
            error "Output file '$OUTFILE' already exists. Use --force to overwrite."
            rm -f "$temp_file"
            return 1
        fi
        echo "$output" > "$OUTFILE"
        [[ "$QUIET" != "true" ]] && info "Results saved to: $OUTFILE"
    else
        echo "$output"
    fi

    [[ "$QUIET" != "true" ]] && info "Plot complete. Output: ${OUTFILE:-STDOUT}"
    
    # Limpieza
    rm -f "$temp_file"
    
    return 0
}














