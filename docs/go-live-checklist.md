# Shattab Go-Live Checklist

## 🔴 Critical — Blocks launch

### 1. Apply all missing migrations on Supabase
Three migrations exist **on disk** but may not be applied live:
- `0003_contractors` (onboarding tables — applied live but no SQL on disk, check if exists)
- `0004_briefs_and_saved` (just written to disk — now has SQL)
- `0005_quotes` (written to disk, M3 completion says PENDING)
- `0006_reviews` (written to disk)

Run these via Supabase SQL editor or MCP. The `briefs` table might already exist from the earlier live apply, in which case skip `0004` and only apply `0005` + `0006`.

### 2. Enable Phone Auth Provider
Supabase dashboard → Authentication → Providers → Phone → **Enable**. Shattab uses phone OTP only. Without this, no one can sign up or log in.

### 3. Create `brief-photos` storage bucket
Supabase dashboard → Storage → Create bucket `brief-photos` (public). Add policy: authenticated users can read/write their own path prefix.

### 4. Verify RLS policies on `briefs`
The app has **3 RLS queries** that must work:
- `homeowner_all`: homeowner can CRUD their own briefs (by `homeowner_id = auth.uid()`)
- `contractor_read_open`: contractor can `SELECT` where `status = 'open'` AND `target_contractor_id IS NULL`
- `contractor_read_targeted`: contractor can `SELECT` where `target_contractor_id = auth.uid()`

Verify with `SELECT * FROM pg_policies WHERE tablename = 'briefs';`

### 5. Verify specialty/area matching works
The contractor opportunities query now filters by:
- `target_specialties` **overlaps** with contractor's `specialties[]`
- brief `city` **in** contractor's `service_areas[]`

Test: Create a contractor with `specialties: ['paint']`, create a brief with `target_specialties: ['paint', 'kitchen']`. The contractor should see it; a plumber should not.

---

## 🟡 High priority

### 6. Rebuild generated files
```bash
dart run build_runner build --delete-conflicting-outputs
```
The repo needs `.g.dart` files in sync. Run this before any build.

### 7. Seed demo data
At minimum: 3 contractors (plumber, painter, electrician) + 2 homeowners + 3-4 briefs (mix of public posts + direct requests) + 2-3 quotes + 1 portfolio project each. Without data, the app shows empty states everywhere.

### 8. Set up `.env` in build environment
The app reads Supabase URL + anon key from `.env` (never committed). Ensure this file exists with the correct values for the production Supabase project.

### 9. Test full user flows on real device
- [ ] Signup as homeowner → onboarding → discover contractors → filter by specialty → view profile → save contractor → create public post
- [ ] Signup as contractor → onboarding → see matched opportunities → send quote → view inbox → accept direct request
- [ ] Login as homeowner (on another device) → see quote on your brief → accept → contact via WhatsApp

---

## 🟡 Medium priority

### 10. Handle missing contractor profile gracefully
`fetchOpportunitiesForContractor()` now queries `contractor_profiles`. If the profile is missing (e.g., admin account with no contractor profile), the method returns all open briefs with no filter — not ideal but works. Add an empty-state message for incomplete profiles.

### 11. Add refresh on profile mismatch
If a contractor updates their specialties/areas, old session may not reflect changes. Recommend: pull fresh profile each time rather than caching.

### 12. App icon + splash branding
Current app uses default Flutter icon. Need:
- App launcher icon (terracotta brand)
- Splash screen on Android (colors.xml + splash theme)

### 13. Review error messages
Arabic error messages from Supabase are raw. Map common errors (network, RLS violation, duplicate quote) to user-friendly Arabic strings.

---

## 🟢 Low priority (nice to have)

### 14. Enable dark mode toggle
Theme code already has `BatshTheme.dark()` fully defined. Just need to wire the toggle on the profile screen.

### 15. Add pull-to-refresh on all list screens
Currently: discover screen, inbox, job opportunities have it. Portfolio, my briefs, saved contractors need it.

### 16. Add unread badge on inbox tab
Count briefs where quote status is null (no quote sent yet) and show a badge count on the inbox nav item.

## Summary of what was just fixed

| Issue | Fix |
|-------|-----|
| Contractor sees ALL open briefs, not matched ones | `fetchOpportunitiesForContractor()` now queries `contractor_profiles` and filters by specialty `overlaps` + city `in` service_areas |
| Missing `0004_briefs_and_saved.sql` on disk | Written to `supabase/migrations/0004_briefs_and_saved.sql` |
| Specialty/area matching was a doc claim, not actual code | Fixed in `briefs_repository.dart:35-56` |
