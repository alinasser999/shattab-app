---
title: "Batsh — M1 Foundation Design"
date: 2026-05-14
status: approved-architecture
milestone: M1
---

# Batsh (بطش) — M1 Foundation Design

## 1. Context

**Product:** Batsh is an Egyptian contractor hiring marketplace. Homeowners discover, compare, and request renovation work from contractors; contractors manage leads, send quotations, and showcase portfolios.

**M1 scope:** The non-negotiable foundation that every later milestone depends on. After M1, a user can sign up by phone, pick a role, complete role-specific onboarding, and land on an empty role-specific shell. No discovery, no requests, no chat — those are M2–M4.

**Why M1 first:** Trying to build all features at once means every feature gets shallow attention. M1 is the chassis everything else bolts onto.

---

## 2. Approved Decisions (do not re-litigate)

| # | Decision | Reason |
|---|---|---|
| 1 | Decomposition into 4 milestones (M1–M4) | Original scope is too large for one spec; would produce a shallow design |
| 2 | Flutter + Supabase + Riverpod 2.x | User's existing stack; Riverpod pairs cleanly with Supabase streams |
| 3 | Android + iOS only (mobile-first) | Goal explicitly emphasizes "premium mobile UI" |
| 4 | Phone OTP for both roles | Egyptian market norm; phone IS the identity |
| 5 | Role locked at signup (homeowner OR contractor) | Cleaner RLS, simpler onboarding, matches goal's "two portals" framing |
| 6 | No verification flow in MVP (auto-verified) | Defers admin-tool scope, contractor is live immediately after onboarding |
| 7 | New Supabase cloud project, eu-central-1 region | ~80ms RTT to Egypt; required for real SMS |
| 8 | Feature-first code structure | Scales to 60+ screens cleanly |
| 9 | Single `go_router` + `StatefulShellRoute` per role | One source of routing truth, supports deep links |
| 10 | Stitch as primary visual reference, extracted in Step 0 | Goal: preserve Stitch design language |

---

## 3. Architecture

### 3.1 Code structure

```
batsh-app/
├── android/                          # platform shells
├── ios/
├── lib/
│   ├── main.dart                     # entrypoint: ProviderScope + MaterialApp.router
│   ├── app.dart                      # BatshApp widget
│   ├── core/
│   │   ├── theme/
│   │   │   ├── batsh_theme.dart      # populated from Stitch in Step 0
│   │   │   ├── batsh_colors.dart
│   │   │   ├── batsh_typography.dart
│   │   │   └── batsh_spacing.dart
│   │   ├── router/
│   │   │   ├── app_router.dart       # go_router config
│   │   │   ├── routes.dart           # route name constants
│   │   │   └── role_guard.dart       # redirect logic
│   │   ├── supabase/
│   │   │   ├── supabase_client.dart  # typed wrapper around supabase_flutter
│   │   │   └── supabase_provider.dart
│   │   ├── widgets/                  # reusable atoms
│   │   │   ├── batsh_button.dart
│   │   │   ├── batsh_text_field.dart
│   │   │   ├── batsh_card.dart
│   │   │   ├── batsh_scaffold.dart
│   │   │   ├── batsh_loading.dart
│   │   │   └── batsh_error.dart
│   │   ├── l10n/                     # generated localizations
│   │   ├── env/
│   │   │   └── env.dart              # flutter_dotenv wrapper
│   │   └── utils/
│   │       ├── extensions.dart
│   │       └── validators.dart       # phone, name validators
│   └── features/
│       ├── auth/
│       │   ├── data/
│       │   │   └── auth_repository.dart
│       │   ├── domain/
│       │   │   └── auth_state.dart
│       │   └── presentation/
│       │       ├── phone_entry_screen.dart
│       │       ├── otp_screen.dart
│       │       └── providers/
│       │           ├── auth_provider.dart
│       │           └── otp_provider.dart
│       ├── onboarding/
│       │   ├── data/
│       │   │   └── onboarding_repository.dart
│       │   ├── domain/
│       │   │   ├── homeowner_profile.dart      # freezed model
│       │   │   ├── contractor_profile.dart     # freezed model
│       │   │   └── onboarding_step.dart
│       │   └── presentation/
│       │       ├── role_select_screen.dart
│       │       ├── homeowner/
│       │       │   ├── apartment_type_screen.dart
│       │       │   ├── location_screen.dart
│       │       │   └── interests_screen.dart
│       │       ├── contractor/
│       │       │   ├── business_name_screen.dart
│       │       │   ├── specialties_screen.dart
│       │       │   ├── service_areas_screen.dart
│       │       │   ├── logo_upload_screen.dart
│       │       │   └── experience_screen.dart
│       │       └── providers/
│       │           └── onboarding_provider.dart
│       ├── shell/
│       │   └── presentation/
│       │       ├── homeowner_shell.dart        # bottom-tab scaffolding
│       │       └── contractor_shell.dart
│       ├── customer_home/
│       │   └── presentation/
│       │       └── discover_placeholder_screen.dart   # M2 fills this in
│       └── contractor_home/
│           └── presentation/
│               └── dashboard_placeholder_screen.dart  # M3 fills this in
├── assets/
│   ├── images/
│   ├── icons/
│   └── lottie/                       # if needed for transitions
├── docs/
│   └── specs/
│       └── 2026-05-14-m1-foundation-design.md
├── test/
├── pubspec.yaml
├── analysis_options.yaml
├── .env.example
├── .env                              # gitignored
└── README.md
```

