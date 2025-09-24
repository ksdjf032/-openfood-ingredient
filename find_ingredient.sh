#!/usr/bin/env bash
# Usage: ./find_ingredient.sh -i "<ingredient>" -f /path/to/products.csv.gz
# Input: products.csv.gz (tab-separated, gzipped)
# Output: product_name<TAB>code for matches, then a final count line.

set -euo pipefail

INGREDIENT=""
FILE=""

usage() {
  echo "Usage: $0 -i \"<ingredient>\" -f /path/to/products.csv.gz"
  echo " -i ingredient to search (case-insensitive)"
  echo " -f gzipped products.csv file"
  echo " -h show help"
}

# Parse flags
while getopts ":i:f:h" opt; do
  case "$opt" in
    i) INGREDIENT="$OPTARG" ;;
    f) FILE="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

# Validate inputs
[ -z "${INGREDIENT:-}" ] && { echo "ERROR: -i <ingredient> is required" >&2; usage; exit 1; }
[ -z "${FILE:-}" ] && { echo "ERROR: -f /path/to/products.csv.gz is required" >&2; usage; exit 1; }
[ -s "$FILE" ] || { echo "ERROR: $FILE not found or empty." >&2; exit 1; }

# Check csvkit tools
for cmd in csvcut csvgrep csvformat; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "ERROR: $cmd not found. Please install csvkit." >&2; exit 1; }
done

# Pipeline:
tmp_matches="$(mktemp)"
zcat "$FILE" \
  | csvcut -t -c ingredients_text,product_name,code \
  | csvgrep -c ingredients_text -r "(?i)${INGREDIENT}" \
  | csvcut -c product_name,code \
  | csvformat -T \
  | tail -n +2 \
  | tee "$tmp_matches"

count="$(wc -l < "$tmp_matches" | tr -d ' ')"
echo ""
echo "Found ${count} product(s) containing: \"${INGREDIENT}\""

# cleanup
rm -f "$tmp_matches"
