# App Store Privacy Labels

Use this worksheet when completing App Store Connect's App Privacy form for PowAI.
The answers below match `Gym-app-ioss/PrivacyInfo.xcprivacy` and the current app/backend behavior.

## Tracking

- Does the app use data for tracking? No.
- Does the app share data with data brokers? No.
- Does the app use data for third-party advertising or advertising measurement? No.

## Data Linked To The User

Mark these data types as collected, linked to the user's identity, not used for tracking, and used for App Functionality.

| App Store Connect category | Select | What PowAI collects |
| --- | --- | --- |
| Contact Info | Name | First and last name for account and social features. |
| Contact Info | Email Address | Account login, password recovery, friend invites, support identity. |
| Identifiers | User ID | Backend user IDs and auth/session identity. |
| Identifiers | Device ID | Push notification device token. |
| Health & Fitness | Fitness | Workouts, routines, exercises, sets, reps, lifted weight, challenge logs, activity/workout progress. |
| Health & Fitness | Health | User-entered profile/body/nutrition data, including age, gender, height, weight, goals, macros, food logs, water/nutrition estimates. |
| User Content | Photos or Videos | User-selected food photos sent for AI nutrition analysis. |
| User Content | Other User Content | Meals, food entries, day-plan items, alarms, friend shares/challenges, support/user-entered content. |
| Other Data | Other Data Types | Backend request metadata needed for account security, API operation, and support/debugging. |

## Purposes

For each selected data type, choose:

- App Functionality: Yes.
- Analytics: No, unless a separate analytics SDK is added later.
- Product Personalization: No.
- Developer Advertising or Marketing: No.
- Third-Party Advertising: No.
- Other Purposes: No.

## HealthKit Review Note

Use this in App Review Notes:

PowAI requests read-only Apple Health permission for heart rate. Apple Health heart-rate data is read only on the user's device during active workouts to display current BPM in the app and Live Activity. Heart-rate samples are not stored on PowAI servers, not sent to third-party AI services, not sold, not used for advertising, and not used for marketing. PowAI's App Privacy "Health" disclosure refers to user-entered body, weight, goal, macro, and nutrition data stored by PowAI for app functionality, not Apple Health heart-rate samples.

## Third-Party Processing Note

Use this wording for the privacy policy and review notes:

Some AI features send user-provided inputs, such as fitness profile details, workout requests, meal prompts, and selected food photos, to PowAI's backend and AI service providers only to generate requested workouts, descriptions, food estimates, or meal suggestions. PowAI does not use this data for tracking or advertising.

## Do Not Select Unless Added Later

- Contacts: PowAI does not request the user's address book.
- Location: PowAI does not request Core Location.
- Browsing History or Search History: PowAI does not collect browser history.
- Diagnostics: Do not select unless client-side crash or performance telemetry is added.
- Purchases: Do not select unless in-app purchases/subscriptions are implemented and collected.
