# MR Booth

Booth-level voter management for Kerala panchayat elections. Uses **Firebase Google Sign-In** with **Google Drive** and **Google Sheets** as the backend.

## Architecture

```
MRBooth/
├── App/                 # AppCoordinator, AppDelegate (Firebase)
├── Core/                # Strings, Theme, Fonts, Errors
├── Models/              # Voter, BoothProfile, KeralaLocalBodyCatalog
├── Services/
│   ├── Auth/            # FirebaseGoogleAuthService
│   ├── Drive/           # GoogleDriveService
│   ├── Sheets/          # GoogleSheetsService
│   └── Google/          # Scopes, API client
├── ViewModels/
├── Views/
└── Resources/           # KeralaLocalBodies.json
```

## Firebase & Google setup

1. Create a [Firebase](https://console.firebase.google.com) project and add an **iOS app** (bundle ID: `com.irshadtkd.writeaway.MRBooth`).
2. Download **GoogleService-Info.plist** → place in `MRBooth/GoogleService-Info.plist`.
3. Firebase → **Authentication** → enable **Google** sign-in provider.
4. [Google Cloud Console](https://console.cloud.google.com) (same project) → enable:
   - Google Drive API
   - Google Sheets API
5. OAuth consent screen → add scopes:
   - `https://www.googleapis.com/auth/drive.file`
   - `https://www.googleapis.com/auth/spreadsheets`
6. **URL scheme** — `MRBooth/Info.plist` must include your `REVERSED_CLIENT_ID` from `GoogleService-Info.plist` (already configured for this project). If you replace `GoogleService-Info.plist`, update the URL scheme in `Info.plist` to match.

See `MRBooth/GoogleService-Info.plist.example` for reference.

## Registration flow

1. User signs in with Google (Firebase Auth).
2. On **Registration**, user selects **District → Panchayath → Ward** (cascading lists from `KeralaLocalBodies.json`).
3. On submit, the app requests **Drive + Sheets** OAuth scopes, then creates:
   - `VoterManagement/{BoothName}/` folder in Drive
   - `voters` Google Sheet with column headers

## Session storage

User session, booth profile (registration), in-progress registration draft, access/refresh tokens, filters, and cached voters are stored in **UserDefaults** only (`SessionStore`). The app does not use Keychain for its own persistence.

After booth registration completes, district/panchayath/ward/booth and Drive/Sheet IDs are saved on the session. For **24 hours** after sign-in (or registration), reopening the app goes straight to the home screen without login or registration again.

## Gemini AI voter extraction

Scan and PDF upload use **Google Gemini** (not on-device OCR):

1. Create an API key at [Google AI Studio](https://aistudio.google.com/apikey).
2. In the app, open **Settings** → **AI Extraction (Gemini)** → paste the key → **Save API Key**.
3. Use **Scan Voter List** (camera, image, or PDF). Multi-page PDFs are processed page by page.

The key is stored in UserDefaults on the device only.

## Development without Firebase

If `GoogleService-Info.plist` is missing, the app uses **mock** auth/Drive/Sheets (UserDefaults). Add the plist to switch to production services automatically.

## Run

1. Open `MRBooth.xcodeproj` (Xcode resolves Firebase + GoogleSignIn SPM packages).
2. Select iPhone simulator → **Run** (⌘R).

## Expand local body data

Edit `MRBooth/Resources/KeralaLocalBodies.json` to add more panchayaths or wards per district.
