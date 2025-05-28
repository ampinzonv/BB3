#!/usr/bin/env bash

# Test: test_bb_blast_reciprocal.sh
# Purpose: Ensure bb_reciprocal_blast runs and generates the expected outputs

set -euo pipefail

# Load BioBASH core and blast if needed
if ! declare -f bb_reciprocal_blast >/dev/null; then
    . ../biobash_core.sh
    . ../blast.sh
    . ../file.sh
fi

# Create temp test directory
TESTDIR=$(mktemp -d)
trap "rm -rf $TESTDIR" EXIT

# Prepare minimal query and subject FASTA
cat > "$TESTDIR/query.fa" <<EOF
>seq1
ATGGCGTGAACGTAGCGTAGCGTAGCTAG
>seq2
ATGGCGTAGCTAGCTAGCTGACTGACTGA
EOF

cat > "$TESTDIR/subject.fa" <<EOF
>hit1
ATGGCGTGAACGTAGCGTAGCGTAGCTAG
>hit2
ATGGCGTAGCTAGCTAGCTGACTGACTGA
EOF

cd "$TESTDIR"

# Run reciprocal blast
bb_reciprocal_blast \
    --query query.fa \
    --subject subject.fa \
    --blast_type blastn \
    --outfile testrecip \
    --quiet \
    --force

# Verify outputs
if [[ ! -s testrecip.A_vs_B.blast ]]; then
    echo "[FAIL] Missing or empty testrecip.A_vs_B.blast"
    exit 1
fi

if [[ ! -s testrecip.B_vs_A.blast ]]; then
    echo "[FAIL] Missing or empty testrecip.B_vs_A.blast"
    exit 1
fi

if [[ ! -s testrecip.reciprocal.tsv ]]; then
    echo "[FAIL] Missing or empty testrecip.reciprocal.tsv"
    exit 1
fi

echo "[PASS] bb_reciprocal_blast produced expected output files."
exit 0
