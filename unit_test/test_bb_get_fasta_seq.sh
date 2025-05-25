#!/usr/bin/env bash

# Load BIOBASH core and function definitions
. ../biobash_core.sh
. ../file.sh

GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"
pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }

##########################
# TEST: extract sequences from file
##########################
test_fasta_seq_from_file() {
    local infile="test_seq.fa"
    local expected="expected_seq.txt"
    local output="output_seq.txt"

    echo -e ">seq1\nATGC\n>seq2\nCGTA" > "$infile"
    echo -e "ATGC\nCGTA" > "$expected"

    bb_get_fasta_seq --input "$infile" > "$output"

    if diff "$output" "$expected" >/dev/null; then
        pass "bb_get_fasta_seq extracts sequences from file"
    else
        fail "Incorrect sequences from file"
        diff "$output" "$expected"
    fi

    rm -f "$infile" "$expected" "$output"
}

##########################
# TEST: extract sequences from STDIN
##########################
test_fasta_seq_from_stdin() {
    local expected="expected_stdin.txt"
    local output="output_stdin.txt"

    echo -e "ATTT\nGGG" > "$expected"

    echo -e ">a1\nATTT\n>b2\nGGG" | bb_get_fasta_seq --input - > "$output"

    if diff "$output" "$expected" >/dev/null; then
        pass "bb_get_fasta_seq works with STDIN"
    else
        fail "Incorrect sequences from STDIN"
        diff "$output" "$expected"
    fi

    rm -f "$expected" "$output"
}

##########################
# TEST: write to output file
##########################
test_fasta_seq_outfile() {
    local infile="infile.fa"
    local outfile="out_seqs.txt"
    local expected="expected.txt"

    echo -e ">s1\nAAA\n>s2\nCCC" > "$infile"
    echo -e "AAA\nCCC" > "$expected"

    bb_get_fasta_seq --input "$infile" --outfile "$outfile"

    if diff "$outfile" "$expected" >/dev/null; then
        pass "bb_get_fasta_seq writes to outfile"
    else
        fail "Incorrect output file content"
        diff "$outfile" "$expected"
    fi

    rm -f "$infile" "$outfile" "$expected"
}

##########################
# TEST: force overwrite
##########################
test_fasta_seq_force_overwrite() {
    local infile="data.fa"
    local outfile="out_force.fa"
    local expected="expected_force.txt"

    echo -e ">id1\nNNN\n>id2\nTTT" > "$infile"
    echo -e "NNN\nTTT" > "$expected"
    echo "old content" > "$outfile"

    bb_get_fasta_seq --input "$infile" --outfile "$outfile" --force

    if diff "$outfile" "$expected" >/dev/null; then
        pass "bb_get_fasta_seq overwrites with --force"
    else
        fail "Incorrect output after --force"
        diff "$outfile" "$expected"
    fi

    rm -f "$infile" "$outfile" "$expected"
}

##########################
# Run all tests
##########################
echo "== Running tests for bb_get_fasta_seq =="
test_fasta_seq_from_file
test_fasta_seq_from_stdin
test_fasta_seq_outfile
test_fasta_seq_force_overwrite
