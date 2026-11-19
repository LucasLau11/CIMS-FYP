#!/usr/bin/env bash
# Runs every supabase/tests/*_check.sql against the database in $SUPABASE_DB_URL.
#
# Each check is one DO block that builds its situation inside a transaction and ends with
# `raise exception 'RESULT (rolled back) ...'`, so nothing is ever kept. The text after RESULT is
# the report. A check FAILS when
#   * it prints a line containing "(BAD)", or
#   * it stops with an error other than the deliberate RESULT one (for example because the
#     ids in a fixture-based check do not exist in this database).
#
# usage: SUPABASE_DB_URL=postgresql://... bash supabase/tests/run_checks.sh [file ...]

set -u
: "${SUPABASE_DB_URL:?Set SUPABASE_DB_URL to a Postgres connection string (a development or branch database).}"

cd "$(dirname "$0")"
files=("$@")
[ ${#files[@]} -eq 0 ] && files=(*_check.sql)

failed=0
for f in "${files[@]}"; do
  echo "=== $f"
  out=$(psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=0 -X -q -f "$f" 2>&1)
  echo "$out"
  if echo "$out" | grep -q "(BAD)"; then
    echo "FAIL: $f reported a (BAD) line"
    failed=1
  elif ! echo "$out" | grep -q "RESULT (rolled back)"; then
    echo "FAIL: $f stopped before it could report (see the error above)"
    failed=1
  else
    echo "ok: $f ran and reported"
  fi
done

if [ $failed -ne 0 ]; then
  echo "Some database checks failed."
  exit 1
fi
echo "All database checks reported without a (BAD) line."
