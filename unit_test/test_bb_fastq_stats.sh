#!/usr/bin/env bash

. ../biobash_core.sh
. ../file.sh

GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"
pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }

test_fastq_stats_equivalence() {
    local plain="../testdata/sample.fq"
    local gz="../testdata/sample.fq.gz"

    local out_plain="out_plain.txt"
    local out_gz="out_gz.txt"

    # Comprimir el archivo si no existe la versión gz
    if [[ ! -f "$gz" ]]; then
        gzip -c "$plain" > "$gz"
    fi

    bb_fastq_stats --input "$plain" --outfile "$out_plain" --force --quiet
    bb_fastq_stats --input "$gz" --outfile "$out_gz" --force --quiet

    awk 'NR==2 {for(i=2;i<=8;i++) printf $i (i<8?" ":"\n")}' "$out_plain" > col_plain.tmp
    awk 'NR==2 {for(i=2;i<=8;i++) printf $i (i<8?" ":"\n")}' "$out_gz" > col_gz.tmp

    if diff col_plain.tmp col_gz.tmp >/dev/null; then

        pass "Compressed and uncompressed FASTQ yield identical stats"
    else
        fail "Stats differ between .fq and .fq.gz"
        diff "$out_plain" "$out_gz"
    fi

    rm -f "$out_plain" "$out_gz"
}

echo "== Running test for bb_fastq_stats with .fq and .fq.gz =="
test_fastq_stats_equivalence
