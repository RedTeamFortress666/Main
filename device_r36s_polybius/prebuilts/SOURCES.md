# Prebuilt APK sources (not committed)

Fetched from `cursor/v1-stable-logins-ios-b952` on RedTeamFortress666/Main.
Re-download with `./device_r36s_polybius/fetch-apks.sh`.

| Module | File on disk | Upstream | applicationId |
| --- | --- | --- | --- |
| Polybius | `Polybius/Polybius.apk` | `polybius/dist/polybius-v1-stable-user-android-arm64.apk` | `com.polybius.polybius.user` |
| PolybiusHq | `PolybiusHq/PolybiusHq.apk` | `polybius/dist/polybius-v1-stable-hq-android-arm64.apk` | `com.polybius.polybius.hq` |
| DoomsdayClock | `DoomsdayClock/DoomsdayClock.apk` | `polybius/dist/doomsday_clock/doomsday-clock-2.0.0-android-arm64.apk` | `com.polybius.doomsday_clock` |

SHA-256 (v1-stable branch blobs):

- user `bd20bf987f812937aafc9a5fe40870087ca7f03b78980c5932bd3b40c465dc4e`
- hq   `75bf9fe9b4c5f8ef32791ee463d08efc2d7835b293041209ba0eb4851a0f35c3`
- vault `509ae553b6948144659021fd2d6ce6b244144e9fdb1686f513f6cb5252653883`

User and HQ are separate packages, so both can be preinstalled.

Doomsday Clock 2.0.1 is **LAUNCHER only**, not `HOME`. Trebuchet stays the
system launcher until the vault APK adds `CATEGORY_HOME`.
