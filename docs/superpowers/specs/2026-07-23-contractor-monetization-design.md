# Contractor Monetization — Design Spec

Date: 2026-07-23
Status: Approved direction, pending user review of spec
App: Shattab (شطب) — Egyptian contractor marketplace, Flutter + Supabase + Riverpod

---

## 1. Goal

Turn the contractor side into revenue via three separate, mutually reinforcing
products, without killing marketplace liquidity:

- **Verified** — trust signal (homeowner-facing), free and earned.
- **Pro** — growth subscription (contractor-facing ROI), recurring revenue.
- **Sponsored** — paid top placement, transactional add-on.

Guiding principle: **Verified ≠ Pro ≠ Sponsored.** Each pulls a different lever
(trust / volume / visibility). Bundling them dilutes all three. Verified is the
universal on-ramp: free, and required before a contractor may spend on placement.

---

## 2. What already exists (migration `0013_monetization.sql`)

- `contractor_profiles`: `plan` (free|pro), `plan_expires_at`, `sponsored_until`,
  `boost_until`, `verified` bool.
- `payments` audit table (Paymob; `purpose` in pro|sponsored|boost; status
  pending|paid|failed). RLS: contractor reads own; only service_role writes.
- `tg_block_selfupgrade` trigger — blocks any non-service_role from writing
  billing columns (`plan`, `plan_expires_at`, `sponsored_until`, `boost_until`,
  `verified`). Keep.
- **Hard lead-gate RLS** on `quotes` insert: only active-Pro may quote. **This
  changes** (see §5).
- `paywall_sheet.dart`: presentational stub, button inert → "coming soon".
- `verified` bool: **not rendered anywhere**, no earn-flow. Both to be built.

---

## 3. Locked decisions

| Decision | Choice |
|---|---|
| Free-tier model | **Freemium quota** — free contractors get 3 leads/month |
| Verified | **Free, earned** via document review |
| Pro price | **299 EGP/mo** (annual 2990/yr ≈ 2 months free) |
| Sponsored eligibility | **Any Verified contractor** (Pro not required) |
| Sponsored pricing | **Flat per week / per job** |

---

## 4. Tiers

| Capability | Free | Pro — 299 EGP/mo |
|---|---|---|
| Send quotes | 3 leads / calendar month | Unlimited |
| Direct-request inbox | Read only | Reply / quote |
| Discovery ranking | Normal | Priority |
| Portfolio slots | ~5 | Unlimited |
| "Homeowner saw your quote" | — | ✓ |
| Eligible to be Verified | ✓ | ✓ |
| Eligible to buy Sponsored | ✓ (if Verified) | ✓ (if Verified) |

Trial: first month free **or** first 3 quotes free (pick one at build; default
first-month-free) to prove ROI before charging.

---

## 5. Freemium quota — the one real RLS rewrite

Current lead-gate is binary (Pro-or-nothing). Replace with a monthly count so
free contractors can quote up to the limit; Pro bypasses it.

Approach:
- Count the contractor's `quotes` rows created in the current calendar month.
- Insert allowed if: `plan='pro' AND plan_expires_at > now()` **OR** monthly
  count `< 3`.
- Enforce in RLS `with check` (source of truth) using a `count(*)` subquery over
  `quotes` where `contractor_id = auth.uid()` and `created_at` in current month.
