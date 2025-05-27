#!/usr/bin/env bash

# Load BioBASH core and function
. ../biobash_core.sh
. ../blast.sh
. ../file.sh  # Asegúrate que bb_blast_summary esté en este archivo o cambia la ruta

# Colores
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"

pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }

# Directorio temporal
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

INPUT_FILE="$TMPDIR/sample_blast.outfmt"
EXPECTED_FILE="$TMPDIR/expected.txt"
RESULT_FILE="$TMPDIR/result.txt"

# Crear archivo BLAST de prueba (14 columnas)
cat > "$INPUT_FILE" <<EOF
query1	subjA	98.2	100	1	0	1	100	1	100	1e-20	180	100	300
query1	subjB	87.0	90	5	1	2	91	3	92	2e-5	100	100	250
query2	subjC	91.5	95	8	1	2	96	3	97	3e-40	200	110	280
query2	subjD	79.0	80	17	2	1	80	5	84	5e-4	100	110	190
EOF

# Salida esperada parcial (verificamos líneas clave)
cat > "$EXPECTED_FILE" <<EOF
BLAST Summary:
  Total alignments:               4
  Unique queries:                 2
  Unique targets:                 4
  Queries with hits:              2
EOF

# Ejecutar la función
bb_blast_summary --input "$INPUT_FILE" --outfile "$RESULT_FILE" --quiet

# Verificar salida
if grep -q "Total alignments:               4" "$RESULT_FILE" &&
   grep -q "Unique queries:                 2" "$RESULT_FILE" &&
   grep -q "Unique targets:                 4" "$RESULT_FILE" &&
   grep -q "Queries with hits:              2" "$RESULT_FILE"; then
   pass "bb_blast_summary output matches expected counts"
else
   fail "bb_blast_summary output differs from expected"
   diff "$EXPECTED_FILE" "$RESULT_FILE" || true
   exit 1
fi
