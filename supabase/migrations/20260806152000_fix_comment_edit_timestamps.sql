-- Backfill historical comment timestamps without the update trigger replacing
-- them with the current time.
drop trigger if exists set_post_comment_updated_at on public.post_comments;

update public.post_comments
set updated_at = created_at
where updated_at > created_at;

create trigger set_post_comment_updated_at
  before update on public.post_comments
  for each row execute function public.tg_set_updated_at();
