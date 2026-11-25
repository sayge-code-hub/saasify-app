#!/usr/bin/env bash
# Verifies the Sayge database after versioned migrations are applied. No
# seed/demo data. Apply schema changes with `supabase db push --remote`.
#
# Apply changes with `supabase db push --remote`, then use this script to
# verify anonymous API access is denied.
#
# Required in .env or .env.example:
#   SUPABASE_URL=https://xxxx.supabase.co
#   SUPABASE_ANON_KEY=eyJ...
#
# Optional:
#   SUPABASE_DB_URL=postgresql://...   # auto-apply DDL via psql
#
# Usage:
#   chmod +x scripts/setup_supabase.sh
#   ./scripts/setup_supabase.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ -f .env ]]; then
  # shellcheck disable=SC1091
  set -a
  source .env
  set +a
elif [[ -f .env.example ]]; then
  # shellcheck disable=SC1091
  set -a
  source .env.example
  set +a
fi

need() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing $name. Add it to .env (see .env.example)." >&2
    exit 1
  fi
}

need SUPABASE_URL
need SUPABASE_ANON_KEY

echo "==> Sayge Supabase verification (versioned migrations only)"
echo "    URL: $SUPABASE_URL"

# Anonymous requests must be rejected. A 200 here means data is exposed.
SENSITIVE_TABLES=(
  employees users clients dms_entities documents employee_purchase_orders
  expenses expense_categories invoices invoice_line_items
  proposals proposal_line_items payroll_runs payslip_records
  activity_log company_details roles
  pos_brands pos_products pos_purchases pos_purchase_items pos_price_rules
)

verify_anon_denied() {
  local failures=0
  echo "==> Verifying anonymous REST access is denied..."
  for table in "${SENSITIVE_TABLES[@]}"; do
    local code
    code="$(curl -sS -o /dev/null -w '%{http_code}' \
      "${SUPABASE_URL}/rest/v1/${table}?select=*&limit=1" \
      -H "apikey: ${SUPABASE_ANON_KEY}")"
    if [[ "$code" == "200" ]]; then
      echo "    FAIL ${table}: HTTP ${code} (readable by anon)"
      failures=$((failures + 1))
    else
      echo "    ok   ${table}: HTTP ${code}"
    fi
  done

  if (( failures > 0 )); then
    echo
    echo "==> ${failures} table(s) still readable anonymously." >&2
    echo "    Apply the pending versioned migrations, then re-run this script." >&2
    return 1
  fi
  echo "==> All checked tables deny anonymous reads."
}

verify_anon_denied

cat <<'EOF'

==> Next steps
  - Migration policy: supabase/MIGRATIONS.md
  - Inspect grants / RLS / policies / function ACLs: run
    supabase/legacy/manual/security_verification.sql in the SQL Editor. Checks 1, 2, 3, 7, 8
    and 9 must return zero rows; the rest are inventories with the expected
    result noted above each query.
  - Create users in Authentication → Users. A public.users row is created
    automatically with the default Employee role; promote owners/admins in
    the dashboard. Login uses Supabase Auth — no demo credentials.
  - Keep SUPABASE_SERVICE_ROLE_KEY out of the app and out of version control.
    The Flutter client only ever uses SUPABASE_ANON_KEY.
EOF
echo "==> Done."