### 3.2 Routing & navigation

**Library:** `go_router` (latest stable).

**Single router config** in `lib/core/router/app_router.dart`. Uses `StatefulShellRoute.indexedStack` to keep tab state per role.

**Top-level routes:**

```
/                            → splash, decides next destination
/login                       → phone entry (PhoneEntryScreen)
/login/otp                   → otp verification (OtpScreen)
/onboarding/role-select      → RoleSelectScreen
/onboarding/homeowner/...    → HomeownerOnboarding flow (multiple screens)
/onboarding/contractor/...   → ContractorOnboarding flow
/h                           → HomeownerShell (StatefulShellRoute)
   /h/discover               → DiscoverPlaceholderScreen
   /h/requests               → placeholder
   /h/saved                  → placeholder
   /h/profile                → placeholder
/c                           → ContractorShell (StatefulShellRoute)
   /c/dashboard              → DashboardPlaceholderScreen
   /c/inbox                  → placeholder
   /c/portfolio              → placeholder
   /c/profile                → placeholder
```

**Role guard / redirect logic** (`role_guard.dart`):

```pseudocode
redirect(state):
  session = ref.read(authProvider)
  if session is null:
    return '/login' unless already in /login/*
  profile = ref.read(currentProfileProvider).value
  if profile is null:
    return '/onboarding/role-select'
  if profile.onboardingComplete == false:
    if profile.role == 'homeowner':
      return next incomplete homeowner step
    else:
      return next incomplete contractor step
  if profile.role == 'homeowner' and current path starts with '/c':
    return '/h/discover'
  if profile.role == 'contractor' and current path starts with '/h':
    return '/c/dashboard'
  return null  # no redirect needed
```

### 3.3 State management

**Riverpod 2.x with code generation.** All providers use `@riverpod` annotation.

**Core providers** (M1 scope):

| Provider | Type | Purpose |
|---|---|---|
| `supabaseClientProvider` | `Provider<SupabaseClient>` | The singleton client |
| `authProvider` | `StreamProvider<Session?>` | Wraps `supabase.auth.onAuthStateChange` |
| `currentProfileProvider` | `FutureProvider<Profile?>` | Reads `profiles` row for current user |
| `onboardingStateProvider` | `NotifierProvider<OnboardingState>` | Tracks in-progress onboarding data |
| `otpControllerProvider` | `NotifierProvider<OtpState>` | Send / verify OTP, cooldown timer |

**Convention:** Repositories return raw `Future<T>`. Providers wrap them and expose `AsyncValue<T>` to widgets. Widgets never `await` directly.

### 3.4 Supabase schema

#### Tables

