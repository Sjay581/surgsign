# SurgSign Desktop

A Windows desktop companion for the iOS **SurgSign** surgical-rounding app.
Residents can enter or edit patients on a Windows workstation, then generate a
handoff QR code and scan it with the iPhone app to transfer the full list.

This is **prototype software**. It is not a medical device and must not be used
with real PHI.

## Prerequisites

- Windows 10 (1809) or later
- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)

## Build

From the repository root:

```
dotnet build SurgSignDesktop/SurgSignDesktop.sln -c Release
```

## Run

```
dotnet run --project SurgSignDesktop/SurgSignDesktop/SurgSignDesktop.csproj
```

Or open `SurgSignDesktop.sln` in Visual Studio 2022 (17.8+) and press F5.

## Handoff workflow

1. Enter or edit patients on the desktop app.
2. Set the **Service** name and pick **AM** or **PM** in the header.
3. Click **Handoff**. A window shows a QR code and the payload size.
4. On the iPhone, open the SurgSign app and scan the QR code.

The Windows app emits the `SS3:` wire format (JSON → zlib → URL-safe base64).
That matches the iOS `CompressionService.encodeNative` decoder.

## Data storage

Patients are persisted as JSON at:

```
%APPDATA%\SurgSign\patients.json
```

Writes are atomic (temp file + rename). **Contents are not encrypted.** This is
the same posture as the iOS prototype — fine for development, not for clinical
use.

Saves happen automatically on any change (add, edit, delete, task toggle).

## Project layout

```
SurgSignDesktop/
├── SurgSignDesktop.sln
└── SurgSignDesktop/
    ├── App.xaml, MainWindow.xaml        WPF entry point
    ├── Models/                          Patient, Task, enums, TransferPayload DTOs
    ├── Services/                        Persistence, Compression (SS3), QR generation
    ├── ViewModels/                      MVVM plumbing + per-view state
    ├── Views/                           PatientList, PatientEdit, Handoff
    └── Themes/Colors.xaml               Dark palette
```

## Dependencies

- [QRCoder](https://www.nuget.org/packages/QRCoder) — QR bitmap rendering
- No other third-party packages. MVVM is hand-rolled.

## License / use

Internal prototype. Do not use with real patient data.
