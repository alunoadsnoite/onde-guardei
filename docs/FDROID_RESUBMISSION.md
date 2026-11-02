# F-Droid resubmission — Onde Guardei?

Status checked 2026-11-02. The fdroiddata merge request [!55304](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/55304) (version 0.3.1) was closed by maintainer linsui for two reasons: the merge-request template was not followed and the app did not yet satisfy the policy requiring more than three months of maintenance.

The MR was reopened after both points were addressed.

## What changed in the resubmission

- The title now follows the required `New app: app name` format.
- The description follows the current `App inclusion` template (`Required`, `Strongly Recommended`, `Suggested`), with the checkboxes filled in.
- The three-month requirement is addressed through the policy exception for authors who maintain other apps on F-Droid. The author maintains these apps already merged in fdroiddata: [!52559](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/52559) (Bíblia Livre IPM), [!52554](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/52554) (TEA Kids), [!52413](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/52413) (FocusFeed), [!51985](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/51985) (RevisaCiclo) and [!50479](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/50479) (TEA Autonomia).
- The metadata file and source commit are unchanged from the previously validated head: `metadata/br.com.valdenor.ondeguardei.yml`, source `e0104fe546a925612dde78d2875e6524bbb087ab`, Flutter `abaf9c523780a608bd46686fd5e53740a07077f8`.
- Head pipeline [#3015318980](https://gitlab.com/alunoadsnoite/fdroiddata/-/pipelines/3015318980) passed all 9 jobs, and the MR is mergeable.

## Current status

- MR state: open, awaiting maintainer review.
- RFP: [rfp#4682](https://gitlab.com/fdroid/rfp/-/work_items/4682).
- The `New App` label could not be applied by the author through the GitLab API (permission denied); a maintainer or bot needs to add it.
- The three-month exception is interpretive. If it is not accepted, the objective criterion is met on **2027-01-21**, three months after the first upstream commit (`2026-10-21`).

## Rules for any further update

- Keep `metadata/br.com.valdenor.ondeguardei.yml` as the only file in the MR.
- Do not add summary, description, changelog or images to fdroiddata; they live in the upstream Fastlane folder.
- Keep the full 40-character source commit hash and update it if the upstream source changes.
- Re-run `fdroid lint`, `fdroid rewritemeta` and the fdroiddata pipeline after any metadata change.
- Do not open a second MR for the same app; update this one.

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

- MR: https://gitlab.com/fdroid/fdroiddata/-/merge_requests/55304
- RFP: https://gitlab.com/fdroid/rfp/-/issues/4682
- Source: https://github.com/alunoadsnoite/onde-guardei

This is a status record, not a claim that F-Droid accepted the application or that the build passed review.
