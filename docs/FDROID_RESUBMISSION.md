# F-Droid resubmission checklist — Onde Guardei?

Status checked 2026-11-02. The fdroiddata merge request !55304 (version 0.3.1) was closed by maintainer linsui for two stated reasons: the merge-request template was not followed and the app did not yet satisfy the policy requiring more than three months of maintenance. Do not reopen or submit a replacement until eligibility is verified.

## Before resubmitting

- [ ] Determine the first verifiable date of active upstream maintenance from Git history and releases. Confirm the F-Droid maintainer's interpretation of the three-month requirement; do not assume repository creation date alone is sufficient.
- [ ] Review the current F-Droid new-app merge-request template and fill out every required field; do not reuse the rejected free-form description.
- [ ] Ensure `fastlane/metadata/android/pt-BR/` and any required metadata, description and screenshots are committed and correctly located.
- [ ] Verify release tag `v0.3.1`, source revision, package ID, versionCode, source URL and checksum against the actual published artifact.
- [ ] Validate reproducible F-Droid build using the current fdroiddata recipe and capture CI output; resolve any remaining errors before a new MR.
- [ ] Verify APK signature/update path, including the README warning about differently signed preview builds. Never instruct users to uninstall without backing up their data.
- [ ] Check the existing RFP issue #4682 for new maintainer feedback and reference it in the next MR.

## Local validation when the development computer is available

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --release
```

These commands validate the Flutter project, but do **not** by themselves prove the F-Droid recipe builds. Review fdroiddata CI separately.

## Links

- Closed MR: https://gitlab.com/fdroid/fdroiddata/-/merge_requests/55304
- RFP: https://gitlab.com/fdroid/rfp/-/issues/4682
- Source: https://github.com/alunoadsnoite/onde-guardei

This is a preparation checklist, not a claim that F-Droid accepted the application or that the build passed.
