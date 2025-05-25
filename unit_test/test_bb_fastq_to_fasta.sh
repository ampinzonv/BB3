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
# TEST: conversion from file
##########################
test_fastq_to_fasta_from_file() {
    local infile="test_reads.fastq"
    local expected="expected.fasta"
    local output="out.fasta"

    echo -e "@r1\nACGT\n+\n!!!!\n@r2\nTGCA\n+\n!!!!" > "$infile"
    echo -e ">r1\nACGT\n>r2\nTGCA" > "$expected"

    bb_fastq_to_fasta --input "$infile" > "$output"

    if diff "$output" "$expected" >/dev/null; then
        pass "bb_fastq_to_fasta converts from file"
    else
        fail "Conversion from file incorrect"
        diff "$output" "$expected"
    fi

    rm -f "$infile" "$expected" "$output"
}

##########################
# TEST: conversion from STDIN
##########################
test_fastq_to_fasta_from_stdin() {
    local expected="expected_stdin.fasta"
    local output="out_stdin.fasta"

    echo -e ">s1\nATTT\n>s2\nGGGA" > "$expected"

    echo -e "@s1\nATTT\n+\n!!!!\n@s2\nGGGA\n+\n!!!!" | bb_fastq_to_fasta --input - > "$output"

    if diff "$output" "$expected" >/dev/null; then
        pass "bb_fastq_to_fasta works with STDIN"
    else
        fail "Conversion from STDIN incorrect"
        diff "$output" "$expected"
    fi

    rm -f "$expected" "$output"
}

##########################
# TEST: output to file
##########################
test_fastq_to_fasta_outfile() {
    local infile="file_reads.fastq"
    local outfile="converted.fasta"
    local expected="expected_outfile.fasta"

    echo -e "@x1\nAAA\n+\n+++\n@x2\nCCC\n+\n+++" > "$infile"
    echo -e ">x1\nAAA\n>x2\nCCC" > "$expected"

    bb_fastq_to_fasta --input "$infile" --outfile "$outfile"

    if diff "$outfile" "$expected" >/dev/null; then
        pass "bb_fastq_to_fasta writes to outfile"
    else
        fail "Incorrect outfile content"
        diff "$outfile" "$expected"
    fi

    rm -f "$infile" "$outfile" "$expected"
}

##########################
# TEST: force overwrite
##########################
test_fastq_to_fasta_force_overwrite() {
    local infile="force_input.fastq"
    local outfile="force_output.fa"
    local expected="expected_force.fa"

    echo -e "@f1\nGGG\n+\n+++\n@f2\nTTT\n+\n+++" > "$infile"
    echo -e ">f1\nGGG\n>f2\nTTT" > "$expected"
    echo "old content" > "$outfile"

    bb_fastq_to_fasta --input "$infile" --outfile "$outfile" --force

    if diff "$outfile" "$expected" >/dev/null; then
        pass "bb_fastq_to_fasta overwrites with --force"
    else
        fail "Incorrect output after --force"
        diff "$outfile" "$expected"
    fi

    rm -f "$infile" "$outfile" "$expected"
}

##########################
# Run tests
##########################
echo "== Running tests for bb_fastq_to_fasta =="
test_fastq_to_fasta_from_file
test_fastq_to_fasta_from_stdin
test_fastq_to_fasta_outfile
test_fastq_to_fasta_force_overwrite