```sql
-- profiles: mirrors auth.users 1:1, holds role + universal fields
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('homeowner', 'contractor')),
  full_name text not null,
  phone text not null,
  avatar_url text,
  onboarding_complete boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index profiles_role_idx on profiles(role);

-- homeowner_profiles: 1:1 with profiles where role=homeowner
create table homeowner_profiles (
  profile_id uuid primary key references profiles(id) on delete cascade,
  apartment_type text not null check (apartment_type in (
    'studio', 'one_bedroom', 'two_bedroom', 'three_bedroom_plus',
    'duplex', 'villa', 'penthouse'
  )),
  city text not null,
  district text not null,
  renovation_interests text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- contractor_profiles: 1:1 with profiles where role=contractor
create table contractor_profiles (
  profile_id uuid primary key references profiles(id) on delete cascade,
  business_name text not null,
  logo_url text,
  bio text,
  specialties text[] not null default '{}',
  service_areas text[] not null default '{}',
  years_experience int,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index contractor_specialties_idx on contractor_profiles using gin (specialties);
create index contractor_service_areas_idx on contractor_profiles using gin (service_areas);
```

#### Triggers

```sql
-- Auto-create profiles row on auth.users insert
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, role, full_name, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'role', 'homeowner'),
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    new.phone
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();

-- updated_at maintenance
create or replace function tg_set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

create trigger set_profiles_updated_at before update on profiles
  for each row execute procedure tg_set_updated_at();
create trigger set_homeowner_updated_at before update on homeowner_profiles
  for each row execute procedure tg_set_updated_at();
create trigger set_contractor_updated_at before update on contractor_profiles
  for each row execute procedure tg_set_updated_at();
```

#### RLS policies

**`profiles`:**

```sql
alter table profiles enable row level security;

-- Anyone authenticated can read profile rows where the linked user is a contractor
-- (needed for customer discovery in M2). Homeowner profiles are private.
create policy "Read own profile"
  on profiles for select
  using (auth.uid() = id);

create policy "Read public contractor profiles"
  on profiles for select
  using (role = 'contractor');

create policy "Update own profile"
  on profiles for update using (auth.uid() = id);
```

**`homeowner_profiles`:** private to the owner.

```sql
alter table homeowner_profiles enable row level security;
create policy "Owner read/write homeowner profile"
  on homeowner_profiles for all
  using (auth.uid() = profile_id) with check (auth.uid() = profile_id);
```

**`contractor_profiles`:** publicly readable (M2 discovery), only owner writes.

```sql
alter table contractor_profiles enable row level security;
create policy "Anyone read contractor profile"
  on contractor_profiles for select using (true);
create policy "Owner write contractor profile"
  on contractor_profiles for insert with check (auth.uid() = profile_id);
create policy "Owner update contractor profile"
  on contractor_profiles for update using (auth.uid() = profile_id);
```

#### Storage buckets

| Bucket | Public | Purpose |
|---|---|---|
| `avatars` | yes | User avatars (homeowner + contractor) |
| `contractor-logos` | yes | Contractor brand logos |

Path conventions:
- `avatars/{user_id}/avatar.jpg`
- `contractor-logos/{user_id}/logo.jpg`

Storage policies: authenticated users can write to paths prefixed with their own `user_id`. Public can read.

### 3.5 Design system (BatshTheme)

Defined as a Dart class with semantic tokens, populated from Stitch in Step 0. **Do NOT use raw hex colors anywhere in feature code.** Always reference `theme.colors.surface.warm`, `theme.typography.headline.lg`, etc.

**Token categories:**

| Category | Examples |
|---|---|
| Color — Surface | background, warm, sunken, raised |
| Color — Brand | primary (terracotta), primaryMuted, accent (sand) |
| Color — Text | primary, secondary, muted, inverse |
| Color — Semantic | success, warning, danger, info |
| Color — Border | hairline, subtle, strong |
| Typography | display.lg/md/sm, headline.lg/md/sm, body.lg/md/sm, label.lg/md/sm |
| Spacing | scale [0,2,4,8,12,16,20,24,32,40,48,64] |
| Radius | none, sm (8), md (12), lg (16), xl (20), full |
| Shadow | none, soft, raised, floating |
| Motion | duration.fast/normal/slow + curves.smooth/spring |

Placeholder values used until Stitch extraction:

