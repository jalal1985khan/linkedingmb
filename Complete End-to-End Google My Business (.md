Complete End-to-End Google My Business (GMB) Architecture & API Reference for Mobile / Flutter App
Overview

This is the complete, end-to-end architectural summary of everything built for Google Business Profile (GMB) integration in SocialHive—from initial Google OAuth setup to live API publishing, AI Auto-Pilot blueprint generation, multi-collection database indexing, and post scheduling.

1. Google OAuth & Account Discovery Pipeline
1.1 OAuth 2.0 Authorization Flow
Scopes Required: https://www.googleapis.com/auth/business.manage
OAuth Connect Endpoint: GET /api/gmb-auth/connect
OAuth Callback Endpoint: GET /api/auth/google/callback
Token Storage: Encrypted Google access tokens and refresh tokens stored per user in MongoDB (gmb_tokens / users collection). Automatic token refresh handled by GMBAuthService.
1.2 Location Discovery & Account Details
Fetch Locations Endpoint: GET /api/gmb-auth/locations
Google APIs Used: MyBusinessAccountManagementAPI (v1) & MyBusinessBusinessInformationAPI (v1).
Extracted Location Fields:
location_id (e.g. locations/17709198911973906328)
title / displayName
primaryCategory & additionalCategories
storefrontAddress (street lines, locality/city, administrativeArea/state, postalCode)
websiteUri, primaryPhone
profile.description
1.3 Update Location Details
Endpoint: PATCH /api/gmb-auth/locations/{location_id}
Query Parameter: update_mask=title,websiteUri,profile.description
Rule: Google API prevents independent phone number updates; phone updates require full storefront address validation.
2. GMB Services & Products Engine
2.1 Live GMB Services API
Endpoint: GET /api/gmb-auth/locations/{location_id}/services
Google API: MyBusinessBusinessInformationAPI (serviceItems).
Extracted Services: Custom and structured category service items (e.g. Branding, Digital Marketing, SEO, Lead Generation, Web Design).
2.2 Product Catalog Management
Endpoint: GET /api/gmb/products?location_id={location_id}
Database Collection: db.gmb_products
Fields: name, category, price, description, imageUrl, isSpecial.
3. GMB Auto-Pilot AI Automation Engine
3.1 360° Business Context Extraction (get_business_context)
The engine gathers complete brand intelligence before generating any posts:

Location details & category profile (gmb_locations).
Live GMB services list (gmb_auth.get_location_services + gmb_services).
Product catalog (gmb_products).
Brand voice & personas (personas collection).
Brand knowledge base snippets & guidelines (knowledge_groups and data_sources).
Anti-Duplication History (gmb_posts and posts over last 60 days).
3.2 Strategy Blueprint AI Generator (generate_strategy_blueprint)
Endpoint: POST /api/gmb/automation/generate-blueprint
Payload:
json

{
  "location_id": "locations/17709198911973906328",
  "posts_per_week": 3,
  "user_role": "pro",
  "allowed_formats": ["TEXT_IMAGE", "PRODUCT", "SERVICE", "OFFER", "EVENT", "VIDEO", "TEXT_ONLY"],
  "auto_schedule": false
}
Post Formats Supported:
TEXT_IMAGE: Graphic/photo + 100-word caption + CTA (LEARN_MORE).
PRODUCT: Featured product copy + price/cta (SHOP).
SERVICE: Service spotlight + consultation CTA (BOOK).
OFFER: Promotional code (SPECIAL20) + terms + CTA (GET_OFFER).
EVENT: Community workshop/event title + CTA (SIGN_UP).
VIDEO: Behind-the-scenes video script + CTA (WATCH).
TEXT_ONLY: Informational updates + phone CTA (CALL_NOW).
AI Infrastructure:
Executes via central LLM (Nvidia Llama 3.1 70B / Gemini 2.5 Flash).
Configured with a 240s HTTP timeout for 70B model inference.
Implements Regex JSON Array Parsing (re.search(r'\[\s*\{.*\}\s*\]', ...)).
Employs dynamic context-aware fallback templates incorporating live product/service names if LLM is unavailable.
4. Multi-Collection Scheduler API
4.1 Get All Scheduled Posts
Endpoint: GET /api/scheduler/posts?page=1&limit=50
Database Query: Concurrently reads from scheduled_posts, linkedin_posts, and gmb_posts.
Field Normalization: Maps caption / summary / content -> content, topic / title -> title, scheduled_at / scheduled_time -> scheduled_time.
4.2 Update Scheduled Post
Endpoint: PUT /api/scheduler/posts/{post_id}
Features: Searches scheduled_posts, gmb_posts, and linkedin_posts using multi-field query (_id as ObjectId or string, matching auth_user_id or user_id). Updates caption, scheduled date, and image payload.
4.3 Delete Scheduled Post
Endpoint: DELETE /api/scheduler/posts/{post_id}
Features: Removes document from scheduled_posts, gmb_posts, or linkedin_posts. Front-end uses optimistic cache invalidation (queryClient.setQueriesData) for 0ms instant UI removal.
5. Direct GMB Post Publishing Engine
5.1 Google Business Profile Local Posts API
Endpoint: POST /api/gmb/locations/{location_id}/localPosts
Google API: MyBusinessLocalPostAPI / Google Business Profile API.
Payload Schema:
json

{
  "languageCode": "en-US",
  "summary": "Full post text content...",
  "callToAction": {
    "actionType": "LEARN_MORE",
    "url": "https://socialhive.pro"
  },
  "media": [
    {
      "mediaFormat": "PHOTO",
      "sourceUrl": "https://res.cloudinary.com/demo/image/upload/sample.jpg"
    }
  ]
}
6. Complete Flutter Data Models (Dart)
dart

class GMBLocation {
  final String locationId;
  final String title;
  final String category;
  final List<String> additionalCategories;
  final String address;
  final String? websiteUri;
  final String? primaryPhone;
  GMBLocation({
    required this.locationId,
    required this.title,
    required this.category,
    required this.additionalCategories,
    required this.address,
    this.websiteUri,
    this.primaryPhone,
  });
  factory GMBLocation.fromJson(Map<String, dynamic> json) {
    return GMBLocation(
      locationId: json['location_id'] ?? '',
      title: json['title'] ?? json['displayName'] ?? '',
      category: json['category'] ?? 'Business Services',
      additionalCategories: List<String>.from(json['additional_categories'] ?? []),
      address: json['address'] ?? '',
      websiteUri: json['websiteUri'],
      primaryPhone: json['primaryPhone'],
    );
  }
}
class ScheduledPost {
  final String id;
  final String content;
  final String? title;
  final DateTime scheduledTime;
  final String status;
  final String platform;
  final bool hasImage;
  final String? imageUrl;
  ScheduledPost({
    required this.id,
    required this.content,
    this.title,
    required this.scheduledTime,
    required this.status,
    required this.platform,
    required this.hasImage,
    this.imageUrl,
  });
  factory ScheduledPost.fromJson(Map<String, dynamic> json) {
    return ScheduledPost(
      id: json['id'] ?? json['_id'] ?? '',
      content: json['content'] ?? json['caption'] ?? json['summary'] ?? '',
      title: json['title'] ?? json['topic'],
      scheduledTime: DateTime.parse(json['scheduled_time'] ?? json['scheduled_at'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'pending',
      platform: json['platform'] ?? 'gmb',
      hasImage: json['has_image'] ?? false,
      imageUrl: json['image_url'] ?? json['media_url'] ?? json['image_data'],
    );
  }
}
