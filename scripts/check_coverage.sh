#!/usr/bin/env bash
set -euo pipefail

LCOV_FILE="${1:-coverage/lcov.info}"
MIN_COVERAGE="${2:-40}"

if [[ ! -f "$LCOV_FILE" ]]; then
  echo "Coverage file not found: $LCOV_FILE"
  exit 1
fi

coverage=$(awk '/^LF:/{lf+=substr($0,4)} /^LH:/{lh+=substr($0,4)} END {if(lf>0) printf("%.2f", (lh/lf)*100); else print "0.00"}' "$LCOV_FILE")

echo "Line coverage: ${coverage}%"
echo "Minimum required: ${MIN_COVERAGE}%"

awk -v cov="$coverage" -v min="$MIN_COVERAGE" 'BEGIN { exit !(cov+0 >= min+0) }'

echo "Coverage threshold passed."
