# PowAI

PowAI is an AI-assisted iOS fitness companion for training, nutrition, and progress tracking. It combines account-based onboarding, personalized workout plans, custom sessions, food logging, charts, HealthKit heart-rate support, Live Activities, and a dedicated ActivityKit widget.

The app is built with SwiftUI and targets iOS 17+. The main app target is `Gym-app-ioss`; the Live Activity/widget target is `PowAI_Widget`.

## What the App Does

### Account, Onboarding, and Profile

- Login with saved session support and bearer-token authenticated requests.
- Create an account with validation for names, email format, password length, password confirmation, and password strength.
- Recover an account through a multi-step password reset flow:
  - email entry
  - 6-digit verification code
  - resend cooldown
  - new password + strength feedback
- Complete a fitness questionnaire that captures:
  - gender
  - body type
  - goal
  - training days per week
  - session duration
  - training location
  - experience level
- Enter final onboarding data including age, height, and weight, with metric/imperial conversion.
- Accept the app terms before account creation.
- Update account settings after signup:
  - email address
  - full profile and fitness-goal data
  - daily macro targets
  - app background/theme
  - app language
- Log out, clear local session state, and delete the account.

### Training

- Shows a workout home tab with the user's generated training plan.
- Lets the user choose a workout day and preview:
  - muscle group
  - exercise list
  - sets and reps
  - estimated calories
- Supports a saved 30-day routine view with routine progress.
- Lets users create a custom workout from the full exercise catalog:
  - category browsing
  - search by exercise or muscle
  - exercise cards with cached remote images
  - selected-exercise strip
  - local save before starting the session
- Generates HIIT workouts on demand by difficulty:
  - Beginner
  - Medium
  - Expert
- Requests alternate workouts from the backend when the user wants a different routine for the same muscle group.
- During a workout session, users can:
  - view the current exercise, description, reps, set count, and estimated calories
  - load exercise images from the backend
  - run set/rest timers
  - receive local rest notifications
  - trigger haptic feedback
  - add an extra set
  - log set weight and reps
  - mark set completion
  - switch set-weight display between pounds and kilograms
  - replace the current exercise through the backend
  - add one more generated exercise
  - update routine exercise weight
- Workout completion summarizes the calories burned and offers a route back home.

### Live Activities, Dynamic Island, and Heart Rate

- Starts ActivityKit Live Activities during recovery/rest timing.
- Updates the Lock Screen and Dynamic Island with:
  - elapsed rest time
  - current set
  - latest heart-rate reading when available
- Uses HealthKit to request and monitor heart-rate samples.
- Displays heart-rate zone color feedback in the widget/Live Activity UI.
- Includes a `PowAI_Widget` target that renders the Live Activity presentation.

### Nutrition

- Logs today's food locally and resets daily food entries by date.
- Tracks daily nutrition totals for:
  - calories
  - protein
  - carbohydrates
  - sugars
- Shows compact daily-goal rings using the user's macro targets.
- Supports multiple food-entry modes:
  - Smart AI text entry
  - Manual macro entry
  - Barcode scanning
  - Camera/photo food analysis
- Smart entry sends food name, quantity, and serving context to the backend for macro estimation.
- Camera entry resizes/compresses food photos, sends them to the backend, and logs the decoded food result.
- Barcode entry uses Open Food Facts to read packaged-food nutrition.
- Users can remove food entries and keep totals clamped at zero.
- Favorites support:
  - favorite logged foods
  - remove favorites
  - quick-add favorites later
  - send favorites to the backend
- Meal ideas support:
  - fetch meal options from the backend
  - generate meals from ingredients
  - filter by meal type and difficulty
  - add generated meals to today's nutrition
  - respect English/Spanish language selection

### Progress Tracking

- Progress tab includes two modes:
  - Lifts
  - Body weight
- Lift progress dashboard:
  - fetches saved exercise set weights from the backend
  - groups history by exercise
  - shows total logged weight, top lift, logged set count, and exercise count
  - renders Swift Charts line graphs by set number
  - supports tapping chart points for details
  - shows set history
  - deletes saved set-weight entries
