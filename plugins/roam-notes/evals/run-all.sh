#!/bin/bash
# Run every *.test.sh in this directory; exit non-zero if any fails.
cd "$(dirname "$0")" || exit 1
status=0
for t in ./*.test.sh; do bash "$t" || status=1; done
exit $status
