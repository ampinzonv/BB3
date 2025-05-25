# BioBASH v0.3 (Codename: Jazzy)

BioBASH is a modular library of Bash functions and command-line tools for bioinformatics workflows. It is designed to work on both macOS and Linux, enabling users to process biological sequence data using UNIX-style pipelines and scripts. All tools follow standard input/output conventions to maximize script composability and automation.

## Key Features

- Modular architecture (`file` and `utility` modules)
- STDIN/STDOUT friendly for pipeline integration
- Extensive logging and error handling
- Cross-platform compatibility (macOS/Linux)
- Autodetection of input types (e.g., gzipped FASTQ)

---

## Module: `file`

This module focuses on operations involving biological sequence files in FASTA and FASTQ formats. It includes functions for extraction, conversion, statistics, and splitting.

### `bb_get_fasta_header`
Extract FASTA headers from a file or STDIN.

### `bb_get_fasta_id`
Extract the first word (ID) of each FASTA header.

### `bb_get_fasta_seq`
Extract only the sequences from a FASTA file, removing headers.

### `bb_get_fasta_length`
Report the length of each sequence in a FASTA file.

### `bb_fastq_to_fasta`
Convert a FASTQ file into FASTA format.

### `bb_split_multiple_fasta`
Split a multi-FASTA file into individual FASTA files per entry.

### `bb_get_fasta_entry`
Extract specific entries from a FASTA file using a single ID or a list of IDs.

### `bb_get_fasta_range`
Extract a subsequence by ID and coordinate range (1-based).

### `bb_fasta_stats`
Generate basic statistics for a FASTA file, including N50.

### `bb_fastq_stats`
Calculate quality and length statistics for FASTQ files, including Q20/Q30 rates.

### `bb_guess_sequence_type`
Guess if the sequences in a FASTA file are DNA, RNA, or protein.

---

## Module: `utility`

This module contains auxiliary functions useful for generic list processing.

### `bb_get_list`
Processes a list of items and returns:
- a sorted non-redundant list (default), or
- frequency and percentage per item (with `--frequency`)

---

## Core Utilities (`biobash_core.sh`)

These internal functions provide core support and are used across modules.

- `parse_args`: Parse standardized command-line arguments.
- `check_input`: Validate input paths or STDIN.
- `check_file_exists`: Prevent overwriting unless `--force` is used.
- `info`, `warn`, `error`: Consistent messaging.
- `detect_os`: Set platform (`macos`, `linux`, `unsupported`).
- `create_outdir`: Ensure output directory exists.
- `get_basename`: Extract base filename.
- `auto_outname`: Generate default output names.
- `is_stdin`: Detect if input is from STDIN.
- `check_dependencies`: Ensure required tools exist.

---

## Citation

If you use BioBASH in your work, please cite it as:

> BioBASH v0.3 (Jazzy). Modular Bash library for bioinformatics workflows. Available at: https://github.com/biobash/jazzy

## License

BioBASH is open source and distributed under the MIT License.


---

## Function Usage Examples

### Module: `file`

#### `bb_get_fasta_header`
Extract headers from a FASTA file:
```bash
bb_get_fasta_header --input sequences.fasta
cat sequences.fasta | bb_get_fasta_header --input -
```

#### `bb_get_fasta_id`
Extract only IDs from headers:
```bash
bb_get_fasta_id --input sequences.fasta
```

#### `bb_get_fasta_seq`
Extract raw sequences:
```bash
bb_get_fasta_seq --input sequences.fasta --outfile onlyseqs.txt
```

#### `bb_get_fasta_length`
Report sequence lengths:
```bash
bb_get_fasta_length --input sequences.fasta
```

#### `bb_fastq_to_fasta`
Convert FASTQ to FASTA:
```bash
bb_fastq_to_fasta --input reads.fastq --outfile reads.fasta
zcat reads.fastq.gz | bb_fastq_to_fasta --input - > reads.fasta
```

#### `bb_split_multiple_fasta`
Split multi-FASTA into one file per sequence:
```bash
bb_split_multiple_fasta --input sequences.fasta --outdir parts/
```

#### `bb_get_fasta_entry`
Extract entry by ID:
```bash
bb_get_fasta_entry --input sequences.fasta --entry seq1
bb_get_fasta_entry --input sequences.fasta --entry-file ids.txt
```

#### `bb_get_fasta_range`
Extract a range from a sequence:
```bash
bb_get_fasta_range --input sequences.fasta --entry seq1 --start 5 --end 25
```

#### `bb_fasta_stats`
Compute stats like N50:
```bash
bb_fasta_stats --input sequences.fasta
```

#### `bb_fastq_stats`
Quality metrics of FASTQ:
```bash
bb_fastq_stats --input reads.fastq
bb_fastq_stats --input reads.fastq.gz
```

#### `bb_guess_sequence_type`
Identify sequence type:
```bash
bb_guess_sequence_type --input unknown_sequences.fasta
```

---

### Module: `utility`

#### `bb_get_list`
Get sorted unique list:
```bash
bb_get_list --input list.txt
cat list.txt | bb_get_list --input -
```

With frequencies:
```bash
bb_get_list --input list.txt --frequency
```

---

## Notes

- All functions support `--quiet` to suppress logging and `--force` to overwrite output files.
- Use `--outfile` or `--outdir` to control outputs.
- Input can be provided from STDIN using `--input -`.

