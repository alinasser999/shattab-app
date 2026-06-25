# Shattab (شطب) — Session Handoff

**Last updated:** 2026-05-16
**Last completed:** M1 + M2 + M2.5 LinkedIn-for-Contractors upgrade
**Next milestone:** M3 Contractor Core

Full project state lives in `C:\Users\LENOVO\Desktop\fovic vault\wiki\entities\batsh-app.md` — read that first.

---

## Goal of the next session

**Step 1 (MUST do first): Visual verification gate.**
Before touching any code, get a screenshot from the user of the Discover tab in **incognito mode** at `http://localhost:8080` after running:
```
cd C:\Users\LENOVO\batsh-app
flutter run -d chrome --web-port 8080
```

What the screenshot must show for M2.5 to be considered "actually shipped":
- Horizontal "مقاولين مميّزين" strip at the top with big cover-photo landscape tiles
- ContractorCards below with: 130px cover image at top + circular avatar peeking below + stat chips (rating, projects count, years) + specialty pills + heart icon
- Tap a contractor → SliverAppBar with 240px cover hero + floating circular avatar with terracotta ring + gold star pill + 3 stat cards in a row + portfolio horizontal strip

**If the screenshot DOESN'T show this:** diagnose why before writing new code. Likely causes (in order):
1. Browser still has service worker from broken build → user needs incognito or DevTools → Application → Service Workers → Unregister + Clear site data
2. Unsplash cover photo URLs are 404-ing/blocked → check Network tab; if so, swap to Supabase storage uploads or alternate CDN
3. The seed data wasn't actually inserted → run a Supabase query to confirm `portfolio_projects` table has rows and `contractor_profiles.cover_photo_url` is populated
4. Genuinely failed the design brief → use frontend-design skill, push harder on the editorial styling

**If the screenshot DOES show all that:** proceed to Step 2.

---

## Step 2 — M3 Contractor Core (the build)

Brainstorm first (use brainstorming skill — do NOT skip), then build:

1. **Contractor inbox** (replaces or sits alongside `JobOpportunitiesScreen`)
   - Direct briefs (homeowner sent brief to THIS contractor specifically) — separate tab/section
   - Public posts in their specialties (already exists as فرص شغل) — keep this
   - Status: new / responded / archived

2. **Contractor portfolio editing screen**
   - List of their existing `portfolio_projects` rows
   - Add new project (title, description, category, location, year, cover photo, up to 5 detail photos → portfolio-photos bucket)
   - Edit / delete existing projects
   - Set/change cover photo on profile (→ contractor-covers bucket)
   - Set/change headline

3. **Profile editing screen** (works for both roles, contractor variant is richer)
   - Bio
   - Specialties (multi-select from catalog)
   - Service areas (multi-select)
   - Years experience
   - Logo
   - For homeowner: apartment type, location, interests

4. **Quote/proposal flow** (only if time permits — otherwise defer to M3.5)
   - Contractor opens a brief → "اعمل عرض سعر" button → form (price range, timeline, notes) → sends back to homeowner
   - Homeowner sees received quotes in brief detail screen
   - New table: `quotes` (id, brief_id, contractor_id, price_min, price_max, timeline_days, notes, status, created_at)
   - RLS: contractors can insert quotes for any brief they can read; homeowners can read quotes for their own briefs

---

## Hard constraints (don't break these)

- Stack stays: Flutter + Supabase + Riverpod 3.x + go_router (NO new packages without asking)
- `.value` not `.valueOrNull` on AsyncValue (Riverpod 3.x removed it)
- No freezed (conflicts with riverpod_annotation in v3)
- Repositories are the ONLY layer that touches Supabase
- All copy is in Egyptian Arabic, RTL throughout
- No in-app chat (deferred to M4) — keep WhatsApp + Call deep links
- Computed star rating stays for now (real reviews in M4)

---

## Side tasks (user can do these without Claude)

- Enable Supabase Phone provider at https://supabase.com/dashboard/project/ajqdutehxpbbflzdovhw/auth/providers
- Rotate Stitch API key (Google Cloud Console → update `~/.claude.json`)

---

## Definition of done for M3

- `flutter analyze` clean
- Contractors can open the app, see their inbox with direct briefs separated from public posts
- Contractors can add at least one portfolio project from within the app (photo upload to Supabase storage works)
- Contractors can edit their bio + headline + specialties
- New migration `0006_*.sql` applied to Supabase, `get_advisors` clean
- Write `batsh-app/docs/m3-completion.md` with what shipped
- Append log entry to `wiki/log.md`
- Update `wiki/entities/batsh-app.md` to flip M3 status to ✅ and add M4 as ⏳ Next
