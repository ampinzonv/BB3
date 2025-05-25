#!/usr/bin/env bash

# Load BIOBASH core and the function
. ../biobash_core.sh
. ../file.sh

GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"
pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }

##########################
# TEST: extract from file
##########################
test_fasta_entry_from_file() {
    local infile="entries.fa"
    local expected="expected_entry.fa"
    local output="out_entry.fa"

    echo -e ">s1 desc\nATGC\n>s2 comment\nCGTA" > "$infile"
    echo -e ">s2 comment\nCGTA" > "$expected"

    bb_get_fasta_entry --input "$infile" --entry s2 > "$output"

    if diff "$output" "$expected" >/dev/null; then
        pass "bb_get_fasta_entry extracts entry from file"
    else
        fail "Incorrect entry from file"
        diff "$output" "$expected"
    fi

    rm -f "$infile" "$expected" "$output"
}

##########################
# TEST: extract from STDIN
##########################
test_fasta_entry_from_stdin() {
    local expected="expected_stdin.fa"
    local output="out_stdin.fa"

    echo -e ">x\nAAA\n>y\nTTT" > expected_stdin.fa
    echo -e ">y\nTTT" > "$expected"

    cat expected_stdin.fa | bb_get_fasta_entry --input - --entry y > "$output"

    if diff "$output" "$expected" >/dev/null; then
        pass "bb_get_fasta_entry works with STDIN"
    else
        fail "Incorrect entry from STDIN"
        diff "$output" "$expected"
    fi

    rm -f expected_stdin.fa "$expected" "$output"
}

##########################
# TEST: write to output file
##########################
test_fasta_entry_outfile() {
    local infile="entry_output.fa"
    local outfile="extracted.fa"
    local expected="expected_outfile.fa"

    echo -e ">z\nGGG" > "$infile"
    echo -e ">z\nGGG" > "$expected"

    bb_get_fasta_entry --input "$infile" --entry z --outfile "$outfile"

    if diff "$outfile" "$expected" >/dev/null; then
        pass "bb_get_fasta_entry writes to outfile"
    else
        fail "Incorrect content in outfile"
        diff "$outfile" "$expected"
    fi

    rm -f "$infile" "$outfile" "$expected"
}

##########################
# TEST: force overwrite
##########################
test_fasta_entry_force_overwrite() {
    local infile="force_entry.fa"
    local outfile="overwrite.fa"
    local expected="expected_force.fa"

    echo -e ">a\nNNN" > "$infile"
    echo -e ">a\nNNN" > "$expected"
    echo "existing" > "$outfile"

    bb_get_fasta_entry --input "$infile" --entry a --outfile "$outfile" --force

    if diff "$outfile" "$expected" >/dev/null; then
        pass "bb_get_fasta_entry overwrites with --force"
    else
        fail "Overwrite with --force failed"
        diff "$outfile" "$expected"
    fi

    rm -f "$infile" "$outfile" "$expected"
}

##########################
# TEST: entry not found
##########################
test_fasta_entry_not_found() {
    local infile="missing.fa"
    local output="notfound.fa"
    local stderr_log="stderr.log"

    echo -e ">id1\nAAACCC\n>id2\nGGG" > "$infile"

    bb_get_fasta_entry --input "$infile" --entry nonexistent > "$output" 2> "$stderr_log"

    if [[ ! -s "$output" && $(grep -c "\[WARN\] Entry ID" "$stderr_log") -gt 0 ]]; then
        pass "bb_get_fasta_entry warns if ID is not found and output is empty"
    else
        fail "bb_get_fasta_entry did not warn or returned unexpected output"
        cat "$stderr_log"
        cat "$output"
    fi

    rm -f "$infile" "$output" "$stderr_log"
}


##########################
# Run all tests
##########################
echo "== Running tests for bb_get_fasta_entry =="
test_fasta_entry_from_file
test_fasta_entry_from_stdin
test_fasta_entry_outfile
test_fasta_entry_force_overwrite
test_fasta_entry_not_found
