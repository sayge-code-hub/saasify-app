# Database migration policy

`supabase/migrations/` is the only executable database-change directory.

- Create changes with `supabase migration new <name>`.
- Review with `supabase migration list --remote` and apply with
  `supabase db push --remote`.
- Never edit an applied migration. Create a corrective migration instead.
- Run the read-only checks in `legacy/manual/security_verification.sql` after
  every production migration and retain the run output with the release.
- `archive/` and `legacy/manual/` are historical evidence only. They must not
  be pasted into the SQL editor or included in deployment automation.

The repository contains the production migration ledger recovered on
2026-11-25. Earlier hand-run scripts were intentionally moved to
`legacy/manual/`; their data-changing statements are no longer an active
deployment path.
