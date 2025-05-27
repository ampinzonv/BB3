
#!/usr/bin/env bash

. ../biobash_core.sh
. ../file.sh
. ../blast.sh

GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"
pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }

test_bb_run_blast() {
    echo "== Running final test for bb_run_blast =="

    local TMPDIR
    TMPDIR=$(mktemp -d)
    cd "$TMPDIR" || { echo "Could not enter temp directory"; return 1; }

    local query_fa="blast_query.fa"
    local db_fa="blast_db.fa"
    local db_prefix="blast_testdb"
    local outdir="blast_output"
    local outfile="${outdir}/result.blastout"

    mkdir -p "$outdir"

    cat <<EOF > "$query_fa"
>query1
ATGCGTAGCTAG
EOF

    cat <<EOF > "$db_fa"
>hit1
ATGCGTAGCTAG
>hit2
TTTTTTTTTTTT
EOF

    bb_create_blast_db --input "$db_fa" --db_name "$db_prefix" --outdir "." --force --quiet

    bb_run_blast --input "$query_fa" --db "$db_prefix" --blast_type blastn --outfile "$outfile" --force --quiet

    if [[ -s "$outfile" ]]; then
        pass "BLAST result file created with hits"
    else
        fail "BLAST output file is empty"
    fi

    echo ">nohit" > "$query_fa"
    echo "CCCCCCCCCCCC" >> "$query_fa"

    bb_run_blast --input "$query_fa" --db "$db_prefix" --blast_type blastn --outfile "$outfile" --force --quiet --strict
    if [[ $? -ne 0 && "$(cat "$outfile")" == "blast: no hits found" ]]; then
        pass "Strict mode correctly fails when no hits are found"
    else
        fail "Strict mode did not behave as expected"
    fi

    cd - >/dev/null
    rm -rf "$TMPDIR"
}

test_bb_run_blast

