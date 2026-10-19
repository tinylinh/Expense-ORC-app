# Expense Orc

Expense Orc is an offline-first Flutter receipt and expense tracker. It is designed
for Android/iOS phones and follows the receipt → OCR → review → save workflow.

## Features

- Capture a receipt with the camera or choose an existing image.
- Recognize receipt text on-device with Google ML Kit; OCR does not upload images.
- Extract a likely merchant, total, and date with a Dart heuristic parser.
- Review and manually correct every field before saving.
- Keep receipt records in SQLite and copy receipt photos into app-private storage.
- Browse, search, filter by category/month, edit, and delete saved receipts.
- View category donut and weekly expense bar charts drawn with `CustomPainter`.
- Switch between Material 3 light and dark themes.

OCR is best-effort: receipt layouts and recognition quality vary. Missing fields
are left for the user to enter rather than guessed.

## Run locally

Requirements: Flutter/Dart matching the SDK constraint in `pubspec.yaml`, plus
an Android or iOS device/emulator. ML Kit text recognition is intended for
mobile; this project does not provide a desktop/web OCR implementation.

```sh
flutter pub get
flutter run
```

On iOS, open the generated Runner project through Flutter/CocoaPods and keep the
camera and photo-library usage descriptions in `ios/Runner/Info.plist`. The
Android image picker uses the platform camera/gallery intents.

## Verify

```sh
flutter analyze
flutter test
```

The parser tests cover common VND separators, total-label prioritization, date
validation, and missing data. Device testing is still needed for camera/gallery,
on-device OCR, persistent SQLite data, and image retention.

## Android release

Configure a private Android upload/release keystore using the Flutter Android
signing instructions, then build with:

```sh
flutter build apk --release
```

On Windows, Android's Gradle/CMake toolchain may reject project paths containing
non-ASCII characters. If the project is under such a path, map it to an ASCII
drive before running Flutter commands, for example:

```powershell
subst X: "C:\path\to\expense_orc"
Set-Location X:\
flutter build apk --release
```

Do not commit keystore files or passwords. The signed APK is written under
`build/app/outputs/flutter-apk/`. Test the APK on a physical Android device
before distribution.
