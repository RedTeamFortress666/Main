# Prebuilt APK sources (not committed)

Fetched from `cursor/v1-stable-logins-ios-b952` on RedTeamFortress666/Main.
Re-download with `./device_r36s_polybius/fetch-apks.sh`, then hide icons with
`CRYPT3X_KS=/path/to/release.jks ./device_r36s_polybius/conceal-prebuilts.sh`.

Do **not** resign with the Android debug keystore. After a verified fetch,
append SHA-256 lines to `SHA256SUMS` and run `scripts/verify-prebuilts.sh`.

| Module | File on disk | Upstream | applicationId | Privileged |
| --- | --- | --- | --- | --- |
| Polybius | `Polybius/Polybius.apk` | `polybius/dist/polybius-v1-stable-user-android-arm64.apk` | `com.polybius.polybius.user` | no |
| PolybiusHq | `PolybiusHq/PolybiusHq.apk` | `polybius/dist/polybius-v1-stable-hq-android-arm64.apk` | `com.polybius.polybius.hq` | no |
| DoomsdayClock | `DoomsdayClock/DoomsdayClock.apk` | rebuild `doomsday_clock/` | `com.polybius.doomsday_clock` | duress only |

User and HQ are separate packages, so both can be preinstalled.
The vault starts them by class name (`com.polybius.polybius.MainActivity`).

Desk cover apps (see `fetch-cover-apks.sh`):

| Module | applicationId | Upstream |
| --- | --- | --- |
| Cromite | (AndR36oid tree) | default browser — do not replace |
| F-Droid | `org.fdroid.fdroid` | f-droid.org repo (1.23.x suggested) |
| Proton Mail | `ch.protonmail.android` | Proton official APK |
| Brave | `com.brave.browser` | **opt-in only** (`BRAVE_APK_URL`) |
| Darth Cherry | `com.polybius.red_veil` | `polybius/dist/darth-cherry-1.0.2-android-arm64.apk` |
