-- A concurrent attachment can commit after a client-side orphan check.
-- Keep client uploads immutable; only trusted, quiescent maintenance may remove them.
drop policy if exists delete_unused_media on storage.objects;
drop function if exists public.can_delete_media(text);