```dart
// lib/core/theme/batsh_colors.dart — PLACEHOLDER, replaced in Step 0
class BatshColors {
  static const Color surfaceBackground = Color(0xFFFAF5EE); // warm beige
  static const Color surfaceWarm = Color(0xFFF3EBDD);
  static const Color brandPrimary = Color(0xFFB85D3F);      // terracotta
  static const Color textPrimary = Color(0xFF2A2420);
  // ...
}
```

---

## 4. Step-by-step implementation order

Re-stated from the handoff doc for completeness:

1. **Step 0** — Stitch token extraction → populate `BatshTheme`
2. **Step 1** — `flutter create` + dep installation + main scaffold
3. **Step 2** — Supabase project provisioning via MCP
4. **Step 3** — Apply schema + RLS + triggers
5. **Step 4** — Type generation + `build_runner watch`
6. **Step 5** — Core infra (theme, router, widgets, supabase client)
7. **Step 6** — Auth feature (phone entry + OTP)
8. **Step 7** — Onboarding feature (role select + both flows)
9. **Step 8** — Shell + placeholder home screens
10. **Step 9** — Smoke test + demo seeds
11. **Step 10** — M1 completion log

---

## 5. Auth flow detail

### 5.1 Screens

1. **PhoneEntryScreen**
   - Country picker locked to +20 (Egypt) for M1; expand later.
   - Phone input with `phone_form_field` validator.
   - "Continue" → call `authRepo.sendOtp(phone)`.
   - Error states: invalid format, rate-limited, network error.

2. **OtpScreen**
   - 6-digit OTP input (Supabase default).
   - 60-second resend cooldown timer.
   - On success: call `authRepo.verifyOtp(phone, code)` → Supabase auth.
   - Trigger `handle_new_user` creates the profiles row.
   - Router redirect kicks user to `/onboarding/role-select`.

### 5.2 AuthRepository (data layer)

```dart
class AuthRepository {
  AuthRepository(this._client);
  final SupabaseClient _client;

  Future<void> sendOtp(String phone) =>
      _client.auth.signInWithOtp(phone: phone);

  Future<AuthResponse> verifyOtp(String phone, String code) =>
      _client.auth.verifyOTP(phone: phone, token: code, type: OtpType.sms);

  Future<void> signOut() => _client.auth.signOut();

  Stream<AuthState> watchAuthState() => _client.auth.onAuthStateChange;
}
```

### 5.3 Edge cases

| Case | Handling |
|---|---|
| OTP expired (>10 min) | Show error toast, enable resend |
| Wrong code | Inline error under input, allow retry without leaving screen |
| Network timeout | Retry button with exponential backoff |
| User backs out mid-OTP | Discard pending phone, return to phone entry |
| Resend too soon | Disable resend button + show countdown |

---

## 6. Onboarding flow detail

### 6.1 Role select

A single screen with two large cards: "صاحب شقة" (homeowner) and "مقاول" (contractor). Each card has an icon, a one-line tagline, and a tap area. Selection sets `profiles.role` immediately via repository call.

### 6.2 Homeowner flow

```
apartment_type → location → interests → done
```

| Step | UI | Field(s) written |
|---|---|---|
| Apartment type | Grid of cards (studio, 1BR, 2BR, 3BR+, duplex, villa, penthouse) | `homeowner_profiles.apartment_type` |
| Location | City picker (Cairo / Giza / Alexandria / etc.) + district picker | `homeowner_profiles.city`, `district` |
| Interests | Multi-select chips (paint, flooring, kitchen, bathroom, electrical, plumbing, full reno) | `homeowner_profiles.renovation_interests[]` |

After last step: set `profiles.onboarding_complete = true` → router pushes to `/h/discover`.

### 6.3 Contractor flow

```
business_name → specialties → service_areas → logo → experience → done
```

| Step | UI | Field(s) written |
|---|---|---|
| Business name | Text input + display name | `contractor_profiles.business_name`, `profiles.full_name` |
| Specialties | Multi-select chips (paint, plumbing, electrical, carpentry, flooring, design, etc.) | `contractor_profiles.specialties[]` |
| Service areas | City + district multi-select | `contractor_profiles.service_areas[]` |
| Logo upload | Image picker → upload to `contractor-logos` bucket | `contractor_profiles.logo_url` |
| Experience | Years input (number) + bio textarea | `contractor_profiles.years_experience`, `bio` |

