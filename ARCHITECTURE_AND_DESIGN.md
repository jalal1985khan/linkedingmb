# SocialHive GMB Flutter App — Complete Architecture & Design System

> **Application Name**: SocialHive GMB Mobile  
> **Platform**: Flutter (iOS & Android)  
> **State Management**: Flutter Riverpod  
> **Navigation**: GoRouter  
> **Design Philosophy**: Modern Premium SaaS (Clean Cards, Glassmorphic Accents, Soft Borders, Micro-Gradients)  
> **Typography**: Google Fonts — Plus Jakarta Sans & Inter  

---

## 🎨 1. Design System & Visual Tokens

### 1.1 Color Palette (`AppColors`)

| Token | Hex Value | Role / Usage |
| :--- | :--- | :--- |
| `primary` | `#4A07E8` | Electric Purple — primary brand actions, active highlights, key CTAs |
| `primaryContainer` | `#633BFF` | Vivid Indigo — active navigation indicators, app bar titles |
| `secondary` | `#00677F` | Cyan Teal — secondary badges, contextual chips |
| `background` | `#FAF8FF` | Lavender Tint Background — premium soft off-white surface |
| `surface` | `#FFFFFF` | Crisp White — card containers, sheets, dialog surfaces |
| `surfaceContainer` | `#EAEDFF` | Light Indigo Tint — separators, soft card backgrounds |
| `border` | `#C9C3D9` | Outline Variant — standard card and input borders |
| `borderSoft` | `#E2E7FF` | Soft Accent Border — subtle card dividers and outlines |
| `textPrimary` | `#131B2E` | Deep Slate / Navy — primary headlines and labels |
| `textSecondary` | `#484556` | Slate Gray — body text, descriptions, timestamps |
| `success` | `#16A34A` | Emerald Green — success alerts, active status, published indicators |
| `error` | `#BA1A1A` | Crimson Red — error toasts, delete actions, pause warnings |
| `queuedBlue` | `#58A7E8` | Sky Blue — post queue status badges |

---

### 1.2 Gradients

```dart
// Brand Primary Gradient (Indigo to Electric Purple)
LinearGradient(
  colors: [Color(0xFF633BFF), Color(0xFF4A07E8)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)

// Sunset Pink Gradient (Accent Highlight)
LinearGradient(
  colors: [Color(0xFFFF52C1), Color(0xFFFF9E63)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)

// Cyan Gradient (Performance / Insights)
LinearGradient(
  colors: [Color(0xFF4CD6FF), Color(0xFF00CCF9)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)

// Green Gradient (Growth / ROI Metrics)
LinearGradient(
  colors: [Color(0xFF3CD5ED), Color(0xFF8CE158)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```

---

### 1.3 Typography System (`Google Fonts Plus Jakarta Sans`)

* **Headlines / Page Titles**: `Plus Jakarta Sans`, Bold (`w700` - `w800`), 16px – 22px
* **Section Titles**: `Plus Jakarta Sans`, Semi-Bold (`w600`), 14px – 16px
* **Body Copy**: `Plus Jakarta Sans`, Regular (`w400` - `w500`), 13px – 14px, line-height 1.45
* **Metadata & Captions**: `Plus Jakarta Sans`, Medium (`w500`), 11px – 12px

---

## 🏗️ 2. Project Architecture & Directory Structure

The app follows a **Feature-Driven Architecture** organized into Clean Data, Presentation, and Domain layers:

```
lib/
├── core/                                # Application Core
│   ├── config/                          # Base URLs and environment settings (ApiConfig)
│   ├── router/                          # GoRouter configuration (AppRouter)
│   └── theme/                           # AppColors, AppTheme, visual constants
│
├── data/                                # Data Layer (API Clients & Repositories)
│   ├── models/                          # BusinessProfile, AiRecommendation, Review, Post models
│   └── repositories/                    # Isolated REST API repositories:
│       ├── api_post_repository.dart     # GMB Posts CRUD & Publishing
│       ├── backend_auth_repository.dart # OAuth & Token validation
│       ├── backend_business_repository.dart # Profile, Services & Products CRUD
│       ├── gmb_analytics_repository.dart # Dashboard metrics & search insights
│       ├── gmb_autonomy_repository.dart  # AI Control, capability ladder & approvals
│       ├── gmb_blueprint_repository.dart # 30-Day Content Blueprint Strategy
│       ├── gmb_qa_repository.dart        # Google Q&A Engine
│       └── gmb_reviews_repository.dart   # Reviews inbox & AI de-escalation replies
│
├── features/                            # Feature Modules (UI & State Controllers)
│   ├── auth/                            # Splash, Google OAuth, Session Management
│   ├── business_flow/                   # Location Switcher, Onboarding, BusinessProfileScreen
│   ├── dashboard/                       # DashboardScreen, ReviewsScreen, AnalyticsDashboardScreen
│   ├── customers/                       # Services Management & Customer Actions
│   ├── posts/                           # CreatePostFlowScreen, PostEditorScreen, PublishedPostsScreen
│   ├── blueprint/                       # BlueprintPlannerScreen (30-Day Strategy Calendar)
│   ├── qa/                              # QAEngineScreen (Google Q&A Engine & FAQ Generator)
│   ├── autonomy/                        # AIControlScreen (Emergency Kill Switch & Approval Inbox)
│   ├── scheduler/                       # QueueScreen & SchedulerScreen (Post Calendar & Queue)
│   ├── settings/                        # AutomationSettingsScreen, AppSettingsScreen
│   ├── notifications/                   # NotificationEndDrawer & Unread Provider
│   └── shell/                           # MainShellScreen (Central Scaffold, Drawer, Bottom Nav)
│
└── shared/                              # Reusable UI Components
    └── widgets/                         # AppMediaPicker, Badges, Credit Widgets
```

