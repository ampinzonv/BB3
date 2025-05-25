#!/usr/bin/env bash

. ../biobash_core.sh
. ../utility.sh

GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"
pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }

echo "== Running tests for bb_get_list =="

# Test 1: Unique list
cat <<EOF > test_list.txt
apple
banana
apple
carrot
banana
EOF

expected_unique="apple
banana
carrot"

result=$(bb_get_list --input test_list.txt)
if [[ "$result" == "$expected_unique" ]]; then
    pass "bb_get_list returns unique list alphabetically"
else
    fail "bb_get_list failed unique list output"
    echo "$result"
fi

# Test 2: Frequency
cat <<EOF > test_freq.txt
apple
banana
banana
carrot
banana
EOF

expected_freq="apple	1	20
banana	3	60
carrot	1	20"

result=$(bb_get_list --input test_freq.txt --frequency)

# Normalize spacing to tabs for comparison
normalized=$(echo "$result" | awk -F'\t' '{printf "%s\t%d\t%d\n", $1, $2, $3}')
if [[ "$normalized" == "$expected_freq" ]]; then
    pass "bb_get_list computes correct frequency output"
else
    fail "bb_get_list did not compute correct frequency output"
    echo "$normalized"
fi

rm -f test_list.txt test_freq.txt
