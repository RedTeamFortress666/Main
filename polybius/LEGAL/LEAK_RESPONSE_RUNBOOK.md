# Leak response runbook

*Do these in order. Evidence and key rotation come before any letter. Times are
targets, not promises. Prompt-tamper theatrics (`EULA.md` § 11,
`PHYSICAL_PAPER.md`) are not step one. Rotate keys first. Do not lead a
filing with the Oracle / Enigma / Colossus clause or the **6th rotor
LLÇ 2026*** smallprint.*

## 0. Triage — what escaped?

| Escaped | Severity | Jump to |
|---|---|---|
| A **build** (APK / IPA / web zip / Linux bundle), unmodified | Low — it was distributed anyway | §1, §3 |
| A **modified build** (gate, ticket, ledger or verifier patched out) | Medium | §1, §3, §4 |
| **Source code**, including unpublished branches | Medium–High | §1, §3, §4, §5 |
| The **private signing key** for invite / game-file tokens | **Critical** | §1, §2 immediately |
| Live **invite codes** or **signed tokens** | High | §1, §2 |
| Operator **credentials / Hive dumps** from a device | Handle as a personal-data incident, not as piracy | §1, then your data-breach process |

## 1. Preserve evidence (first hour)

For each location:

```bash
# Page as seen, with headers and timestamp
curl -sD - -o /tmp/leak/page.html "https://…"
date -u +%FT%TZ > /tmp/leak/fetched_at.txt

# The file itself, hashed
curl -sL -o /tmp/leak/copy.apk "https://…/file.apk"
sha256sum /tmp/leak/copy.apk | tee /tmp/leak/copy.sha256

# Compare against your own release
sha256sum build/app/outputs/flutter-apk/app-release.apk
```

Record in a dated log: URL, uploader handle, hash, whether the hash matches a
build you shipped (unmodified copy) or not (modified copy), screenshots with
the system clock visible, and who on your side looked. Web-archive the URL if
the service allows it.

If the copy is modified, note **what** was changed at the level of observable
behaviour ("login gate absent", "ledger shows CHAIN BROKEN on first run",
"trusted modulus differs"). Do not distribute your analysis of *how* it was
patched — that is a circumvention guide.

## 2. Rotate what can be rotated (first day)

- **Signing key leaked** — generate a new RSA-4096 pair offline (e.g.
  `openssl genrsa 4096`), point `tool/polybius_sign.dart` at the new private
  key, update `kProjectRsaModulusB64` in
  `lib/core/crypto/signature_service.dart`, ship a release, and instruct
  operators to set the new trusted modulus in the Developer panel on any
  copy that cannot be updated. Every token signed with the old key is now
  untrusted; re-issue them.
- **Invite codes / tokens leaked** — mark them used or expired in the
  Developer panel (`INVITE MANAGEMENT`) and mint replacements.
- **Pool seeds leaked** — POOL → randomise, then SYNC a fresh courier token to
  peers over QR. Old ciphertext under the leaked seed should be treated as
  readable.
- **Operator accounts** — Developer panel → `FORCE POOL RESET` logs everyone
  out and re-gates on PIN. Ask operators to change access keys.

The **patch ledger** is device-local and MAC-chained under each device's key.
It is evidence *on that device* that a weave record was tampered with; it is
not something you rotate.

## 3. Decide the route (first week)

```
Is the host a § 512 / DSA intermediary?  ──yes──▶ DMCA_TAKEDOWN_TEMPLATE.md
        │no
Do you know who did it?  ──yes──▶ CEASE_AND_DESIST_TEMPLATE.md
        │no
Monitor, re-check in 30 days, keep the evidence log.
```

Ask counsel before sending anything if **any** of these apply: the recipient
is a security researcher; the material is a quote or screenshot rather than a
copy; the copy is a fork of a public GitHub repo with no `LICENSE`; you intend
to raise anti-circumvention or trade-secret claims.

## 4. Public statement (optional)

If the leak is being discussed publicly, a short factual note is usually
better than silence or threats:

> A modified build of PØLYBĪUS is circulating at `[location]`. It is not ours.
> Builds we publish are listed at `[RELEASES.md / release page]` with SHA-256
> hashes. Modified builds may have had their authentication and integrity
> checks removed; do not enter credentials into them.

Publishing your official hashes is the single most useful thing here.

## 5. After the fact

- Commit a `LICENSE` if you still have none (see `LEGAL/README.md`).
- Add a `SECURITY.md` with a disclosure contact so the next finder has a
  route that is not a public repo.
- Note the incident and outcome in `RELEASES.md` or an internal log.
- Update the `CLIENT OWNED` and `COVER RECORD` residual text in the leak
  detector if the incident taught you something the wording should say.
