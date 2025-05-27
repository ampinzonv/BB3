#!/usr/bin/env bash

. ../biobash_core.sh
. ../blast.sh
. ../file.sh


GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"
pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }

test_bb_create_blast_db_basic() {
    local infile="test_input.fasta"
    local outdir="blastdb_test"
    local dbprefix="myblastdb"

    mkdir -p "$outdir"

    cat <<EOF > "$infile"
>seq1
ATGCGTAGCTAGTCA
>seq2
GGCATGCGTACGTAG
EOF

    # Ejecutar con --force para evitar errores por archivos existentes
    bb_create_blast_db --input "$infile" --outdir "$outdir" --db_name "$dbprefix" --title "TestBLAST" --force

    if [[ -f "$outdir/${dbprefix}.nsq" || -f "$outdir/${dbprefix}.psq" ]]; then
        pass "BLAST database created successfully"
    else
        fail "BLAST database files not found"
        ls -l "$outdir"
    fi

    rm -f "$infile"
    rm -rf "$outdir"
}

echo "== Running final test for bb_create_blast_db =="
test_bb_create_blast_db_basic

