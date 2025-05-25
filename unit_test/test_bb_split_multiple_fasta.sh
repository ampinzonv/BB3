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
# TEST: from file input
##########################
test_split_from_file() {
    local infile="multi.fa"
    local outdir="split_test_file"

    echo -e ">s1\nAAA\n>s2\nCCC" > "$infile"
    rm -rf "$outdir"
    mkdir -p "$outdir"

    bb_split_multiple_fasta --input "$infile" --outdir "$outdir"

    if [[ -f "$outdir/s1.fasta" && -f "$outdir/s2.fasta" ]]; then
        pass "Split from file input works"
    else
        fail "Output files missing from file input"
    fi

    rm -rf "$infile" "$outdir"
}

##########################
# TEST: from STDIN
##########################
test_split_from_stdin() {
    local outdir="split_test_stdin"
    rm -rf "$outdir"
    mkdir -p "$outdir"

    echo -e ">a\nTTT\n>b\nGGG" | bb_split_multiple_fasta --input - --outdir "$outdir"

    if [[ -f "$outdir/a.fasta" && -f "$outdir/b.fasta" ]]; then
        pass "Split from STDIN works"
    else
        fail "Output files missing from STDIN"
    fi

    rm -rf "$outdir"
}

##########################
# TEST: force overwrite
##########################
test_split_force_overwrite() {
    local infile="force.fa"
    local outdir="split_force"

    echo -e ">x\nAAA\n>y\nCCC" > "$infile"
    mkdir -p "$outdir"
    echo "preexisting" > "$outdir/x.fasta"

    bb_split_multiple_fasta --input "$infile" --outdir "$outdir" --force

    if grep -q "AAA" "$outdir/x.fasta" && grep -q "CCC" "$outdir/y.fasta"; then
        pass "Force overwrite works"
    else
        fail "Force overwrite failed"
    fi

    rm -rf "$infile" "$outdir"
}

##########################
# TEST: reject conflict with existing file
##########################
test_reject_file_named_as_outdir() {
    local infile="conflict.fa"
    local conflict="conflict_dir"
    echo -e ">z1\nNNN" > "$infile"
    echo "I am a file" > "$conflict"

    if bb_split_multiple_fasta --input "$infile" --outdir "$conflict" 2>/dev/null; then
        fail "Should fail when outdir is a file"
    else
        pass "Fails as expected when outdir is a file"
    fi

    rm -f "$infile" "$conflict"
}

##########################
# Run all tests
##########################
echo "== Running tests for bb_split_multiple_fasta =="
test_split_from_file
test_split_from_stdin
test_split_force_overwrite
test_reject_file_named_as_outdir
