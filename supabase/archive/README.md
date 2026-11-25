# Archived SQL — do not run in production

These scripts are preserved for audit/history only. They are not part of the
active migration path and must never be included in `scripts/setup_supabase.sh`.

- `destructive/`: scripts that delete or reset application data.
- `demo/`: sample/demo seed data only.
- `superseded/`: replaced by the authoritative multi-tenant and security
  hardening migrations.

Production deployments use only versioned scripts in `../migrations/`.
