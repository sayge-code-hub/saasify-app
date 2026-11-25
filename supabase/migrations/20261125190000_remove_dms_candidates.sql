-- Candidates are not a supported DMS owner type in the product. Remove their
-- catalog and document metadata. Supabase prevents Storage-object deletion via
-- SQL; any binary file must be removed through the Storage API separately.
begin;

delete from public.documents where entity_type = 'candidate';
delete from public.dms_entities where entity_type = 'candidate';

commit;