- Body-weight dashboard:
  - fetches user weight history from the backend
  - logs today's weight
  - deletes weight entries
  - shows latest, peak, low, and total change
  - charts body-weight history
  - toggles display between pounds and kilograms

### Localization and Personalization

- Ships English and Spanish localization files.
- Uses an app-level language manager to apply locale changes across SwiftUI.
- Supports custom app backgrounds:
  - default theme
  - solid color
  - two-color gradient
- Stores appearance preferences in `UserDefaults`.
- Uses Rive animations and bundled visual assets for the login/onboarding experience.

## Project Structure

- `Gym-app-ioss/` - main iOS app source.
- `Gym-app-ioss/Views/` - SwiftUI screens for login, onboarding, workouts, nutrition, progress, and settings.
- `Gym-app-ioss/Model/` - app data models and services such as HealthKit, food, workout DTOs, Gemini/API-key helpers, and Live Activity support.
- `Gym-app-ioss/ViewModel/` - observable view models for exercise/workout lists.
- `Gym-app-ioss/Utilities/` - persistence, authentication session, HTTP helpers, constants, app language, ActivityKit attributes, and shared layout/theme utilities.
- `Gym-app-ioss/Assets.xcassets/` - app icon, colors, body-type images, and visual assets.
- `Gym-app-ioss/RiveAssets/` - Rive animation files.
- `Gym-app-ioss/en.lproj/` and `Gym-app-ioss/es.lproj/` - localized strings.
- `PowAI_Widget/` - WidgetKit and ActivityKit Live Activity UI.
- `Gym-app-ioss.xcodeproj/` - Xcode project, schemes, package references, and workspace metadata.

## Integrations

- Backend API: configured in `Gym-app-ioss/Utilities/Constants.swift`.
- Google Generative AI: included through `generative-ai-swift` and `GenerativeAi-Info.plist`.
- Open Food Facts: used for barcode nutrition lookup.
- HealthKit: used for heart-rate monitoring during workout sessions.
- ActivityKit and WidgetKit: used for Live Activities, Lock Screen, and Dynamic Island workout timing.
- Swift Charts: used for lift and body-weight progress graphs.
- Rive: used for animated UI backgrounds/buttons.
- KeychainAccess, OpenAIKit, and OpenAISwift are present as Swift package dependencies.

## Permissions and Capabilities

The app declares permissions/capabilities for:

- Camera access for barcode scanning and food-photo analysis.
- HealthKit read access for live heart-rate display.
- HealthKit capability/background delivery in entitlements.
- Live Activities support.
- Portrait orientation.

## Getting Started

1. Open `Gym-app-ioss.xcodeproj` in Xcode.
2. Select the `Gym-app-ioss` scheme.
3. Confirm signing for both the main app and `PowAI_Widget` targets.
4. Confirm the backend URL in `Gym-app-ioss/Utilities/Constants.swift`.
5. Confirm any required API keys/configuration in `GenerativeAi-Info.plist`.
6. Build and run on an iOS 17+ simulator or physical device.

For HealthKit, Live Activities, Dynamic Island, camera scanning, and real heart-rate data, test on a capable physical device whenever possible.

## Notes for Developers

- The app relies on bearer tokens saved through `AuthSession`; authenticated endpoints call `applyBearerToken()`.
- Today's food entries and favorite foods are persisted in `UserDefaults`.
- Daily nutrition totals are persisted locally and reset/saved around midnight.
- Exercise images are fetched from the backend and cached on disk for custom-workout catalog cards.
- Several app flows depend on the backend returning workout, routine, meal, and set-weight DTOs in the expected shape.
- Some filenames preserve historical spelling, such as `FisrtWindow.swift`, `staringWorkWindow.swift`, and `PersiatnceCalories.swift`.

## Privacy and Safety

PowAI handles account, workout, food, body-weight, and heart-rate-related data to power its training and nutrition features. AI-generated workouts, meal estimates, and nutrition analysis are guidance tools only and are not medical advice. Users should consult a qualified healthcare professional before changing diet, training intensity, or health routines.
