# Operator downloads

## Admin / User pool (10 accounts)

PGP-signed credential roster + fresh Android APK:

| Artifact | Link |
| --- | --- |
| **Signed roster** | [ADMIN_USER_POOL.txt.asc](./ADMIN_USER_POOL.txt.asc) |
| **Plain roster** | [ADMIN_USER_POOL.txt](./ADMIN_USER_POOL.txt) |
| **Signing public key** | [polybius-pool-pubkey.asc](./polybius-pool-pubkey.asc) |
| **Admin/user APK** | [../polybius-1.0.0-beta.1-admin-user-arm64.apk](../polybius-1.0.0-beta.1-admin-user-arm64.apk) |

Verify the signature:
```bash
gpg --import polybius-pool-pubkey.asc
gpg --verify ADMIN_USER_POOL.txt.asc
```

Pool operators: **NiteQueen**, **Artem3s** (admin) · **Cup1d!**, **Dyslex1c**, **WhyTwoK**, **M00nFox**, **V3ctorKid**, **Gl1tchCat**, **H0neyBad**, **PixelW1z** (user/agent).

## Earlier developer/admin cards

| Operator | Tier | Code | Card |
| --- | --- | --- | --- |
| **SpamKat2** | developer | `W1-66-3R` | [spamkat2.md](./spamkat2.md) |
| **Gam3.0n** | developer | `B1-66-3R` | [gameon.md](./gameon.md) |
| **KASP3R** | admin | `TR1-66-3R` | [kasper.md](./kasper.md) |

Treat all credentials as sensitive — they are baked into the first-install bootstrap of these BETA builds.
