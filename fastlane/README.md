# Store metadata

`en-US` translates the catalog listing; the app interface is Portuguese.

Descriptions, icons, screenshots and changelogs live in `metadata/android/`. Icons derive from this project's existing MIT-licensed launcher artwork. No private photos, catalogs or progress files are distributed here.

The screenshots are real Flutter widget renders using only illustrative objects and places. They do not claim device-camera or Android-file-picker validation. Regenerate using the pinned Flutter SDK:

```sh
GENERATE_STORE_SCREENSHOTS=1 STORE_SCREENSHOT_FONT="$FLUTTER_ROOT/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf" flutter test test/store_screenshots_test.dart
```

The renderer loads Flutter's Material icon font and Roboto for readable screenshots. Font files are not copied into this repository.
