# F-Droid review fixes — 27 October 2026

The existing packaging request is [RFP #4682](https://gitlab.com/fdroid/rfp/-/work_items/4682). It was moved from fdroiddata to fdroid/rfp; no duplicate request is needed. This is an inclusion request, not approval or catalog publication.

## Bot feedback addressed

- Add Fastlane metadata for pt-BR and en-US: title, summary, description, icon, screenshots and version-code changelogs. English translates the listing; the app UI is Portuguese.
- Add the official SHA-256 of the exact Gradle distribution used by this project. The checksum was obtained from services.gradle.org, without copying a value for another archive variant.
- Keep the draft recipe in fdroid.yml synchronized with metadata/br.com.valdenor.ondeguardei.yml, using a full release-source commit hash and tag-based updates.

Local validation with fdroidserver 2.4.5: rewritemeta and lint passed using the fdroiddata category configuration. Fastlane length, image presence, canonical package filename and version/tag matching were checked. These checks do not mean a full F-Droid build or binary scan has passed; that remains for the packaging pipeline.

## Flutter recipe and screenshots

The recipe pins Flutter abaf9c523780a608bd46686fd5e53740a07077f8 and release source b5256a393bd4af0a87f8878ef90edb967bd77e41. It removes local debug signing and prepares separate ARMv7, ARM64 and x86_64 builds with codes 31–33, derived from base code 3. The frozen lockfile is enforced. This is a draft packaging recipe; no new F-Droid-signed APK is claimed.

The 21 application tests passed; the optional screenshot renderer passed separately, Flutter analyze found no issues and formatting passed. Store screenshots render actual widgets using exclusively illustrative data; see fastlane/README.md. No new application behavior, release version or signing key was introduced.

The GitHub publishing-failure notification for run 40546074746 was followed by successful run 40546882279 at the same source commit 6fa9e8dec6db7fecfd9e7443aa4fdc0f1d8bd26a. It is a historical failed attempt, not evidence that the current publication remains failed.
