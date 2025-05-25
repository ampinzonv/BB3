#!/usr/bin/env bash

. ../biobash_core.sh
. ../file.sh

GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"
pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }

test_fasta_stats_basic() {
    local infile="stats_test.fa"
    local outfile="stats_output.txt"
    local expected="expected_output.txt"

    cat <<EOF > "$infile"
>seq1
AAAAAAAAAAAAAAAAAAA
>seq2
GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
>seq3
TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
EOF

    cat <<EOF > "$expected"
STATISTIC        VALUE
---------------- ----------------
Total sequences: 3
Total length:    145
Minimum length:  19
Maximum length:  68
Average length:  48.33
N50:             58
EOF

    bb_fasta_stats --input "$infile" --outfile "$outfile" --force

    if diff "$outfile" "$expected" >/dev/null; then
        pass "Correct statistics for 3-sequence FASTA"
    else
        fail "Incorrect statistics output"
        diff "$outfile" "$expected"
    fi

    rm -f "$infile" "$outfile" "$expected"
}

echo "== Running final test for bb_fasta_stats =="
test_fasta_stats_basic
