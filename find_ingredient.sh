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

# Figure out which column is "ingredients_text"
ING_COL=$(zcat "$FILE" | head -1 | tr '\t' '\n' | grep -n "^ingredients_text$" | cut -d: -f1)

if [ -z "$ING_COL" ]; then
  echo "ERROR: ingredients_text column not found in header" >&2
  exit 1
fi

# Stream the gzipped file through awk
zcat "$FILE" | awk -F'\t' -v IGN="$INGREDIENT" -v ICOL="$ING_COL" '
BEGIN {
  count = 0
  ign_lc = tolower(IGN)
}
NR == 1 { next } # skip header
{
  code = $1
  name = $2
  ingredients = $ICOL
  if (tolower(ingredients) ~ ign_lc) {
    print name "\t" code
    count++
  }
}
END {
  print "----"
  print "Found " count " product(s) containing: \"" IGN "\""
}'