After last step: set `profiles.onboarding_complete = true` → router pushes to `/c/dashboard`.

### 6.4 Resumability

`onboarding_complete` only flips at the end. Between steps, each field is written immediately to the DB. If the user closes the app mid-onboarding, the redirect guard reads the partial state and resumes at the first empty field.

---

## 7. Shells (placeholder content for M1)

### 7.1 HomeownerShell

`StatefulShellRoute.indexedStack` with 4 branches. Bottom tab bar with these labels (Arabic):

| Tab | Label | M1 content |
|---|---|---|
| Discover | اكتشف | "Coming in M2" placeholder card |
| Requests | طلباتي | placeholder |
| Saved | المحفوظات | placeholder |
| Profile | حسابي | shows profile data + sign out button |

### 7.2 ContractorShell

| Tab | Label | M1 content |
|---|---|---|
| Dashboard | لوحة التحكم | "Coming in M3" placeholder card |
| Inbox | الطلبات | placeholder |
| Portfolio | أعمالي | placeholder |
| Profile | حسابي | shows business data + sign out button |

Both shells follow the same `BatshScaffold` pattern with safe-area handling, status-bar styling matching the theme, and an animated tab indicator.

---

## 8. Out of scope for M1

Explicit list — do NOT build any of these in M1:

- Contractor discovery / search / filtering (M2)
- Contractor profile viewing (M2)
- Request creation, tracking (M2)
- Saved contractors (M2)
- Contractor dashboard cards / analytics (M3)
- Request inbox (M3)
- Quotation system (M3)
- Portfolio management (M3)
- Chat / realtime messaging (M4)
- Push notifications (M4)
- Reviews (M4)
- Admin tooling / KYC (post-MVP)
- Web platform (post-MVP)

---

## 9. Definition of M1 complete

M1 ships when **all** of these are true:

- [ ] App scaffold runs on Android emulator and iOS simulator with hot reload
- [ ] Stitch tokens fully populate `BatshTheme`; no raw hex outside the theme files
- [ ] Phone OTP signup works against the real Supabase project
- [ ] A new user lands on role-select after first signup
- [ ] Homeowner onboarding completes and routes to `/h/discover`
- [ ] Contractor onboarding completes and routes to `/c/dashboard`
- [ ] Logging out returns user to `/login` and clears local state
- [ ] Killing the app mid-onboarding resumes at the correct step on relaunch
- [ ] RLS policies tested with two seed accounts (homeowner cannot read another homeowner's profile)
- [ ] Both shells render with their 4 placeholder tabs
- [ ] All copy is in Arabic; RTL renders correctly
- [ ] `wiki/log.md` updated with M1 completion entry

---

## 10. Open risks

| Risk | Mitigation |
|---|---|
| Supabase phone OTP requires SMS provider config; Twilio sandbox limits accounts | For M1 demo, use sandbox + whitelist 2-3 numbers. Switch to production provider before M2 launch. |
| Stitch tokens may not be a clean 1:1 mapping to Flutter (e.g., Stitch uses CSS gradient stops) | Add manual mapping notes in `batsh_theme.dart`; document in step 0 output |
| Arabic font rendering on iOS differs slightly from Android (default Arabic font) | Bundle a single Arabic display font (likely IBM Plex Sans Arabic or similar) and use across both platforms |
| Phone number normalization (Egyptian numbers: +201xxxxxxxxx, leading-zero variants) | Use `phone_form_field` parser; store in E.164 format always |
| Supabase MCP requires OAuth interactive flow | Expect to prompt user once during Step 2 |

---

## 11. References

- Existing Femi app entity (Flutter+Supabase precedent): `c:\Users\LENOVO\Desktop\fovic vault\wiki\entities\femi-app.md`
- Stitch MCP endpoint: `https://stitch.googleapis.com/mcp`
- Supabase project region recommendation: eu-central-1 (Frankfurt)
- Flutter version target: latest stable (`>=3.24.0`)
- Dart SDK constraint: `>=3.5.0 <4.0.0`
