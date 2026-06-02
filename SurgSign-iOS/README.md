# SurgSign — Native iOS App

A native SwiftUI iOS app for surgical rounding and shift handoff. Built from the same workflow as your PWA, with added native features:

- **Face ID lock** — patient data is gated behind biometric unlock and re-locks when the app goes to the background.
- **Peer-to-peer handoff** — two iPhones near each other can transfer the patient list directly using MultipeerConnectivity, no QR code or paste required.
- **QR code fallback** — for handoffs across longer distances, the same QR/paste flow your PWA uses.
- **Encrypted local storage** — patient records persist via SwiftData with Keychain-managed credentials.
- **Auto-purge** — configurable policy for clearing patient data after a defined inactivity window.

This project requires **iOS 17+** (uses SwiftData and the `@Observable` macro) and **Xcode 15+**.

---

## How to open and run this app

### 1. Unzip on your Mac

Drop the zip somewhere convenient — e.g. `~/Documents/SurgSign-iOS/` — and double-click to unzip.

### 2. Open in Xcode

Double-click `SurgSign.xcodeproj`. Xcode will open and show the project navigator on the left with the SurgSign source tree.

### 3. Set your signing team

This is the only manual config step needed:

1. In the project navigator (left sidebar), click the blue **SurgSign** project icon at the very top.
2. In the middle pane, select the **SurgSign** target (under "TARGETS").
3. Click the **Signing & Capabilities** tab.
4. Under "Team", choose your Apple ID from the dropdown.
   - If your Apple ID isn't listed: Xcode menu → **Settings** → **Accounts** → "+" → sign in with your Apple ID, then come back here.
5. The "Bundle Identifier" is currently `com.surgsign.app`. If Xcode complains it's already taken, change it to something unique like `com.sanjay.surgsign`.

### 4. Run on the simulator (no iPhone needed yet)

1. At the top of Xcode, next to the SurgSign scheme name, there's a device selector — click it and pick **"iPhone 15 Pro"** (or any iPhone simulator).
2. Click the ▶ Play button (or press ⌘R).
3. The simulator will boot and the app will launch. First run takes 30–90 seconds.

### 5. Run on your actual iPhone

1. Plug your iPhone into your Mac with a USB cable.
2. When iOS prompts "Trust This Computer?" on the phone, tap **Trust** and enter your passcode.
3. In Xcode's device selector, your iPhone should now appear at the top of the list. Select it.
4. Click ▶. The app will install and launch.
5. **First-time only**: iOS will refuse to open the app because the developer (you) isn't trusted yet. On your iPhone: **Settings → General → VPN & Device Management → [Your Apple ID] → Trust**. Then relaunch from the home screen.

That's it. The app runs natively, with no Safari, no internet required after install.

---

## File structure (so you know what's where)

```
SurgSign-iOS/
├── README.md                         ← this file
├── SurgSign.xcodeproj/               ← Xcode project (open this)
└── SurgSign/                         ← source code
    ├── SurgSignApp.swift             ← app entry point
    ├── Info.plist                    ← iOS permissions & bundle config
    ├── Assets.xcassets/              ← app icon, accent color
    ├── App/AppState.swift            ← global state (shift, service name)
    ├── Models/                       ← Patient, Task, Priority, TransferPayload
    ├── Persistence/                  ← SwiftData container setup
    ├── Services/
    │   ├── BiometricGate.swift       ← Face ID / Touch ID lock
    │   ├── MultipeerService.swift    ← peer-to-peer handoff
    │   ├── QRCodeService.swift       ← QR generation
    │   ├── SecureTransferCrypto.swift← payload encryption
    │   ├── KeychainService.swift     ← secure key storage
    │   ├── CompressionService.swift  ← payload compression
    │   ├── ExportImportService.swift ← JSON backup
    │   ├── TransferService.swift     ← orchestrates transfer flows
    │   └── PurgePolicy.swift         ← auto-clear inactive data
    ├── Utilities/                    ← color theme, date formatters, POD math
    ├── ViewModels/                   ← patient list & form view models
    └── Views/
        ├── Main/                     ← root ContentView, disclaimer screen
        ├── PatientList/              ← list, cards, shift toggle
        ├── PatientForm/              ← add/edit patient
        ├── Handoff/                  ← share + scan screens
        ├── Settings/                 ← settings screen
        └── Shared/                   ← reusable badge components
```

40 Swift files, ~5,500 lines of code. The architecture is MVVM with SwiftData for persistence.

---

## What you should see when the app runs

1. **First launch**: medical disclaimer screen. You must accept before proceeding.
2. **Main screen**: empty patient list with a "+ Add Patient" button at the bottom.
3. **Add a patient**: name, MRN, room, surgeon, diagnosis, procedure, surgery date (POD auto-calculates), code status, allergies, priority, notes, and a task list.
4. **Handoff**: tap the handoff button → you see two options:
   - **"Send to Nearby Device"** — uses MultipeerConnectivity. Other phone taps "Receive from Nearby Device" and they discover each other automatically.
   - **"Show QR Code"** — same QR flow as your PWA.
5. **Settings**: toggle Face ID lock, configure auto-purge window, export/import JSON backups.

---

## Known limitations & next steps

- **Not on the App Store yet**. To distribute beyond your own device, you need an Apple Developer Program membership ($99/year). After that, you can submit to TestFlight (internal testing) or App Store Review.
- **HIPAA**: same caveat as the PWA. The code uses Keychain, encryption, and biometric gating, but production clinical use requires institutional review and likely a BAA with whoever hosts/distributes the binary.
- **No server**: this is a fully offline app. The handoff is direct peer-to-peer or via QR. There's no cloud sync between devices outside the same room.
- **App icon is a placeholder**. The "S" on blue square in `Assets.xcassets/AppIcon.appiconset/` is auto-generated. Replace `AppIcon-1024.png` with a real design when you have one (1024×1024 PNG, no transparency).

---

## Troubleshooting

**"Failed to register bundle identifier"** — change the bundle ID in Signing & Capabilities (e.g. add your initials: `com.sanjay.surgsign`).

**"No account for team"** — Xcode → Settings → Accounts → add your Apple ID.

**Build fails with "Cannot find type X in scope"** — usually means a file isn't included in the target. Click the file in the navigator → File Inspector (right sidebar) → check "SurgSign" under Target Membership.

**Camera or Face ID prompt never appears** — check Info.plist has the usage description strings (it does in this project, but verify if you edit it).

**App icon shows as a question mark** — Xcode caches aggressively. Product menu → Clean Build Folder (Shift+Cmd+K) and rebuild.

---

Built to pair with the SurgSign PWA at https://sjay581.github.io/surgsign/. The native app and the PWA can exchange handoffs through the QR/paste path since they use compatible payload formats.
