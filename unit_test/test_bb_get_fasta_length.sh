#!/usr/bin/env bash

# Load BIOBASH core and function
. ../biobash_core.sh
. ../file.sh

GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"
pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }

##########################
# TEST: lengths from file
##########################
test_fasta_length_from_file() {
    local infile="test_len.fa"
    local expected="expected_len.txt"
    local output="output_len.txt"

    echo -e ">seq1\nATGC\n>seq2\nCCGTAA" > "$infile"
    echo -e "seq1\t4\nseq2\t6" > "$expected"

    bb_get_fasta_length --input "$infile" > "$output"

    if diff "$output" "$expected" >/dev/null; then
        pass "bb_get_fasta_length computes lengths from file"
    else
        fail "Incorrect output from file"
        diff "$output" "$expected"
    fi

    rm -f "$infile" "$expected" "$output"
}

##########################
# TEST: lengths from STDIN
##########################
test_fasta_length_from_stdin() {
    local expected="expected_stdin.txt"
    local output="output_stdin.txt"

    echo -e "s1\t3\ns2\t5" > "$expected"

    echo -e ">s1\nAAA\n>s2\nGGGTT" | bb_get_fasta_length --input - > "$output"

    if diff "$output" "$expected" >/dev/null; then
        pass "bb_get_fasta_length works with STDIN"
    else
        fail "Incorrect output from STDIN"
        diff "$output" "$expected"
    fi

    rm -f "$expected" "$output"
}

##########################
# TEST: output to file
##########################
test_fasta_length_outfile() {
    local infile="inlen.fa"
    local outfile="outlen.tsv"
    local expected="expected_out.txt"

    echo -e ">x1\nAAA\n>x2\nCCCC" > "$infile"
    echo -e "x1\t3\nx2\t4" > "$expected"

    bb_get_fasta_length --input "$infile" --outfile "$outfile"

    if diff "$outfile" "$expected" >/dev/null; then
        pass "bb_get_fasta_length writes to outfile"
    else
        fail "Incorrect outfile content"
        diff "$outfile" "$expected"
    fi

    rm -f "$infile" "$outfile" "$expected"
}

##########################
# TEST: force overwrite
##########################
test_fasta_length_force_overwrite() {
    local infile="fasta_force.fa"
    local outfile="force_out.tsv"
    local expected="expected_force.txt"

    echo -e ">id1\nAA\n>id2\nGGGG" > "$infile"
    echo -e "id1\t2\nid2\t4" > "$expected"
    echo "preexisting" > "$outfile"

    bb_get_fasta_length --input "$infile" --outfile "$outfile" --force

    if diff "$outfile" "$expected" >/dev/null; then
        pass "bb_get_fasta_length overwrites with --force"
    else
        fail "Incorrect output after --force"
        diff "$outfile" "$expected"
    fi

    rm -f "$infile" "$outfile" "$expected"
}

##########################
# Run tests
##########################
echo "== Running tests for bb_get_fasta_length =="
test_fasta_length_from_file
test_fasta_length_from_stdin
test_fasta_length_outfile
test_fasta_length_force_overwrite
