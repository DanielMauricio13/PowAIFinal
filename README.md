# PowAI

PowAI is an AI-assisted iOS fitness, nutrition, alarm, and day-planning companion. The app combines account-based onboarding, personalized workout generation, custom training sessions, food logging, progress charts, wake-up missions, time-block planning, HealthKit heart-rate display, Live Activities, Dynamic Island support, and a WidgetKit extension.

The app is built with SwiftUI. The current project target is iOS 26.0+ because the app uses newer APIs such as AlarmKit. The main app target is `Gym-app-ioss`; the Live Activity/widget extension target is `PowAI_WidgetExtension`.

## Feature Overview

### Account, Login, and Recovery

- User login with saved session support.
- Bearer-token authenticated backend requests.
- JWT/session token storage through KeychainAccess.
- Account creation with validation for:
  - first and last name
  - email format
  - password length
  - password confirmation
  - password strength
- Multi-step account recovery:
  - email entry
  - 6-digit verification code
  - resend cooldown
  - new password entry
  - password strength feedback
- Logout with local session cleanup.
- Account deletion from settings.
- Push notification device-token registration and backend upload when notification permission is granted.

### Onboarding and Fitness Profile

- Fitness questionnaire for personalization.
- Captures and stores:
  - gender
  - body type
  - fitness goal
  - training days per week
  - workout duration
  - workout location
  - experience level
- Final onboarding step for:
  - age
  - height
  - weight
  - metric/imperial conversion
- Terms and privacy notice acceptance before account creation.
- Explicit consent text for backend and third-party AI processing of fitness inputs, nutrition entries, food photos, activity data, and AI prompts.

### Home and Navigation

- Authenticated main app shell with tabs for:
  - workouts
  - nutrition
  - alarms/day plan
  - progress
  - user settings
- Welcome screen for signed-in users.
- Personalized copy and localized UI strings.
- App-wide background/theme handling.

### Training Plans and Workout Selection

- Workout home screen showing the user's generated training plan.
- Routine mode for a saved 30-day workout plan.
- Day selection with preview of:
  - target muscle group
  - exercise list
  - set and rep targets
  - estimated calories
- "Make Your Own" workout builder.
- Saved custom-workout list with start-later support.
- Delete saved custom workouts.
- HIIT workout generation by difficulty:
  - Beginner
  - Medium
  - Expert
- Regenerate HIIT workouts.
- Request alternate routines from the backend for the same muscle group.

### Custom Workout Builder

- Browse the exercise catalog by category.
- Search by exercise name or muscle group.
- View exercise cards with remote/cached exercise images.
- Select exercises into a custom workout.
- Save custom workouts to the backend.
- Start custom workouts from saved plans.
- Track custom workout exercise count and estimated total calories.

### Active Workout Sessions

- Exercise-by-exercise workout session flow.
- Displays:
  - current exercise
  - exercise description
  - reps
  - set count
  - estimated calories
  - remote exercise imagery
- Set/rest timer support.
- Local rest notifications.
- Haptic feedback.
- Add extra sets.
- Log set weight and reps.
- Mark sets complete.
- Switch set-weight display between pounds and kilograms.
- Save set weights to the backend.
- Fetch previous set weights.
- Replace the current exercise through the backend.
- Add one more generated exercise during a session.
- Share workout completion/challenge data.
- Completion summary with calories burned and navigation back home.

### Live Activities, Dynamic Island, and Heart Rate

- ActivityKit Live Activities for workout rest/recovery timing.
- Lock Screen and Dynamic Island presentation through `PowAI_WidgetExtension`.
- Workout Live Activity shows:
  - rest/recovery status
  - elapsed timer
  - current set
  - latest heart-rate reading when available
- HealthKit read-only heart-rate support during active workouts.
- Heart-rate monitoring can resume when an active workout Live Activity exists.
- Heart-rate zone coloring in app/widget UI.
- Workout Live Activity is prioritized over day-plan Live Activity when both exist.

### Nutrition Tracking

- Daily food log stored locally and synced with backend flows where applicable.
- Daily reset by date.
- Daily nutrition totals for:
  - calories
  - protein
  - carbohydrates
  - sugars
- Daily macro-goal rings using user targets.
- Add food through:
  - Smart AI text entry
  - manual macro entry
  - barcode scanning
  - camera/photo food analysis
- Smart entry sends food name, quantity, and serving context to the backend for macro estimation.
- Camera entry resizes/compresses selected food photos and sends them to the backend for nutrition analysis.
- Barcode entry uses Open Food Facts for packaged-food nutrition.
- Remove food entries.
- Clamp totals at zero when entries are removed.
- Save and remove favorite foods.
- Quick-add favorite foods later.
- Upload favorites to the backend.

