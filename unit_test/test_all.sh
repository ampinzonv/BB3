#!/usr/bin/env bash

echo "== Running all BIOBASH tests =="

test_files=(
    test_bb_fasta_stats.sh
    test_bb_fastq_stats.sh
    test_bb_fastq_to_fasta.sh
    test_bb_get_fasta_entry.sh
    test_bb_get_fasta_header.sh
    test_bb_get_fasta_id.sh
    test_bb_get_fasta_length.sh
    test_bb_get_fasta_range.sh
    test_bb_get_fasta_seq.sh
    test_bb_get_list.sh
    test_bb_guess_sequence_type.sh
    test_bb_split_multiple_fasta.sh
   
    test_bb_blast_best_hit.sh
    test_bb_create_blast_db.sh
    test_bb_run_blast.sh
    test_bb_blast_summary.sh
    test_bb_blast_on_the_fly.sh
    test_bb_blast_reciprocal.sh
    
)

for test in "${test_files[@]}"; do
    if [[ -x "$test" ]]; then
        echo ""
        echo -e "\\033[1;34m[$test] \\033[0m"
        ./"$test"
        echo ""
    else
        echo "[SKIP] $test is not executable or not found"
    fi
done

echo "== All tests completed =="