---

## 🧭 3. Navigation & Screen Flow (`GoRouter`)

```
/splash ────────────────────────► Authentication Check
                                        │
           ┌────────────────────────────┴───────────────────────────┐
           ▼                                                        ▼
       /login                                              Has Location Selected?
   (Google OAuth)                                                   │
                                            ┌───────────────────────┴──────────────────────┐
                                            ▼                                              ▼
                                    /business/select                                     /home
                               (Location Discovery & Sheet)                     (MainShellScreen)
                                                                                           │
                                  ┌────────────────────────┬───────────────────────────────┴───────────────────────────────┬────────────────────────┐
                                  ▼                        ▼                                                               ▼                        ▼
                             Tab 0: Home              Tab 1: Reviews                                                  Tab 2: Services          Tab 3: Create Post
                          (DashboardScreen)          (ReviewsScreen)                                                (CustomersScreen)      (CreatePostFlowScreen)
                                  │
                                  ├─► Drawer: Strategy Blueprint (`/blueprint`)
                                  ├─► Drawer: Google Q&A Engine (`/qa`)
                                  ├─► Drawer: AI Control & Approvals (`/control`)
                                  ├─► Drawer: Post Queue (`QueueScreen`)
                                  ├─► Drawer: Published Posts (`PublishedPostsScreen`)
                                  ├─► Drawer: Automations (`AutomationSettingsScreen`)
                                  └─► Drawer: Business Profile (`BusinessProfileScreen`)
```

---

## ⚡ 4. Riverpod State Management Architecture

* **`authProvider`**: Watches user authentication state, token persistence in `FlutterSecureStorage`, and active user identity.
* **`activeLocationProvider`**: Global single source of truth for the currently selected Google Business Profile (`(auth_user_id, location_id)`). Switching locations immediately invalidates and refetches dashboard, blueprint, Q&A, and reviews.
* **`userCreditsProvider`**: Real-time credit monitoring (`availableCredits`, `isZeroCredits`, `isLowCredits`). Dynamically alerts users when automations are paused due to depleted credits.
* **`unreadNotificationsCountProvider`**: Polls and streams unread review alerts and post notifications directly into the top bar badge.

---

## 🔗 5. Backend REST API Integration Matrix

| Feature | Screen | API Endpoint | Description |
| :--- | :--- | :--- | :--- |
| **Blueprint Strategy** | `BlueprintPlannerScreen` | `POST /api/gmb/automation/generate-blueprint` | Generates 15–30 day content strategy |
| | | `GET /api/gmb/automation/blueprint` | Fetches active content blueprint |
| | | `POST /api/gmb/automation/blueprint/item/improvise` | AI re-writes slot with fresh creative angle |
| | | `POST /api/gmb/automation/render-and-schedule` | Pushes all concepts into Post Queue |
| **Q&A Engine** | `QAEngineScreen` | `GET /api/gmb/qa` | Fetches published questions on Google Maps |
| | | `POST /api/gmb/qa/generate` | AI generates 5 local high-intent FAQs |
| | | `POST /api/gmb/qa/post` | Publishes question and answer to Google |
| **AI Control** | `AIControlScreen` | `GET /api/gmb/autonomy/capabilities` | Fetches L0/L1/L2 capability ladder rules |
| | | `POST /api/gmb/autonomy/settings` | Updates autonomy levels per capability |
| | | `POST /api/gmb/autonomy/pause` | Emergency kill switch (pause/resume writes) |
| | | `GET /api/gmb/autonomy/approvals` | Fetches drafts pending human sign-off |
| | | `POST /api/gmb/autonomy/approvals/resolve` | 1-click Approve & Publish / Reject |
| **Products** | `BusinessProfileScreen` | `GET /api/gmb/products` | Loads products catalogue |
| | | `POST /api/gmb/products/analyze-website` | AI website product scraper |
| | | `POST /api/gmb/products` | Adds product (Title, Price, Description) |
| **Reviews** | `ReviewsScreen` | `GET /api/gmb/reviews` | Reviews inbox with star ratings |
| | | `POST /api/gmb/reviews/reply/enhance` | AI de-escalation & staff-safe reply |
| | | `POST /api/gmb/reviews/reply` | Submits reply to Google Business Profile |
| **Posts & Queue** | `QueueScreen` / `PostEditorScreen` | `GET /api/gmb/posts` | Loads scheduled calendar posts |
| | | `POST /api/gmb/posts/create` | Creates new draft/scheduled post |
| | | `POST /api/gmb/posts/publish` | Immediate publish to Google Maps |

---

## 🔒 6. Reputation & Account Isolation Protocols

1. **Location-Scoped Caching**: Every repository query strictly attaches `location_id`. Account A's settings never contaminate Account B.
2. **Review De-escalation Protocol**: 1–2 star reviews automatically trigger AI de-escalation, protect named staff members from public conflict, and provide a direct offline contact pathway.
3. **Emergency Autonomy Control**: If unexpected changes occur, the user can hit **"Pause All"** in `AIControlScreen` to immediately halt unattended writes.