### Meal Ideas

- Fetch meal ideas from the backend.
- Generate meal options from user-provided ingredients.
- Filter meal ideas by:
  - meal type
  - difficulty
- Add generated meals to the daily nutrition log.
- Respect English/Spanish app language selection.

### Progress Tracking

- Progress area with two modes:
  - lift history
  - body-weight history
- Lift dashboard:
  - fetch saved exercise set weights from the backend
  - group history by exercise
  - show total logged weight
  - show top lift
  - show logged set count
  - show exercise count
  - render Swift Charts line graphs
  - tap chart points for details
  - show set history
  - delete saved set-weight entries
- Body-weight dashboard:
  - fetch body-weight history from the backend
  - log today's weight
  - delete weight entries
  - show latest weight
  - show peak and low
  - show total change
  - render body-weight chart history
  - switch display between pounds and kilograms

### Alarms

- Alarm list and alarm editor.
- Create, edit, enable/disable, and delete alarms.
- Alarm configuration includes:
  - alarm name
  - time
  - repeat days
  - alarm sound
  - soft awakening
  - hide snooze button
  - wake-up check after dismissal
  - challenge difficulty
- Bundled custom alarm sounds.
- Alarm sound preview.
- AlarmKit scheduling with local-notification fallback behavior.
- Challenge missions for dismissing alarms:
  - math
  - typing phrase
  - memory sequence
  - QR/barcode scan
- Multiple missions can be combined on one alarm.
- Barcode/QR mission can scan or store a registered code.
- Active alarm screen requires successful mission completion before dismissal.
- Wake-up check scheduling after the alarm is dismissed.

### Day Plan

- Day planner for time-block scheduling.
- Date navigation for past, today, and future plans.
- Create, edit, delete, and mark time blocks complete.
- Time blocks include:
  - title
  - notes
  - start and end time
  - category
  - reminder before start
  - leave-time reminder
  - optional start alarm
  - recurrence
  - repeat days
  - recurrence end date
- Repeating block deletion options:
  - only this day
  - this and future days
  - all occurrences
- Backend caching for recently loaded day plans.
- Local scheduling for day-plan notifications and start alarms.
- Share day-plan blocks with friends/challenges.
- Apple Calendar integration:
  - request calendar access
  - load events for the selected date
  - show calendar title and event timing
  - import calendar events as day-plan blocks
  - prevent duplicate imports
- Day-plan Live Activity updates for:
  - current block
  - next block
  - status
  - category
  - block end time
  - leave time
  - next start time
- Day-plan Live Activity ends automatically when there is no current/upcoming block for today.

### Widget and Live Activity Extension

- `PowAI_WidgetExtension` renders ActivityKit presentations.
- Supports workout rest/recovery UI.
- Supports day-plan Lock Screen and Dynamic Island UI.
- Shows current/next day-plan information.
- Shows day-plan countdowns for block end, leave time, or next start.
- Uses shared `TimeTrackingAttributes` state.

### Localization and Personalization

- English localization.
- Spanish localization.
- Runtime app-language selection through `AppLanguageManager`.
- Localized app permission strings.
- Localized widget strings.
- Custom app backgrounds:
  - default theme
  - solid color
  - two-color gradient
- Appearance preferences stored in `UserDefaults`.
- Rive animation assets for login/onboarding UI.
- Bundled body-type visual assets.

### Privacy and Safety

- Privacy manifest included at `Gym-app-ioss/PrivacyInfo.xcprivacy`.
- App Store privacy worksheet included at `APP_STORE_PRIVACY.md`.
- Discloses collection/processing for:
  - account info
  - user identifiers
  - push device token
  - fitness profile
  - workouts
  - food logs
  - body-weight entries
  - selected food photos
  - alarms/day-plan/user-entered content
  - backend request metadata
- HealthKit heart-rate data is read only during active workouts for on-device display and Live Activity updates.
- HealthKit heart-rate samples are not stored on PowAI servers.
- AI-generated workouts, meal estimates, and nutrition analysis are guidance tools only and are not medical advice.

## Integrations

- PowAI backend API: configured in `Gym-app-ioss/Utilities/Constants.swift`.
- Open Food Facts: barcode nutrition lookup.
- HealthKit: read-only heart-rate monitoring during active workouts.
- ActivityKit: workout and day-plan Live Activities.
- WidgetKit: Lock Screen and Dynamic Island extension UI.
- AlarmKit: alarm scheduling and alarm permission usage.
- EventKit: Apple Calendar event import for Day Plan.
- UserNotifications: local notifications, alarm backups, reminders, and push registration.
- BackgroundTasks: registered processing task for timer-related background behavior.
- AVFoundation: alarm audio/sound preview and camera scanning support.
- Swift Charts: lift and body-weight progress charts.
- Rive: bundled animated UI assets.
- KeychainAccess: secure session token storage.

