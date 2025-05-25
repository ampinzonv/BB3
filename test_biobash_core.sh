#!/usr/bin/env bash

# Load core functions
. ./biobash_core.sh

# Colors for pretty output
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"

pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }

##########################
# TEST: detect_os
##########################
test_detect_os() {
    detect_os
    case "$OS_TYPE" in
        linux|macos)
            pass "detect_os correctly detected OS: $OS_TYPE"
            ;;
        *)
            fail "detect_os returned invalid OS_TYPE: $OS_TYPE"
            ;;
    esac
}

##########################
# TEST: error
##########################
test_error_message() {
    QUIET="false"
    local output
    output=$(error "Test error message" 2>&1)
    if [[ "$output" == *"[ERROR] Test error message"* ]]; then
        pass "error prints message with QUIET=false"
    else
        fail "error failed with QUIET=false"
    fi
}

test_error_quiet() {
    QUIET="true"
    local output
    output=$(error "Should not be printed" 2>&1)
    if [[ -z "$output" ]]; then
        pass "error is silent with QUIET=true"
    else
        fail "error printed despite QUIET=true"
    fi
}

##########################
# TEST: info
##########################
test_info_message() {
    QUIET="false"
    local output
    output=$(info "Test info message")
    if [[ "$output" == *"[INFO]  Test info message"* ]]; then
        pass "info prints message with QUIET=false"
    else
        fail "info failed with QUIET=false"
    fi
}

test_info_quiet() {
    QUIET="true"
    local output
    output=$(info "Should not be printed")
    if [[ -z "$output" ]]; then
        pass "info is silent with QUIET=true"
    else
        fail "info printed despite QUIET=true"
    fi
}

##########################
# TEST: warn
##########################
test_warn_message() {
    QUIET="false"
    local output
    output=$(warn "Test warn message" 2>&1)
    if [[ "$output" == *"[WARN]  Test warn message"* ]]; then
        pass "warn prints message with QUIET=false"
    else
        fail "warn failed with QUIET=false"
    fi
}

test_warn_quiet() {
    QUIET="true"
    local output
    output=$(warn "Should not be printed" 2>&1)
    if [[ -z "$output" ]]; then
        pass "warn is silent with QUIET=true"
    else
        fail "warn printed despite QUIET=true"
    fi
}

##########################
# TEST: check_file_exists
##########################
test_check_file_exists_blocks_without_force() {
    local temp_file="test_exists.txt"
    echo "dummy" > "$temp_file"

    FORCE="false"
    if (check_file_exists "$temp_file") 2>/dev/null; then
        fail "check_file_exists did not block existing file with FORCE=false"
    else
        pass "check_file_exists blocks existing file with FORCE=false"
    fi
    rm -f "$temp_file"
}

test_check_file_exists_allows_with_force() {
    local temp_file="test_exists_force.txt"
    echo "dummy" > "$temp_file"

    FORCE="true"
    if (check_file_exists "$temp_file"); then
        pass "check_file_exists allows existing file with FORCE=true"
    else
        fail "check_file_exists blocked file despite FORCE=true"
    fi
    rm -f "$temp_file"
}

##########################
# TEST: check_input
##########################
test_check_input_allows_stdin() {
    if (check_input "-"); then
        pass "check_input accepts STDIN ('-')"
    else
        fail "check_input rejected STDIN ('-')"
    fi
}

test_check_input_existing_file() {
    local temp_file="input_test_file.txt"
    echo "content" > "$temp_file"

    if (check_input "$temp_file"); then
        pass "check_input accepts existing file"
    else
        fail "check_input rejected existing file"
    fi
    rm -f "$temp_file"
}

test_check_input_missing_file() {
    local missing_file="definitely_missing_input.txt"
    if (check_input "$missing_file") 2>/dev/null; then
        fail "check_input accepted missing file"
    else
        pass "check_input correctly rejected missing file"
    fi
}

##########################
# TEST: auto_outname
##########################
test_auto_outname_from_file() {
    local result
    result=$(auto_outname "sequence.fasta" "txt")
    if [[ "$result" == "sequence.txt" ]]; then
        pass "auto_outname correctly processes filename with extension"
    else
        fail "auto_outname failed on file input: got '$result'"
    fi
}

test_auto_outname_from_stdin() {
    local result
    result=$(auto_outname "-" "png")
    if [[ "$result" == "STDIN.png" ]]; then
        pass "auto_outname correctly handles STDIN input"
    else
        fail "auto_outname failed on STDIN input: got '$result'"
    fi
}

test_auto_outname_no_extension_in_input() {
    local result
    result=$(auto_outname "rawdata" "gff")
    if [[ "$result" == "rawdata.gff" ]]; then
        pass "auto_outname works with file without extension"
    else
        fail "auto_outname failed with file without extension: got '$result'"
    fi
}

##########################
# TEST: create_outdir
##########################
test_create_outdir_creates_directory() {
    local newdir="test_outdir"
    rm -rf "$newdir"

    QUIET="true"
    create_outdir "$newdir"
    local status=$?

    if [[ $status -eq 0 && -d "$newdir" ]]; then
        pass "create_outdir successfully created directory"
    else
        echo "Function returned status: $status"
        ls -ld "$newdir" 2>/dev/null
        fail "create_outdir did not create the directory or returned error"
    fi
    rm -rf "$newdir"
}


