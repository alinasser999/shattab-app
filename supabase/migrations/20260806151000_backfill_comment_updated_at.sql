-- Existing comments received updated_at when threading was introduced. Their
-- initial value should equal created_at so the UI does not label old comments
-- as edited.
update public.post_comments
set updated_at = created_at
where updated_at > created_at;
