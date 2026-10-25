# Expense Orc

Expense Orc is an offline-first Flutter receipt OCR and expense tracker for
Android and iOS. Scan a receipt, review and correct detected values, then keep
the verified expense and original image on the device.

## Features

- Capture a receipt using the camera or choose an existing image.
- Recognize text on-device with Google ML Kit Text Recognition.
- Parse likely merchant, VND total, and receipt date; uncertain values remain
  blank for manual entry.
- Review the source image and raw OCR text before saving.
- Store receipts in SQLite and copy images from temporary picker storage into
  app-private persistent storage.
- Browse, search, filter, edit, and delete saved receipts.
- Summarize actual receipt data with animated CustomPainter category and weekly
  charts.
- Use Material 3 light/dark themes.

## Architecture and data flow

```text
Camera/gallery
  → ReceiptScannerScreen
  → OcrService (on-device ML Kit; Latin recognition script)
  → ReceiptParser (Vietnamese keyword folding and conservative amount parsing)
  → ReceiptFormScreen (manual review and validation)
  → Riverpod receiptsProvider / ReceiptsNotifier
  → ReceiptRepository
  → AppDatabase (versioned SQLite) + app-private receipt images
  → Dashboard, history, and analytics
```

Presentation screens use Riverpod providers and do not execute SQL. The
repository performs parameterized CRUD operations. SQLite stores VND amounts as
integer đồng, date-only receipt dates, the saved image path, and raw OCR text.
The database schema is versioned and creates a category/date index when
migrating from version 1. An image is removed only after no remaining receipt
references that file.

The dashboard and category chart summarize the current calendar month. The
weekly chart uses the current Monday-through-Sunday calendar week. Both charts
are drawn with `CustomPainter` and update from saved receipts.

## Dependencies

- Flutter/Dart versions matching the `environment` constraint in
  `pubspec.yaml`.
- `flutter_riverpod` 2 for state management.
- `google_mlkit_text_recognition` for on-device OCR.
- `image_picker` for camera/gallery selection.
- `sqflite`, `path`, and `path_provider` for local persistence.
- `intl` for date and VND formatting.

The SQLite FFI package is a development dependency used by isolated database
tests; it is not part of the Android app's runtime data path.

## Setup and run

Install Flutter and Android Studio with the Android SDK, then run:

```sh
flutter pub get
flutter run
```

Choose an Android emulator or connected phone. OCR is implemented for mobile;
web and desktop platforms are not supported for this flow.

### Android permissions and configuration

The Android image picker uses the system camera and photo picker intents, so
the app does not request broad external-storage access or add a cloud service.
No additional Android manifest permission configuration is required by the
current picker flow. The image itself is copied to the app's private documents
directory after confirmation, and its stable path is saved in SQLite.

ML Kit is configured with its Latin text-recognition script. This includes
Latin-script Vietnamese text, but this project does not claim Vietnamese-
specific OCR accuracy or a dedicated Vietnamese model. Recognition quality
depends on image quality and the receipt layout; manually verify all fields.

For iOS, retain the camera and photo-library usage descriptions in
`ios/Runner/Info.plist`.

## Testing and analysis

```sh
dart format lib test
flutter analyze
flutter test
```

The test suite covers Vietnamese and international total labels, common VND
grouping, ambiguous decimal amounts, dates, missing/noisy data, model
serialization, and SQLite create/read/update/delete plus persistence in a
temporary database.

Device testing is still required for camera/gallery handoff, physical-device OCR,
offline use, app restart persistence, and image-file retention.

## Android release APK

Release builds use a private upload keystore when `android/key.properties` is
present. Create a keystore locally; do not commit it or its passwords:

```powershell
keytool -genkey -v -keystore android\expense-orc-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias expense-orc
```

Create `android/key.properties` locally with the following entries:

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=expense-orc
storeFile=../expense-orc-upload.jks
```

Both `android/key.properties` and Android keystore files are ignored by Git.
Then build the release APK:

```powershell
flutter build apk --release
```

The output path is `build/app/outputs/flutter-apk/app-release.apk`. Without
`android/key.properties`, Gradle does not sign the release APK; configure the
private key before distributing or installing a release build.

On Windows, Android's Gradle/CMake toolchain may reject project paths containing
non-ASCII characters. If that happens, map the project to an unused ASCII drive
letter before running Flutter commands:

```powershell
subst X: "C:\path\to\expense_orc"
Set-Location X:\
flutter build apk --release
```

Keep the keystore backup secure. Never add signing passwords, keystores,
`key.properties`, API keys, or local SDK paths to version control.

## Demo checklist

Record a 2–3 minute demo on a physical Android device showing:

1. Camera capture of a real receipt.
2. On-device OCR and detected merchant, date, and total.
3. Review of raw OCR text and manual correction of any values.
4. Saving the receipt and finding it in history.
5. Restarting the app to show persistence.
6. The animated category donut chart reflecting the saved receipt.

No demo recording or physical-device verification is included in this repository.

## Known limitations

- OCR and parser output are best-effort; users must verify before saving.
- Amounts with ambiguous decimal separators are left undetected rather than
  converted to an uncertain integer VND amount.
- ML Kit's Latin script is used; there is no claim of language-specific
  Vietnamese recognition accuracy.
- Data is local to the app installation and is not synchronized or backed up
  remotely.
- Android camera/gallery, ML Kit, and release installation behavior require
  device validation.