test_create_outdir_existing_directory() {
    local existingdir="existing_outdir"
    mkdir -p "$existingdir"

    QUIET="true"
    if (create_outdir "$existingdir"); then
        pass "create_outdir does not fail on existing directory"
    else
        fail "create_outdir failed on existing directory"
    fi
    rm -rf "$existingdir"
}

##########################
# TEST: get_basename
##########################
test_get_basename_with_extension() {
    local result
    result=$(get_basename "/home/user/sample.fasta")
    if [[ "$result" == "sample" ]]; then
        pass "get_basename strips extension and path"
    else
        fail "get_basename failed: got '$result'"
    fi
}

test_get_basename_no_extension() {
    local result
    result=$(get_basename "rawdata")
    if [[ "$result" == "rawdata" ]]; then
        pass "get_basename works with file with no extension"
    else
        fail "get_basename failed: got '$result'"
    fi
}

test_get_basename_with_dot_in_name() {
    local result
    result=$(get_basename "/tmp/my.sample.1.txt")
    if [[ "$result" == "my.sample.1" ]]; then
        pass "get_basename removes only the final extension"
    else
        fail "get_basename failed on file with multiple dots: got '$result'"
    fi
}

##########################
# TEST: is_stdin
##########################
test_is_stdin_true() {
    if is_stdin "-"; then
        pass "is_stdin correctly returns true for '-'"
    else
        fail "is_stdin failed for '-'"
    fi
}

test_is_stdin_false() {
    if is_stdin "file.txt"; then
        fail "is_stdin incorrectly returned true for 'file.txt'"
    else
        pass "is_stdin correctly returns false for 'file.txt'"
    fi
}

##########################
# TEST: parse_args
##########################
test_parse_args_sets_expected_variables() {
    parse_args --input input.txt --outfile result.out --outdir results --jobname job1 --force --quiet

    if [[ "$INPUT" == "input.txt" && "$OUTFILE" == "result.out" && "$OUTDIR" == "results" &&
          "$JOBNAME" == "job1" && "$FORCE" == "true" && "$QUIET" == "true" ]]; then
        pass "parse_args sets all standard variables correctly"
    else
        fail "parse_args failed to set variables"
        echo "INPUT=$INPUT OUTFILE=$OUTFILE OUTDIR=$OUTDIR JOBNAME=$JOBNAME FORCE=$FORCE QUIET=$QUIET"
    fi
}

test_parse_args_fails_on_unknown_argument() {
    if (parse_args --unknown value) 2>/dev/null; then
        fail "parse_args did not fail on unknown argument"
    else
        pass "parse_args fails on unknown argument as expected"
    fi
}

##########################
# TEST: check_dependencies
##########################
test_check_dependencies_all_present() {
    if (check_dependencies bash echo grep); then
        pass "check_dependencies passes when all commands are available"
    else
        fail "check_dependencies failed despite all commands being present"
    fi
}

test_check_dependencies_missing_command() {
    if (check_dependencies definitelynotacmd) 2>/dev/null; then
        fail "check_dependencies did not fail on missing command"
    else
        pass "check_dependencies correctly fails on missing command"
    fi
}

##########################
# TEST: --processors
##########################
test_parse_args_sets_processors() {
    parse_args --processors 4
    if [[ "$PROCESSORS" == "4" ]]; then
        pass "--processors sets PROCESSORS correctly"
    else
        fail "--processors failed: got '$PROCESSORS'"
    fi
}

test_parse_args_processors_invalid_value() {
    if (parse_args --processors abc) 2>/dev/null; then
        fail "--processors accepted invalid value"
    else
        pass "--processors rejected invalid value as expected"
    fi
}

test_parse_args_processors_zero() {
    if (parse_args --processors 0) 2>/dev/null; then
        fail "--processors accepted 0"
    else
        pass "--processors correctly rejected 0"
    fi
}


##########################
# Run tests
##########################
echo "== Running tests for biobash_core.sh =="

test_detect_os
test_error_message
test_error_quiet
test_info_message
test_info_quiet
test_warn_message
test_warn_quiet
test_check_file_exists_blocks_without_force
test_check_file_exists_allows_with_force
test_check_input_allows_stdin
test_check_input_existing_file
test_check_input_missing_file
test_auto_outname_from_file
test_auto_outname_from_stdin
test_auto_outname_no_extension_in_input

test_create_outdir_creates_directory
test_create_outdir_existing_directory

test_get_basename_with_extension
test_get_basename_no_extension
test_get_basename_with_dot_in_name

test_is_stdin_true
test_is_stdin_false

test_parse_args_sets_expected_variables
test_parse_args_fails_on_unknown_argument

test_check_dependencies_all_present
test_check_dependencies_missing_command

test_parse_args_sets_processors
test_parse_args_processors_invalid_value
test_parse_args_processors_zero








