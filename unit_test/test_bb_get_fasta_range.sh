#!/usr/bin/env bash

. ../biobash_core.sh
. ../file.sh

GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"
pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }

test_id_found() {
    local infile="test_range.fa"
    local expected="expected_range.fa"
    local output="out_range.fa"

    echo -e ">gene1\nACTGACTGACTGACTGACTG" > "$infile"
    echo -e ">gene1\nACTGA" > "$expected"

    bb_get_fasta_range --input "$infile" --entry gene1 --start 5 --end 9 > "$output"

    if diff "$output" "$expected" >/dev/null; then
        pass "Extracts correct range from valid ID"
    else
        fail "Incorrect range extracted"
        diff "$output" "$expected"
    fi

    rm -f "$infile" "$expected" "$output"
}

test_id_not_found() {
    local infile="test_notfound.fa"
    local output="out_notfound.fa"
    local log="stderr_notfound.log"

    echo -e ">geneX\nACGTACGTACGT" > "$infile"

    bb_get_fasta_range --input "$infile" --entry missing --start 1 --end 5 > "$output" 2> "$log"

    if grep -q "\[WARN\] Entry ID \"missing\" not found." "$log"; then
        pass "Warns when ID is not found"
    else
        fail "Missing ID warning not shown"
        cat "$log"
    fi

    rm -f "$infile" "$output" "$log"
}

test_range_exceeds_length() {
    local infile="test_rangelimit.fa"
    local log="stderr_rangelimit.log"

    echo -e ">geneZ\nAAAAAA" > "$infile"

    bb_get_fasta_range --input "$infile" --entry geneZ --start 3 --end 20 2> "$log"

    if grep -q "\[WARN\] End position exceeds sequence length." "$log"; then
        pass "Warns when range exceeds sequence length"
    else
        fail "No warning for excessive range"
        cat "$log"
    fi

    rm -f "$infile" "$log"
}

test_stdin_input() {
    local expected=">x\nCTGA"
    echo -e ">x\nAACTGACT\n>y\nGGGG" | bb_get_fasta_range --input - --entry x --start 3 --end 6 > out_stdin.tmp
    echo -e "$expected" > expected_stdin.tmp

    if diff out_stdin.tmp expected_stdin.tmp >/dev/null; then
        pass "Handles input from STDIN"
    else
        fail "STDIN input failed"
        diff out_stdin.tmp expected_stdin.tmp
    fi

    rm -f out_stdin.tmp expected_stdin.tmp
}

test_auto_detect_id() {
    local infile="oneseq.fa"
    local expected=">seqonly\nGTACC"
    echo -e ">seqonly\nAACCGGTACCGTACCGT" > "$infile"

    bb_get_fasta_range --input "$infile" --start 6 --end 10 > result_autodetect.tmp
    echo -e "$expected" > expected_autodetect.tmp

    if diff result_autodetect.tmp expected_autodetect.tmp >/dev/null; then
        pass "Auto-detects ID when only one sequence is present"
    else
        fail "Auto-detection of single ID failed"
        echo "Got:"
        diff result_autodetect.tmp expected_autodetect.tmp
    fi

    rm -f "$infile" result_autodetect.tmp expected_autodetect.tmp
}

echo "== Running corrected tests for bb_get_fasta_range =="
test_id_found
test_id_not_found
test_range_exceeds_length
test_stdin_input
test_auto_detect_id

