#!/bin/bash
# Minimal assertions for the roam-notes shell tests. Source this file.
_pass=0; _fail=0
_fail_msg() { _fail=$((_fail+1)); printf 'FAIL: %s\n' "$1"; shift; printf '  %s\n' "$@"; }
assert_eq() { if [ "$2" = "$3" ]; then _pass=$((_pass+1)); else _fail_msg "$1" "expected: $3" "actual:   $2"; fi; }
assert_contains() { if printf '%s' "$2" | grep -Fq -- "$3"; then _pass=$((_pass+1)); else _fail_msg "$1" "missing: $3" "in: $2"; fi; }
assert_empty() { if [ -z "$2" ]; then _pass=$((_pass+1)); else _fail_msg "$1" "expected empty, got: $2"; fi; }
assert_file() { if [ -f "$2" ]; then _pass=$((_pass+1)); else _fail_msg "$1" "missing file: $2"; fi; }
report() { printf '%s: %d passed, %d failed\n' "$(basename "$0")" "$_pass" "$_fail"; [ "$_fail" -eq 0 ]; }
