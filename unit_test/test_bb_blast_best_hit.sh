
#!/usr/bin/env bash

. ../biobash_core.sh
. ../blast.sh

GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"
pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }

test_bb_blast_best_hit() {
    echo "== Running test: bb_blast_best_hit vs expected output variable =="

    local TMPDIR
    TMPDIR=$(mktemp -d)
    local blast_input_file="$(realpath ../testdata/salidablast.outfmt)"

    cd "$TMPDIR" || { echo "Could not enter temp directory"; return 1; }

    # Variable con salida esperada exacta
    local expected_output="query2	subjC	91.5	95	8	1	2	96	3	97	3e-40	200	110	280
query2	subjD	79.0	80	17	2	1	80	5	84	5e-4	100	110	190
query1	subjA	98.2	100	1	0	1	100	1	100	1e-20	180	100	300
query1	subjB	87.0	90	12	1	5	94	12	101	1e-5	160	100	250"

    # Guardar en archivo temporal
    local expected_file="expected.txt"
    echo "$expected_output" > "$expected_file"

    # Archivo resultado generado por la función
    local result_file="result.txt"
    bb_blast_best_hit --input "$blast_input_file" --outfile "$result_file" --quiet --force

    if diff "$result_file" "$expected_file" >/dev/null; then
        pass "bb_blast_best_hit output matches expected output"
    else
        fail "bb_blast_best_hit output differs from expected output"
        diff "$result_file" "$expected_file"
    fi

    cd - >/dev/null
    rm -rf "$TMPDIR"
}

test_bb_blast_best_hit
