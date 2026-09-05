# Downloadable builds

No APK is committed to git. Debug-signed binaries are not published.

Get builds from GitHub Actions (see `../RELEASES.md`):

1. GitHub → **Actions** → **Build Polybius downloads** → **Run workflow**.
2. Download `polybius-android-apk` from the run artifacts.

Android CI **fails** unless repository secrets `ANDROID_KEYSTORE_BASE64` and
`ANDROID_KEY_PROPERTIES` are set. See `../BUILD.md` for local keystore setup.

## First run

There is no factory account. Create an operator id, a 12+ character password,
and a 6-digit PIN.

## Web / confidentiality

The web target stores keys in `localStorage`. Treat it as a preview, not a
confidentiality target. Native builds use the platform keystore.