- Client mirrors the remaining count for UX (blurred/locked leads, "X left this
  month"), but the RLS is authoritative.

Quota number (3) is a tunable constant; document it in one place.

---

## 6. Verified — trust track (build first; no payment dependency)

**Flow**
1. Contractor taps "وثّق حسابك".
2. Uploads: national ID front + back, selfie holding ID. Optional: trade license
   / tax card / proof of past work.
3. Insert `verification_requests` row (status `pending`); files in a private
   storage bucket.
4. **Admin reviews** (Supabase dashboard or a simple internal review screen).
5. Approve → service-role sets `contractor_profiles.verified = true` (guard
   already blocks self-set). Reject → status `rejected` + reason; contractor sees
   reason and can resubmit.

**Schema (new)**
- `verification_requests(id, contractor_id fk profiles, status pending|approved|rejected,
  reason text, id_front_path, id_back_path, selfie_path, extra_paths text[],
  created_at, reviewed_at, reviewed_by)`.
- RLS: contractor reads/inserts own pending; only service_role updates status.
- Storage bucket `verification-docs` (private; contractor writes own prefix,
  service_role/admin reads).

**Display (new)**
- Render `verified` badge in `contractor_card.dart` (currently absent), on
  contractor profile, and on quote rows.
- Unverified shown "غير موثّق".
- Discovery filter "موثّق فقط".

**Want-drivers**
- Loss aversion: unverified become invisible under the filter.
- Completion nudge on contractor home ("حسابك ٦٠٪ — وثّق نفسك").
- Later, once data exists: social proof ("الموثّقون بيردّوا عليهم أكتر").

---

## 7. Pro — growth track (Paymob)

**Triggers to show paywall**
- Free quota hit; tap a locked/blurred matched lead; onboarding upsell; profile
  "Go Pro" entry.

**Flow**
1. Paywall sheet → plan select (monthly / annual).
2. Call `create-payment` edge fn → Paymob checkout URL → open in WebView.
3. Paymob webhook → `payment-webhook` edge fn (service_role) verifies signature →
   insert `payments` row `paid` (idempotent on `provider_ref`) → set
   `plan='pro'`, `plan_expires_at = now() + interval`.
4. Renewal reminder before expiry; on expiry, contractor drops to free quota
   (no destructive change — just the columns lapse).

**New**
- Edge fns: `create-payment`, `payment-webhook`.
- Plan-select UI + Paymob CheckoutWebview; replace the inert paywall button body.

**Reuse:** `payments`, guard trigger, `plan`/`plan_expires_at`.

**Want-drivers**
- Show missed money: blurred count of matched leads with EGP value ("١٢ شغل
  اتطابق معاك الأسبوع ده" + lock).
- ROI anchor: "عرض واحد ممكن يجيب ٢٠٬٠٠٠ ج، البرو ٢٩٩/شهر".
- Trial removes first-purchase risk.

---

## 8. Sponsored — placement track (any Verified)

Two products the existing columns already support:

- **Featured** (`sponsored_until`) — top of Discover contractor list for the
  homeowner's city/specialty. **Labeled "مموّل".** Multiple sponsored in one
  segment **rotate** for fair impressions; cap slots per segment (e.g. 3). Flat
  **~199 EGP/week** (tunable).
- **Quote-boost** (`boost_until`) — pins the contractor's quote to the top of a
  homeowner's received-quotes list on jobs they quote. Flat **~49 EGP/job**
  (tunable).

**Eligibility:** must be **Verified** (any plan). Prevents promoting unvetted
contractors — brand/scam protection. Not Pro-gated.

**Flow:** same Paymob path as Pro but `purpose='sponsored'|'boost'`; webhook sets
`sponsored_until` / `boost_until`.

**Honesty:** sponsored placement is always visibly labeled so organic ranking
keeps meaning. No auction at launch (YAGNI) — flat rate only.

---

## 9. Phasing (build order)

1. **Verified** — table, bucket, upload UI, admin review, badge + filter. No
   payment dependency; ships trust and generates the eligibility gate + data.
2. **Freemium quota** — RLS rewrite (§5), quota counter, paywall triggers/locked
   leads UI.
3. **Pro via Paymob** — 2 edge fns, plan-select UI, checkout WebView, webhook.
4. **Sponsored** — Featured + Quote-boost purchase + rotation/label/pin render.

Add-on tuning (auction, dynamic caps) explicitly deferred.

---

## 10. Open defaults (chosen, tunable — flagged, not blocking)

- Free quota = **3 / calendar month**.
- Pro trial = **first month free**.
- Featured = **199 EGP/wk**, cap **3 slots/segment**, rotation on impression.
- Quote-boost = **49 EGP/job**.
- Portfolio free cap = **5**.

---

## 11. Non-goals (this spec)

- In-app chat, push notifications (separate track).
- Homeowner-side paid features.
- Auction-based placement.
- Automated (non-manual) verification.

---

## 12. Visual / UX design (impeccable shape brief)

Design probes generated (higgsfield, 3 lanes: drenched terracotta / restrained
cream / dark luxe). **Chosen: Hybrid** — Lane A drenched-terracotta aspirational
hero + Lane B Free-vs-Pro clarity table. Pharaonic/hieroglyph texture rejected
(tourist cliché, off "Modern Heritage"). Message reframed luxury → **contractor
ROI** (leads = money). Probes archived under `.probes/` (dev-only, gitignored).

**Register note:** the app is Restrained product UI; the Pro page is the one
surface that earns a **Committed/Drenched** override (like an onboarding welcome
or upsell). All other monetization surfaces (verify, sponsored, sheet) stay
closer to Restrained with terracotta accents.

**Tokens only** — `BatshColors` (primary terracotta `#9E3D18`, tertiary gold,
secondary olive, surface cream), `BatshTypography` (Cairo display for
price/headline, Tajawal body), `BatshRadius` (card 12–16, pill for chips/CTA),
`BatshShadows`, `BatshMotion`. No raw hex. RTL-native, all copy in `strings.dart`.

### 12.1 Pro subscription page (full screen, `/c/pro`)

Top → bottom (RTL):

1. **Hero band** (~38% height, drenched terracotta vertical gradient + soft
   radial glow behind the medallion; NO hieroglyph texture). Back arrow top-start.
   Gold premium medallion (crown/seal, `Icons.workspace_premium` styled or asset).
   Headline "شطب برو". Value line "خلّي شغلك ما يوقفش — عروض بلا حدود".
2. **Plan card** (cream, elevated, overlaps hero bottom edge):
   - Segmented toggle **شهري / سنوي**; annual carries a "وفّر شهرين" pill.
   - Price, tabular figures: "٢٩٩ ج" + "/شهر" (annual → "٢٩٩٠ ج/سنة").
   - ROI line: "عرض واحد ممكن يرجّع اشتراك السنة كله".
   - Benefit rows (gold check + label): عروض بلا حدود · ردّ على الطلبات المباشرة ·
     ترتيب أعلى في البحث · معرض أعمال بلا حدود · إشعار "شاف عرضك".
   - Primary CTA "ابدأ شهر مجاني" (trial) → checkout.
   - Microcopy: "تقدر تلغي في أي وقت".
3. **Free vs Pro table** (two columns الحالي / برو; rows with ✕ / ✓). Key row:
   "٣ عروض/شهر" vs "بلا حدود".
4. **Trust footer**: "الدفع عن طريق Paymob · آمن" + terms link (standalone label).

**States:** default · annual-selected (price crossfades) · CTA loading (spinner,
disabled) · payment error (inline row + "حاول تاني") · already-Pro ("أنت مشترك،
بينتهي في {date}" + manage/renew) · reduced-motion (no medallion animation).

### 12.2 Paywall sheet (bottom sheet, contextual) — replaces current stub

Fires at the moment of pain (quota hit / tap a locked lead / onboarding upsell).
- Reason line, context-specific: "خلصت الـ٣ عروض المجانية الشهر ده".
- 3 top benefits (not the full list — this is a nudge, not the store).
- Price + primary CTA "اشترك في برو" → opens checkout directly (keep momentum).
- Secondary "مش دلوقتي" dismiss.
Reuse the existing `paywall_sheet.dart` shell; swap inert button for checkout.

### 12.3 Locked-lead treatment (the want-driver)

On the opportunities feed for a free contractor at quota: matched leads render as
**blurred cards with a lock** + count ribbon "١٢ شغل اتطابق معاك — اشترك تشوفهم"
and, where known, an EGP value hint. This is the FOMO surface that feeds 12.2.
Above quota-remaining: subtle "باقي لك عرضين الشهر ده" chip.

### 12.4 Verified flow (`/c/verify`)

- **Entry:** completion nudge on contractor profile ("وثّق حسابك — العملاء
  بيثقوا في الموثّقين أكتر") + a "وثّق حسابك" row.
- **Verify screen:** one-line benefit, then upload slots (tap → camera/gallery):
  بطاقة (وش) · بطاقة (ضهر) · سيلفي وأنت ماسك البطاقة · [اختياري] رخصة/سجل. Submit CTA
  "ابعت للمراجعة".
- **States:** unverified (default) · pending ("قيد المراجعة، بنرد خلال ٤٨ ساعة") ·
  approved (badge + brief success) · rejected (reason + "ظبّط وابعت تاني").
- **Badge component** (new, reused everywhere): gold seal + check + "موثّق";
  render on `contractor_card`, contractor profile header, and quote rows.
  Unverified in discovery shows a muted "غير موثّق".

### 12.5 Sponsored purchase (`/c/promote`)

- **Gate:** must be Verified. If not → route to 12.4 first ("لازم توثّق حسابك
  الأول").
- Two products as tabs/cards: **ظهور مميّز** (Featured, top of discovery, per
  week) and **تمييز العرض** (Quote-boost, per job).
- Purchase sheet: pick duration (١ / ٢ / ٤ أسابيع for Featured), price, Paymob CTA.
  Preview the "مموّل" label as it will appear.
- **Active state:** "ظهورك المميّز شغّال لحد {date}".
- Discovery render: sponsored cards top of list, always labeled "مموّل", rotated
  among sponsored in-segment.

### 12.6 Motion (flutter_animate; product register = 150–250 ms, restrained)

- Hero medallion: scale + fade in once on entry (≤400 ms), reduced-motion → none.
- Benefit list: stagger 30–50 ms per row, first open only.
- Monthly/annual toggle: price crossfade (~200 ms).
- CTA press: scale to 0.97.
- Payment success: animated check.
- No orchestrated full-page load sequence beyond the medallion. Every animation
  has a reduced-motion path (`BatshMotion`).

### 12.7 Accessibility (ui-ux-pro-max)

- Touch targets ≥44 dp; 8 dp min spacing.
- Semantic labels on icon-only controls (back, upload slots, medallion decorative
  → excluded from semantics).
- Contrast: white/cream text on terracotta hero ≥4.5:1; gold reserved for large
  text / icons (≥3:1), never body. Price never color-only.
- Reduced motion respected. RTL mirrored throughout.
- Input: verified doc capture uses camera intent; no keyboard traps.

### 12.8 New strings (additive to `strings.dart`, class `S`)

Pro page (title/value/benefits/CTA/trial/ROI/annual-badge), plan toggle,
Free-vs-Pro rows, paywall reason variants, locked-lead ribbon + quota chip,
verify (entry/benefit/slot labels/pending/approved/rejected/reason), badge
"موثّق"/"غير موثّق", sponsored (product names/duration/active/label/gate). All
`_t(ar, en)`.

### 12.9 New/changed files (UI layer)

- New: `features/billing/presentation/pro_screen.dart`,
  `plan_toggle.dart`, `free_vs_pro_table.dart`,
  `features/verification/presentation/verify_screen.dart` (+ providers/repo),
  `features/verification/presentation/widgets/verified_badge.dart`,
  `features/promotion/presentation/promote_screen.dart` (+ purchase sheet).
- Change: `paywall_sheet.dart` (checkout wiring), `contractor_card.dart` (badge +
  sponsored label), opportunities feed (locked-lead + quota chip), discovery
  (sponsored sort/label + "موثّق فقط" filter), routes.
- Reuse: `BatshButton`, `BatshCard`, `BatshChip`, `BatshScaffold`, `PhotoPicker`,
  `BatshShimmer`.
