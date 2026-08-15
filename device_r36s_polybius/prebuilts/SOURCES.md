# Prebuilt APK sources (not committed)

Fetched from `cursor/v1-stable-logins-ios-b952` on RedTeamFortress666/Main.
Re-download with `./device_r36s_polybius/fetch-apks.sh`, then hide icons with
`./device_r36s_polybius/conceal-prebuilts.sh`.

| Module | File on disk | Upstream | applicationId |
| --- | --- | --- | --- |
| Polybius | `Polybius/Polybius.apk` | `polybius/dist/polybius-v1-stable-user-android-arm64.apk` | `com.polybius.polybius.user` |
| PolybiusHq | `PolybiusHq/PolybiusHq.apk` | `polybius/dist/polybius-v1-stable-hq-android-arm64.apk` | `com.polybius.polybius.hq` |
| DoomsdayClock | `DoomsdayClock/DoomsdayClock.apk` | rebuild `doomsday_clock/` 2.0.2+ | `com.polybius.doomsday_clock` |

SHA-256 after conceal (local, gitignored):

- user  `116c90f87b5c8bf7de6039449c5079e4d3a6cba7c03e34a45711fb1616552a11` (LAUNCHER stripped, debug-resigned)
- hq    `ef6433fa0d85480d35826e0c5a44a1c2e0250bb1b3725c639d2669805869ada4` (same)
- vault `8757019e8530aa24dbe981e27fdaa2d9f4bf6aa191f53a7954e9411c53b93009` (2.0.2+3, HOME)

Upstream v1-stable blobs (before conceal):

- user `bd20bf987f812937aafc9a5fe40870087ca7f03b78980c5932bd3b40c465dc4e`
- hq   `75bf9fe9b4c5f8ef32791ee463d08efc2d7835b293041209ba0eb4851a0f35c3`
- vault 2.0.1 `509ae553b6948144659021fd2d6ce6b244144e9fdb1686f513f6cb5252653883`

User and HQ are separate packages, so both can be preinstalled.
The vault starts them by class name (`com.polybius.polybius.MainActivity`).
