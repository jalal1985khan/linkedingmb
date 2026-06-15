# GMB AI App - Development Guide (Flutter, Mock-Data First)

This guide is for building a **fully functional Flutter UI with mock data first**, then connecting real Google/GMB and AI services in controlled phases.

---

## 1) Product Goal

Build an AI-driven Google Business Profile (GMB) assistant app where users:

1. Sign in with Google account (Gmail).
2. Fetch linked business profiles (if any).
3. If no profile exists, complete smart onboarding form.
4. Let AI analyze business context and propose optimizations.
5. User can either:
   - approve each suggestion manually, or
   - enable auto-apply for selected categories.
6. Auto-generate and auto-schedule posts/images supported by Google Business Profile.

For now: all flows should work end-to-end in UI using local mock repositories.

---

## 2) Theme Direction (from uploaded design)

Use a clean, soft, AI-modern style matching your screenshot:

- Primary accent: Indigo/Violet (`#5B5CE2`)
- Secondary accent: Lavender (`#A66BFF`)
- Soft background: Off-white (`#F8F9FC`)
- Surface cards: White (`#FFFFFF`)
- Borders/chips: Light gray/lilac (`#E4E7F2`, `#E9DEF8`)
- Success/queue hint: Sky blue (`#58A7E8`)
- Text primary: `#1F2430`
- Text secondary: `#6B7280`

Typography:
- Font: `Inter` or `SF Pro` fallback
- Rounded cards/chips (12-18 radius), subtle shadows
- Compact top nav + filter chips + feed card list

---

## 3) Recommended Flutter Stack

- **State management:** `flutter_riverpod`
- **Routing:** `go_router`
- **Networking:** `dio`
- **Modeling:** `freezed` + `json_serializable`
- **Local cache:** `hive` or `isar`
- **Auth adapter:** `google_sign_in` (mock first)
- **Image loading:** `cached_network_image`
- **Time/date:** `intl`

Keep repository interfaces stable so mock implementations can be swapped with production APIs later.

---

## 4) App Modules

Use feature-first structure:

```
lib/
  core/
    theme/
    constants/
    routing/
    widgets/
    services/
  features/
    auth/
    business_profile/
    onboarding/
    ai_insights/
    posts/
    scheduler/
    settings/
  data/
    models/
    repositories/
    mock/
```

---

## 5) Core User Flows

### A) Auth + Entry
1. Splash -> checks auth state.
2. Login screen with "Continue with Google".
3. On success -> profile fetch flow.

### B) Existing GMB Business Found
1. Show business selector (if multiple locations).
2. Load dashboard (queue, AI generated, scheduled posts).
3. Enable post generation + scheduling.

### C) No GMB Business Found (New User)
1. Guided onboarding form:
   - Business name
   - Category
   - Location/service area
   - Website/social links
   - Target audience
   - Tone/personality
   - Posting frequency
2. AI starts business analysis job (mock async states).
3. Show AI recommendations screen.
4. User chooses manual or auto-apply rules.

### D) AI Recommendation Lifecycle
1. Draft recommendation list (profile improvements, keywords, FAQs, posting strategy).
2. Per-item actions: Accept / Edit / Reject.
3. Auto-apply engine honors user preference.
4. History log for transparency.

### E) Post Scheduler
1. AI generates post drafts (caption + image suggestion + CTA).
2. User can edit draft.
3. Scheduler supports immediate or timed publish.
4. Queue view with statuses: Draft, Queued, Scheduled, Published, Failed.

---

## 6) Mock Data Strategy (Important for current phase)

Create repository contracts and mock implementations:

- `AuthRepository`
  - `signInWithGoogle()`
  - `signOut()`
  - `currentUser()`

- `BusinessRepository`
  - `getBusinessesForUser(userId)`
  - `getBusinessById(id)`
  - `createBusinessProfile(input)`

- `AiRepository`
  - `analyzeBusiness(profile)`
  - `getRecommendations(businessId)`
  - `applyRecommendation(id, mode)`

