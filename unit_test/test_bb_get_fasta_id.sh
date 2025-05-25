#!/usr/bin/env bash

# Load BIOBASH core and the function file
. ../biobash_core.sh
. ../file.sh

GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"
pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }

##########################
# TEST: extract IDs from file
##########################
test_fasta_id_from_file() {
    local infile="test_id.fa"
    local outfile="output.txt"
    local expected="expected.txt"

    echo -e ">seq1 description\nATGC\n>seq2 something\nCGTA" > "$infile"
    echo -e "seq1\nseq2" > "$expected"

    bb_get_fasta_id --input "$infile" > "$outfile"

    if diff "$outfile" "$expected" >/dev/null; then
        pass "bb_get_fasta_id extracts IDs from file"
    else
        fail "Incorrect IDs from file"
        diff "$outfile" "$expected"
    fi

    rm -f "$infile" "$outfile" "$expected"
}




##########################
# TEST: extract IDs from STDIN
##########################
test_fasta_id_from_stdin() {
    local outfile="output_stdin.txt"
    local expected="expected_stdin.txt"

    echo -e "a1\nb2" > "$expected"

    echo -e ">a1 comment\nTTT\n>b2\nAAA" | bb_get_fasta_id --input - > "$outfile"

    if diff "$outfile" "$expected" >/dev/null; then
        pass "bb_get_fasta_id works with STDIN"
    else
        fail "Incorrect IDs from STDIN"
        diff "$outfile" "$expected"
    fi

    rm -f "$outfile" "$expected"
}




##########################
# TEST: write to output file
##########################
test_fasta_id_outfile() {
    local infile="input.fa"
    local outfile="ids.txt"
    echo -e ">X1\nNNN\n>Y2\nCCC" > "$infile"

    if bb_get_fasta_id --input "$infile" --outfile "$outfile"; then
        if [[ -f "$outfile" && "$(cat "$outfile")" == $'X1\nY2' ]]; then
            pass "bb_get_fasta_id writes to outfile"
        else
            fail "Incorrect content in outfile"
        fi
    else
        fail "Function failed to write to outfile"
    fi

    rm -f "$infile" "$outfile"
}

##########################
# TEST: force overwrite
##########################
test_fasta_id_force_overwrite() {
    local infile="input2.fa"
    local outfile="ids_force.txt"
    echo -e ">A1\nGGG\n>B2\nTTT" > "$infile"
    echo "existing" > "$outfile"

    if bb_get_fasta_id --input "$infile" --outfile "$outfile" --force; then
        if [[ "$(cat "$outfile")" == $'A1\nB2' ]]; then
            pass "bb_get_fasta_id overwrites with --force"
        else
            fail "Incorrect overwrite content"
        fi
    else
        fail "Function failed with --force"
    fi

    rm -f "$infile" "$outfile"
}

##########################
# Run tests
##########################
echo "== Running tests for bb_get_fasta_id =="
test_fasta_id_from_file
test_fasta_id_from_stdin
test_fasta_id_outfile
test_fasta_id_force_overwrite
