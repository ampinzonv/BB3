#!/usr/bin/env bash

# Load function and core
. ../biobash_core.sh
. ../file.sh

GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"
pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }

##########################
# TEST: basic file input
##########################
test_fasta_header_from_file() {
    local testfile="test_header.fa"
    echo -e ">seq1 desc\nATGC\n>seq2 something\nCGTA" > "$testfile"
    local output
    output=$(bb_get_fasta_header --input "$testfile")

    if [[ "$output" == $'>seq1 desc\n>seq2 something' || "$output" == $'>seq1 desc
>seq2 something' ]]; then
        pass "bb_get_fasta_header extracts headers from file"
    else
        fail "Incorrect headers from file"
        echo "$output"
    fi
    rm -f "$testfile"
}

##########################
# TEST: STDIN input
##########################
test_fasta_header_from_stdin() {
    local output
    output=$(echo -e ">seqA\nAAA\n>seqB\nCCC" | bb_get_fasta_header --input -)

    if [[ "$output" == $'>seqA\n>seqB' || "$output" == $'>seqA
>seqB' ]]; then
        pass "bb_get_fasta_header works with STDIN"
    else
        fail "Incorrect headers from STDIN"
        echo "$output"
    fi
}

##########################
# TEST: output to file
##########################
test_fasta_header_outfile() {
    local infile="input.fa"
    local outfile="headers.fa"
    echo -e ">X\nTTT\n>Y\nGGG" > "$infile"

    if bb_get_fasta_header --input "$infile" --outfile "$outfile"; then
        if [[ -f "$outfile" && "$(cat "$outfile")" == $'>X\n>Y' || "$(cat "$outfile")" == $'>X
>Y' ]]; then
            pass "bb_get_fasta_header writes to outfile"
        else
            fail "Output file content is incorrect"
        fi
    else
        fail "Function failed to write to outfile"
    fi

    rm -f "$infile" "$outfile"
}

##########################
# TEST: force overwrite
##########################
test_fasta_header_force_overwrite() {
    local infile="in.fa"
    local outfile="headers.fa"
    echo -e ">A\nAAA\n>B\nBBB" > "$infile"
    echo "existing" > "$outfile"

    if bb_get_fasta_header --input "$infile" --outfile "$outfile" --force; then
        if [[ "$(grep '^>' "$outfile")" == $'>A
>B' || "$(grep '^>' "$outfile")" == $'>A\n>B' ]]; then
            pass "bb_get_fasta_header overwrites with --force"
        else
            fail "Content incorrect after --force overwrite"
        fi
    else
        fail "Function failed with --force"
    fi

    rm -f "$infile" "$outfile"
}

##########################
# Run tests
##########################
echo "== Running tests for bb_get_fasta_header =="
test_fasta_header_from_file
test_fasta_header_from_stdin
test_fasta_header_outfile
test_fasta_header_force_overwrite