- `PostRepository`
  - `getPosts(filters)`
  - `generatePostDraft(promptContext)`
  - `schedulePost(postId, dateTime)`
  - `publishNow(postId)`

Mock behavior should simulate latency/errors using delayed futures to make UI realistic.

---

## 7) Screens to Build First (UI Complete with mocks)

1. Splash / Auth loading
2. Login (Google CTA)
3. Business selection / "No business found"
4. Onboarding form (multi-step)
5. AI analysis progress screen
6. AI recommendations (manual/auto apply)
7. SmartPost dashboard (matching uploaded design)
8. Post editor
9. Scheduler calendar/time picker
10. Settings + automation preferences

---

## 8) Data Models (Minimum)

- `AppUser`
- `BusinessProfile`
- `BusinessLocation`
- `AiRecommendation`
- `PostDraft`
- `ScheduledPost`
- `AutomationRules`
- `OperationLog`

All models should support JSON for easy API swap later.

---

## 9) Real Integration Plan (after mock UI is stable)

### Phase R1 - Google Auth (real)
- Integrate OAuth via Google Sign-In.
- Securely store tokens.

### Phase R2 - Google Business Profile APIs
- Fetch accounts + locations.
- Read profile details, media, and posting capabilities.

### Phase R3 - AI Backend
- Add backend endpoint layer:
  - business analysis
  - recommendation generation
  - post generation
  - safety filtering

### Phase R4 - Publish/Scheduler Integration
- Publish supported post types to Google Business Profile.
- Background job/cron (server-side) for scheduled posts.
- Retry + failure logging.

---

## 10) Security + Compliance Basics

- OAuth tokens must never be hardcoded in app.
- Use backend proxy for sensitive operations.
- Add user consent + audit log for auto-apply actions.
- Explicitly show when AI performed an automatic change.
- Keep "undo" and "disable automation" controls visible.

---

## 11) Development Phases and Milestones

### Phase 1 (Week 1): Foundation + Theme + Routing
- Setup project architecture, theme system, navigation, reusable widgets.
- Done when static screens navigate correctly.

### Phase 2 (Week 2): Mock Repositories + State
- Build all repositories/interfaces + mock implementations.
- Wire providers and async states (loading/error/empty/data).

### Phase 3 (Week 3): End-to-End Mock Product Flow
- Login -> business detect -> onboarding -> AI suggestions -> scheduler.
- Done when full app demo works without backend.

### Phase 4 (Week 4): Polish + QA
- Refine UX, animations, edge cases, offline behavior.
- Add widget tests + golden tests for critical screens.

### Phase 5+: Real Service Integrations
- Replace mocks module-by-module with real APIs.

---

## 12) Definition of Done for "Mock-Functional UI"

You can mark v1 complete when:

1. Every major flow is reachable from the app.
2. Data states are realistic (loading/error/success/empty).
3. Dashboard reflects queue and AI-generated cards like design.
4. Scheduler interactions are functional with mock persistence.
5. User can complete a full journey without dead ends.

---

## 13) Immediate Next Build Order

1. Create Flutter app shell + theme tokens.
2. Build reusable components:
   - top app bar
   - stat chips
   - filter chips
   - post card
3. Implement dashboard screen from screenshot.
4. Add auth and onboarding screens.
5. Connect all screens to mock repositories.
6. Add feature flags to switch mock -> real later.

---

## 14) Suggested Backlog (first implementation batch)

- [ ] Project bootstrap + dependencies
- [ ] Theme + design system
- [ ] App routing + guarded routes
- [ ] Mock auth flow
- [ ] Business profile fetch (mock)
- [ ] New business onboarding wizard
- [ ] AI recommendation center (mock)
- [ ] SmartPost dashboard (theme-matched)
- [ ] Post create/edit/schedule
- [ ] Automation settings + action logs

---

If you approve this plan, next step is to scaffold the Flutter app structure and implement the **dashboard UI + mock repository layer first**.