## Permissions and Capabilities

The app declares or uses permissions/capabilities for:

- Camera access for barcode/QR scanning and food-photo capture.
- Photo library access for selected food-photo nutrition analysis.
- Calendar access for Apple Calendar import into Day Plan.
- HealthKit read access for live heart-rate display.
- HealthKit background delivery entitlement.
- Live Activities.
- Push notifications.
- Time-sensitive notifications.
- AlarmKit usage.
- Background audio/processing modes.
- Portrait orientation.

## Project Structure

- `Gym-app-ioss/` - main iOS app source.
- `Gym-app-ioss/Views/` - SwiftUI screens for login, onboarding, workouts, nutrition, alarms, day plan, progress, and settings.
- `Gym-app-ioss/Model/` - app data models and services such as HealthKit, food, workout DTOs, Live Activity management, and heart-rate UI.
- `Gym-app-ioss/ViewModel/` - observable view models for exercise and workout data.
- `Gym-app-ioss/Utilities/` - persistence, authentication, HTTP helpers, constants, language management, ActivityKit attributes, notifications, and shared utilities.
- `Gym-app-ioss/Assets.xcassets/` - app icon, accent color, body-type images, and visual assets.
- `Gym-app-ioss/RiveAssets/` - Rive animation files.
- `Gym-app-ioss/AlarmSounds/` - bundled custom alarm sounds.
- `Gym-app-ioss/en.lproj/` and `Gym-app-ioss/es.lproj/` - localized app strings.
- `PowAI_Widget/` - WidgetKit and ActivityKit Live Activity UI.
- `Gym-app-ioss.xcodeproj/` - Xcode project, schemes, Swift package references, and workspace metadata.
- `APP_STORE_PRIVACY.md` - App Store privacy-label worksheet and review-note wording.

## Current Build Settings

- Main app bundle identifier: `io.Mauro.Gym-app-ios`.
- Widget extension bundle identifier: `io.Mauro.Gym-app-ios.PowAIWidget`.
- Display name: `POW AI`.
- Marketing version: `1.0`.
- Current build number: `20`.
- Minimum iOS version: `26.0`.
- App category: Health & Fitness.
- Swift version: 5.
- Swift packages:
  - KeychainAccess
  - RiveRuntime

## Getting Started

1. Open `Gym-app-ioss.xcodeproj` in Xcode.
2. Select the `Gym-app-ioss` scheme.
3. Confirm signing for both `Gym-app-ioss` and `PowAI_WidgetExtension`.
4. Confirm the backend URL in `Gym-app-ioss/Utilities/Constants.swift`.
5. Build and run on an iOS 26+ simulator or physical device.
6. Test HealthKit, Live Activities, Dynamic Island, camera scanning, AlarmKit, notifications, and real heart-rate behavior on a physical device whenever possible.

## App Store Distribution Checklist

- Archive the `Gym-app-ioss` scheme in Release.
- Upload through Xcode Organizer or App Store Connect.
- Confirm App Store Connect build selection for version `1.0` build `20` or the next incremented build.
- Complete App Store privacy answers using `APP_STORE_PRIVACY.md`.
- Provide a hosted privacy policy URL.
- Provide support URL.
- Provide screenshots for required device sizes.
- Complete age rating.
- Complete export compliance.
- Provide Review Notes with:
  - demo account credentials
  - backend availability note
  - HealthKit read-only heart-rate explanation
  - AI/photo nutrition processing explanation
  - AlarmKit and notification behavior explanation
  - calendar import explanation
- Confirm production APNs setup and notification behavior.
- Confirm all paid features, if any are added later, use Apple's in-app purchase rules.

## Developer Notes

- Authenticated endpoints rely on `AuthSession` and `applyBearerToken()`.
- Food entries and favorites use `UserDefaults` persistence.
- Daily nutrition totals reset/save around midnight.
- Custom workouts, alarms, day-plan blocks, weight entries, and set weights depend on backend DTOs matching the app's expected shape.
- Exercise images are fetched from the backend and cached locally.
- Day-plan data has a short in-memory cache to avoid repeated backend loads.
- Some filenames preserve historical spelling, such as `FisrtWindow.swift`, `staringWorkWindow.swift`, and `PersiatnceCalories.swift`.
- The repository may contain local Xcode state files; avoid committing user-specific workspace state unless intentionally needed.
