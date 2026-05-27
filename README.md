# PowAI Final

PowAI Final is an AI-powered iOS fitness app that combines personalized training, nutrition coaching, and real-time workout support in one experience. The app has evolved from a basic workout generator into a broader fitness companion with account flows, richer nutrition inputs, Live Activities, and a dedicated workout widget.

## What’s New in This Version
- A more complete onboarding flow with account creation, login, and profile management.
- Expanded nutrition logging modes: **Smart AI**, **Manual entry**, **Barcode scanning**, and **Camera-based food analysis**.
- Favorite foods for fast re-logging of common meals.
- Improved workout session tracking with Live Activities and Dynamic Island support.
- Rest-session widget enhancements that include set count, elapsed time, and heart-rate display.

## Core Features

### 1) Personalized Training
- AI-generated workout plans tailored to user profile and goals.
- Workout day selection and per-exercise breakdowns (sets/reps/calorie estimates).
- In-session rest tracking to support structured training.

### 2) Smart Nutrition Tracking
- Add foods using:
  - AI text-based interpretation.
  - Manual macro/calorie input.
  - Barcode scanning for packaged products.
  - Camera capture + AI analysis for meal estimation.
- Track calories, protein, carbs, and sugars against daily targets.
- Save and quickly re-add favorite foods.

### 3) Live Activities + Widget Experience
- Workout rest periods can be tracked with Live Activities.
- Dynamic Island and Lock Screen presentation for at-a-glance timing.
- Widget view surfaces:
  - Current set number.
  - Elapsed timer.
  - Heart-rate (BPM) with zone-based visual feedback.

### 4) Account & Profile Utilities
- Secure session flow with token-based authenticated requests.
- Profile retrieval and update paths.
- Additional account utilities such as recovery and settings views.

## Project Structure
- `Gym-app-ioss/` — Main iOS app source (views, models, utilities, view models).
- `PowAI_Widget/` — WidgetKit + ActivityKit implementation for workout Live Activities.
- `Gym-app-ioss.xcodeproj/` — Xcode project and schemes.

## Getting Started
1. Open `Gym-app-ioss.xcodeproj` in Xcode.
2. Select an iOS Simulator or physical device.
3. Build and run the app.
4. Create an account (or log in), complete onboarding, and start your plan.

## Privacy, Safety, and Disclaimer
PowAI Final stores account and activity-related data only for core app functionality (training, nutrition logging, and progress support). AI outputs are guidance tools and **not medical advice**. Always consult a qualified healthcare professional before changing diet, training intensity, or health routines.

---

If you are continuing development, keep this README aligned with new capabilities (especially onboarding, workout analytics, nutrition inputs, and widget behavior).
