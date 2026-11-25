# Sensitive data retention and deletion

The database stores retention policy metadata but performs **no automatic purge**.
Deletion must be a documented, approved operator workflow because employment,
tax, payroll, and legal-hold obligations vary by jurisdiction and customer.

1. Verify the requester and tenant authority.
2. Check legal hold and applicable local retention period.
3. Export required records to the authorised archive.
4. Remove database rows and private Storage objects together, recording a
   redacted event in `sensitive_data_audit`.
5. Confirm backup-expiry timing with the customer; backups cannot be rewritten.

Encryption at rest is provided by Supabase. Field-level encryption requires a
server-side KMS/envelope-encryption key (for example through an Edge Function)
and must never be implemented with a key bundled in the Flutter client.
