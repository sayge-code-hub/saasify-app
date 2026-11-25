-- POS is not part of the current pilot. This is a platform-wide product
-- switch, independent of any individual company's billing configuration.

begin;

update public.platform_module_flags
set is_enabled = false,
    updated_at = now(),
    updated_by = null
where module_key = 'pos';

commit;
