# PØLYBĪUS — Legal paperwork for hacked, stolen or leaked copies

> **Read this first.** These are drafting templates, not legal advice. Nothing
> in this folder creates an attorney–client relationship. Copyright, anti-
> circumvention, trade-secret and contract law differ by country and change
> over time. Have a lawyer licensed in your jurisdiction review anything before
> you send it, file it, or rely on it.

The code cannot stop a person who owns the device from patching the verifier
out of their own copy — the leak detector names that surface `CLIENT OWNED`
and keeps it **RESIDUAL** on purpose (see `BUILD.md`, "Security model"). This
folder is the remedy for that residual: paper, not patches.

## What is in here

| File | Use it when |
|---|---|
| `EULA.md` | Ship with every build. Sets the terms a cracked copy breaks. |
| `DMCA_TAKEDOWN_TEMPLATE.md` | A copy is hosted on a site / app store / file host that honours 17 U.S.C. § 512 (or an EU DSA Art. 16 notice). |
| `CEASE_AND_DESIST_TEMPLATE.md` | You know who is distributing or modifying the copy and want it to stop before litigation. |
| `LEAK_RESPONSE_RUNBOOK.md` | The moment you learn a build, key or invite has escaped. Evidence first, letters second. |

## Who the rights holder is

Fill in `[RIGHTS HOLDER]` everywhere with the legal name (person or company)
that owns the PØLYBĪUS source and assets. If that is unclear inside the team,
sort it out before sending anything — a notice from the wrong party is void
and, under § 512(f), can carry liability for misrepresentation.

In the arcade the nameplate reads `© 1981 SINNESLÖSCHEN CORP`. That is set
dressing. Sinneslöschen is not a real company and cannot be the sender.

## Licence status of the repository

There is currently **no `LICENSE` file** at the repository root. In most
jurisdictions that means *all rights reserved* by default: nobody has
permission to copy, modify or redistribute beyond what the law allows without
a licence (fair use / fair dealing, interoperability, backup copies, etc.).
That is the strongest footing for a takedown, but it also means honest
contributors have no licence either. Decide which you want and commit a
`LICENSE` accordingly. If you pick a permissive or copyleft licence later,
the DMCA route against **forks** narrows to licence-violation cases.

## What a "hacked copy" usually is, legally

| What happened | Primary hook | Notes |
|---|---|---|
| Rebuilt / re-signed APK, IPA or web bundle hosted elsewhere | Copyright (reproduction, distribution) | Straightforward § 512 notice. |
| Verifier / login gate / patch ledger patched out | Anti-circumvention (17 U.S.C. § 1201; EU InfoSoc Art. 6) + copyright | Only if the gate is a "technological measure" protecting the work; a lawyer should confirm. |
| Someone published the source, including private branches | Copyright; possibly trade secret if the source was kept confidential and marked as such | Trade-secret claims die the moment the material is public without protest — act quickly. |
| Leaked **private signing key** (`polybius_sign.dart` counterpart) or a real signed invite | Not primarily a legal problem — rotate the key first (`LEAK_RESPONSE_RUNBOOK.md`) | Then consider whether the leak itself was a contract or CFAA / Computer Misuse Act matter. |
| Trademark-style reuse of the name / logo | Trademark, passing off | Only if you have registered or established use of the mark. |

## Honest limits

- A takedown removes a copy from one host. It does not un-leak a binary.
- Anti-circumvention claims are contested territory; interoperability and
  security-research exemptions exist in the US and EU. Do not send § 1201
  language at a researcher who reported a bug to you.
- Encryption software may be subject to export controls (US EAR 5D002 with
  the mass-market / publicly-available notes; EU dual-use Regulation
  2021/821). That is a compliance question for the rights holder, not a hook
  against the leaker.
- Filing a false or reckless notice has consequences (§ 512(f); analogous
  provisions elsewhere). Every template here has a good-faith statement in it
  because the law requires one and because it should be true.
