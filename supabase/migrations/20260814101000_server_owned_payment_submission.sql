-- Keep payment claims server-owned.
--
-- A client may request a Pro payment claim, but it must not be able to choose
-- the amount written to payment_requests. The RPC validates the request,
-- computes the price, and makes retries idempotent before inserting a pending
-- row. Approval remains a separate admin-only operation.

drop policy if exists "pr_insert_own" on public.payment_requests;
revoke insert, update, delete on public.payment_requests from public, anon, authenticated;

drop function if exists public.submit_payment_request(text, text, text, text, text, text);

create function public.submit_payment_request(
  p_method text,
  p_purpose text,
  p_plan_term text default null,
  p_proof_path text default null,
  p_reference_text text default null,
  p_idempotency_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := (select auth.uid());
  v_key text := nullif(btrim(p_idempotency_key), '');
  v_amount int;
  v_existing uuid;
  v_request uuid;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.contractor_profiles cp where cp.profile_id = v_uid
  ) then
    raise exception 'contractor profile required' using errcode = '42501';
  end if;

  if p_method <> 'instapay' then
    raise exception 'payment method is not available';
  end if;
  if p_purpose <> 'pro' then
    raise exception 'payment purpose is not available';
  end if;
  if p_plan_term not in ('monthly', 'annual') then
    raise exception 'invalid Pro plan term';
  end if;
  if v_key is null or length(v_key) < 16 or length(v_key) > 128 then
    raise exception 'invalid idempotency key';
  end if;
  if p_reference_text is not null and length(p_reference_text) > 500 then
    raise exception 'reference is too long';
  end if;
  if p_proof_path is not null
     and p_proof_path !~ ('^' || v_uid::text || '/[A-Za-z0-9._/-]+$') then
    raise exception 'invalid proof path';
  end if;

  v_amount := case p_plan_term
    when 'monthly' then 299
    when 'annual' then 2990
  end;

  select pr.id
    into v_existing
    from public.payment_requests pr
   where pr.contractor_id = v_uid
     and pr.idempotency_key = v_key
   limit 1;
  if v_existing is not null then
    return v_existing;
  end if;

  begin
    insert into public.payment_requests (
      contractor_id,
      method,
      purpose,
      plan_term,
      amount_egp,
      proof_path,
      reference_text,
      status,
      idempotency_key
    ) values (
      v_uid,
      p_method,
      p_purpose,
      p_plan_term,
      v_amount,
      p_proof_path,
      nullif(btrim(p_reference_text), ''),
      'pending',
      v_key
    )
    returning id into v_request;
  exception when unique_violation then
    select pr.id
      into v_request
      from public.payment_requests pr
     where pr.contractor_id = v_uid
       and pr.idempotency_key = v_key
     limit 1;
    if v_request is null then
      raise;
    end if;
  end;

  return v_request;
end;
$$;

revoke all on function public.submit_payment_request(text, text, text, text, text, text)
  from public, anon, authenticated;
grant execute on function public.submit_payment_request(text, text, text, text, text, text)
  to authenticated;

comment on function public.submit_payment_request(text, text, text, text, text, text)
  is 'Creates one server-priced pending Pro payment claim for the authenticated contractor.';
