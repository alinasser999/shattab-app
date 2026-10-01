# Shattab AI Assistant

## Product boundary

The assistant is a first-party, Arabic-first guide for homeowners and
professionals. It can ask focused questions about a finishing need, explain
bounded industry or app workflows, and hand a homeowner into the existing
professional discovery flow.

It is not a second messaging system. Human-to-human chat remains outside this
feature, and the assistant never invents a professional, phone number, price,
rating, verification state, or database identifier.

## Request flow

```text
AssistantScreen (RTL)
  -> AssistantChatNotifier (ephemeral state)
  -> AssistantRepository (redaction + six-message/500-char cap)
  -> Supabase Edge Function: assistant-chat
       -> Supabase JWT validation
       -> aggregate daily quota (no transcript)
       -> OpenRouter model: openrouter/free
       -> bounded JSON envelope
  -> validated specialty/city filters
  -> DiscoveryRepository.fetchContractorsPage
  -> real ContractorListing cards
```

The client does not send a model override. The Edge Function owns the
OpenRouter secret and pins `openrouter/free`, so a change in the provider's
free catalogue is handled by the router rather than by a paid fallback.

## Bounded envelope

The model may return only:

- an allowlisted intent;
- sanitized Arabic reply and one focused next question;
- a canonical specialty root from the shared catalog;
- a canonical city from homeowner onboarding;
- an allowlisted in-app action ID; and
- up to four short quick replies.

The UI uses `specialty_key` and `city_key` only as filters for the existing
discovery repository. Professional names, badges, ratings, and profile routes
come from the existing `ContractorListing` and router contracts.

## Privacy and abuse controls

- Prompts and completions are not persisted as transcripts.
- Client and server redact Egyptian phone numbers, emails, cards, national IDs,
  UUIDs, and external URLs before the model request.
- History is capped at six messages and 500 characters per message.
- Only aggregate `(user_id, usage_date, request_count)` usage is stored, with a
  server-owned daily limit and an RPC derived from `auth.uid()`.
- Analytics records only booleans, counts, and allowlisted action values.
- Provider failures return a deterministic local fallback; no paid model is
  selected.

## Activation checklist

1. Deploy migration `20260910210000_assistant_quota.sql`.
2. Store `OPENROUTER_API_KEY` as a Supabase Edge Function secret. Never add it
   to Flutter, `.env.example`, logs, or git history.
3. Deploy `supabase/functions/assistant-chat`.
4. Sign in to a test account and verify the homeowner and professional routes.
5. Confirm the free-router and fallback behavior with the focused Flutter tests.
