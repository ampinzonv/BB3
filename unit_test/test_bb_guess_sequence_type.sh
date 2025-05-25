#!/usr/bin/env bash

. ../biobash_core.sh
. ../file.sh

GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"

pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }

run_test() {
    local content="$1"
    local expected="$2"
    local label="$3"

    local tmp=$(mktemp)
    echo -e "$content" > "$tmp"

    local result
    result=$(bb_guess_sequence_type --input "$tmp" 2>/dev/null)

    if [[ "$result" == "$expected" ]]; then
        pass "$label"
    else
        fail "$label: expected '$expected', got '$result'"
    fi

    rm -f "$tmp"
}

echo "== Running test for bb_guess_sequence_type =="

run_test ">seq1\nATGCGTACGTTAGC" "DNA" "Detect DNA"
run_test ">seq1\nAUGCGAUUCGACUGA" "RNA" "Detect RNA"
run_test ">seq1\nMKTAYIAKQRQISFVK" "Protein" "Detect Protein"

# FASTQ-like input test
tmpf=$(mktemp)
echo -e "@seq1\nATGCGTACGTTAGC\n+\nIIIIIIIIIIIIII" > "$tmpf"
if bb_guess_sequence_type --input "$tmpf" >/dev/null 2>&1; then
    fail "Detect FASTQ: should have failed"
else
    pass "Detect FASTQ: correctly rejected"
fi
rm -f "$tmpf"
