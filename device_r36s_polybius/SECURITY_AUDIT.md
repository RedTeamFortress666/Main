# CRYPT3X OS — Safety + Privacy Audit

Audit of the AndR36oid / LineageOS 18.1 product overlay in
`device_r36s_polybius/` for the R36S (Rockchip RK3326) and compatible
panels. Threat model: malicious apps, network observers, physical SD
access, USB attacks. Target: GrapheneOS / CalyxOS / DivestOS / iodéOS
controls that still fit this 18.1 + 4.4 kernel + unsigned boot chain.

Policy tests: `python3 -m unittest discover -s device_r36s_polybius/tests -v`.

Severity: **C** critical · **H** high · **M** medium · **L** low · **I** info.
Status: **fixed** in this tree, **mitigated**, or **residual** (hardware /
unsigned boot / needs a full ROM rebuild to prove).

---

## 1. Build & source hygiene

| ID | Sev | Finding | Status |
| --- | --- | --- | --- |
| B1 | H | No roomservice allowlist; breakfast can pull arbitrary GitHub. | **fixed** — `local_manifests/crypt3x.xml` allowlists `andr36oid` only. Tests reject GApps / microG / firebase remotes. |
| B2 | H | `untrack.xml` `remove-project` of missing names aborts `repo sync`. | **mitigated** — apply.sh does **not** copy `untrack.xml` blindly. Package `OVERRIDES` strip Updater / GMS instead. |
| B3 | M | Product advertised `userdebug` + `test-keys` in `PRIVATE_BUILD_DESC`. | **fixed** — production lunch is `-user` / `release-keys`. userdebug remains for bring-up. |
| B4 | C | `conceal-prebuilts.sh` generated `CN=CRYPT3X` **debug** keystore (`android`/`android`). Anyone can resign "official" APKs. | **fixed** — refuses debug keys unless `CRYPT3X_ALLOW_DEBUG_KEYS=1`. |
| B5 | M | Cover APKs fetched over HTTPS but not pin-checked. | **mitigated** — `scripts/verify-prebuilts.sh` + optional `prebuilts/SHA256SUMS`. |
| B6 | I | Full Lineage tree is not vendored (correct). Nested clones stay gitignored. | **ok** |

Forbidden in local manifests / roomservice (enforced by tests): `gapps`,
`opengapps`, `mindthegapps`, `nikgapps`, `microg`, `gmscore`, `phonesky`,
`firebase`, `sentry`, `crashlytics`, `googleapis`.

---

## 2. Google / GMS / telemetry

| ID | Sev | Finding | Status |
| --- | --- | --- | --- |
| G1 | C | Captive portal still defaulted at Google (`connectivitycheck.gstatic.com`) if Settings.Global was unset. Properties alone do not always map. | **fixed** — empty overlay URLs + `captive_portal_mode=0` + boot `harden.sh` + `hosts` sink. |
| G2 | H | NTP default `time.android.com`. | **fixed** — `config_ntpServer=2.android.pool.ntp.org`, hosts block `time.android.com` / `time.google.com`. |
| G3 | H | Lineage Updater + stats phone home to Lineage CDN / `stats.lineageos.org`. | **fixed** — `remove-Updater`, `remove-LineageStats`, hosts, `persist.lineage.stats_disabled=1`. |
| G4 | H | GMS names only partially overridden (no Chrome, GSF feedback, ConfigUpdater, …). | **fixed** — expanded `prebuilts/remove`. |
| G5 | H | Default browser was **Brave** (Google Safe Browsing, usage pings, BAT). AndR36oid already had Cromite. | **fixed** — Cromite stays; Brave is `BRAVE_APK_URL` opt-in. |
| G6 | M | SUPL / A-GPS would hit `supl.google.com` if a GPS HAL appears. | **fixed** — `ro.gps.agps_provider=0`, assisted GPS default off. |
| G7 | M | Setup Wizard / backup transports. | **fixed** — `ro.setupwizard.mode=DISABLED`, backup default false, provisioned=true. |
| G8 | I | microG is not used (correct — it still talks to Google). | **ok** |

---

## 3. Network stack

| ID | Sev | Finding | Status |
| --- | --- | --- | --- |
| N1 | H | Fallback DNS was documented as Quad9 but ADB-on builds still leaked via captive portal / NTP. | **fixed** — Quad9 `net.dns*` + Private DNS `dns.quad9.net` on every boot. Tests ban `8.8.8.8` / `dns.google`. |
| N2 | H | `allow-in-power-save` for Brave / Proton / F-Droid / Cherry = background network in Doze. | **fixed** — exemptions only for Orbot + WireGuard. |
| N3 | M | Wi-Fi and Bluetooth default **on** (BT for "mesh") — radio identifier + scan leak. | **fixed** — both default **off**; scan-always off; MAC randomization kept. |
| N4 | L | Wi-Fi Direct permission remains (Daijisho / local play). | **kept** — usability; P2P MAC randomization overlay enabled. |
| N5 | I | No system-wide Tor. | **residual** — Orbot always-on VPN is the supported path. |

`harden.sh` re-clamps Global settings after `sys.boot_completed` so an app
cannot persist `captive_portal_mode=1` or `adb_enabled=1` across reboot
(unless `ro.crypt3x.dev_adb=1`).

---

## 4. Radios, sensors, location

| ID | Sev | Finding | Status |
| --- | --- | --- | --- |
| R1 | H | Fused / network location overlays could load microG stubs. | **fixed** — overlays false, provider package names empty. |
| R2 | M | `def_wifi_scan_always_available` was already false; BT-on defeated it. | **fixed** with BT default off. |
| R3 | L | R36S has no cellular modem; telephony packages already removed upstream. | **ok** |
| R4 | L | Camera / Recorder / Mic apps stripped (handheld has no useful camera). | **kept** — Polybius CAMERA is runtime, not priv-app. |

---

## 5. USB, ADB, physical

| ID | Sev | Finding | Status |
| --- | --- | --- | --- |
| U1 | C | `persist.sys.usb.config=mtp,adb` on every image. | **fixed** — `none` unless `CRYPT3X_DEV_ADB=true`. |
| U2 | C | `config_disableUsbPermissionDialogs=true` — BadUSB/HID auto-grant. | **fixed** — dialogs **on**. Wi-Fi dongles / ESP32 still work after one tap. |
| U3 | C | `apply.sh` wrote `/dev/hidraw* 0666 system system` (any app keylog/inject). | **fixed** — stripped; never re-added. ttyACM/ttyUSB stay **0660**. |
| U4 | H | USB accessory + host remain (needed for dongles / ESP32). | **mitigated** — host kept, grants explicit, Trust `trust_restrict_usb=1` when the Lineage setting exists. |
| U5 | C | Boot medium **is** the microSD. RK3326 has **no AVB**. Lost card = lost disk. | **residual** — documented; `BOARD_AVB_ENABLE=false` (honest). Do not fake verified boot. |
| U6 | H | Well-known factory duress PIN was published (`737380`). | **residual** in vault APK if still hardcoded — ROM docs no longer treat it as a secret; change on first setup. |

---

## 6. Permissions & privileged apps

| ID | Sev | Finding | Status |
| --- | --- | --- | --- |
| P1 | C | Polybius + HQ were `LOCAL_PRIVILEGED_MODULE := true` with CAMERA, FINE_LOCATION, INTERNET, BT in the priv-app allowlist (auto-grant). | **fixed** — modules unprivileged; those permissions **removed** from the allowlist. |
| P2 | C | DoomsdayClock had `WRITE_SECURE_SETTINGS`, `INTERACT_ACROSS_USERS`, `MANAGE_ROLE_HOLDERS` plus launcher overrides that **removed Daijishou**. | **fixed** — allowlist is duress-only (`MASTER_CLEAR` / `FACTORY_RESET` / `REBOOT` / `CHANGE_COMPONENT_ENABLED_STATE`). Daijishou is the emulation HOME. |
| P3 | H | `ro.control_privapp_permissions` not forced to `enforce` (userdebug may `log`). | **fixed** — `enforce`. |
| P4 | M | Orbot/WireGuard `BIND_VPN_SERVICE` in priv-app XML was unnecessary. | **fixed** — removed. |

---

## 7. SELinux

| ID | Sev | Finding | Status |
| --- | --- | --- | --- |
| S1 | H | No product sepolicy; bridge + harden script would run unlabeled or as init. | **fixed** — `sepolicy/crypt3x.te` + `file_contexts`; `BOARD_SEPOLICY_DIRS` via `BoardConfig-crypt3x.mk`. |
| S2 | M | `neverallow untrusted_app tty_device` can conflict with AndR36oid gadget rules and fail the build. | **mitigated** — omitted; nodes stay `system` 0660; comment records the goal. |
| S3 | I | 4.4 + Android 11 neverallow set is far from GrapheneOS. | **residual** |

---

## 8. Kernel (RK 4.4)

| ID | Sev | Finding | Status |
| --- | --- | --- | --- |
| K1 | H | USB ACM/serial enabled without hardening (DEVMEM, kexec, dmesg). | **fixed** — fragment + apply.sh: `SECURITY_DMESG_RESTRICT`, SYN cookies, disable DEVMEM/DEVKMEM/PROC_KCORE/KEXEC/MAGIC_SYSRQ when present. |
| K2 | I | Modern GrapheneOS options (CFI, SCS, PAN/UAO, `init_on_alloc`) are not in this 4.4 tree. | **residual** |
| K3 | L | USB HID for gamepads stays (evdev). hidraw is not world-writable. | **ok** |

---

## 9. Prebuilts / trackers

| ID | Sev | Finding | Status |
| --- | --- | --- | --- |
| A1 | H | Brave as default. | **fixed** — Cromite. |
| A2 | M | Proton Mail phones home to Proton (justified for mail). | **ok** — optional package, no Doze exemption. |
| A3 | M | F-Droid can install anything (`def_install_non_market_apps=true`). | **kept** — required for a de-Googled handheld; no privileged F-Droid extension. |
| A4 | L | PRESIGNED APKs — ROM does not re-sign with platform keys (good). Conceal path must use **release** keys. | **fixed** in conceal script. |

---

## 10. Storage, updates, logging

| ID | Sev | Finding | Status |
| --- | --- | --- | --- |
| D1 | C | No trustworthy FBE/AVB on SD-boot RK3326. | **residual** — treat SD as plaintext to a lab. |
| D2 | H | Lineage Updater. | **fixed** — removed; sideload / re-flash only. |
| D3 | M | MatLog stripped (already). `profiler.force_disable_ulog` / `nocheckin` / `persist.traced.enable=0` added. | **fixed** |
| D4 | L | `debug.sf.nobootanimation` debug property removed from product props. | **fixed** |

---

## 11. Usability (must not regress)

Kept or restored:

- **Daijishou** as emulation HOME (no longer overridden / phony-removed).
- **Cromite** as the de-Googled browser.
- USB **host** for Wi-Fi dongles and ESP32 CDC (grant dialog once).
- Audio HAL, panel DTBs, Files (OTG), gamepad HID/evdev.
- Optional Orbot / WireGuard for a device-wide IP path.
- Lite 8 GiB image path unchanged.

Radios default off: one extra toggle for Wi-Fi before netplay. That is
the privacy default, not a functional removal.

---

## 12. Residual risk (cannot fully close here)

1. Unsigned RK3326 boot + SD as the block device — evil maid wins.
2. Linux 4.4 kernel — unpatchable class of bugs; no CFI.
3. `userdebug` AndR36oid bring-up still exists; shipping `-user` is a
   process control, not a compiler guarantee.
4. Vault APK duress default, if still `737380`, is independent of this overlay.
5. Full `repo sync` + image build is **not** run in this workspace (~200GB).

---

## 13. Test map

| Control | Asserted in |
| --- | --- |
| No default ADB gadget | `test_hardening.py` → `hardening.mk` |
| USB permission dialogs on | overlay `config.xml` |
| No hidraw 0666 | `apply.sh` |
| No GApps remotes | `local_manifests/*.xml` |
| No 8.8.8.8 / time.android.com as NTP | hardening + overlay + hosts |
| Daijishou / Cromite not removed | `remove/Android.mk`, `polybius.mk`, DoomsdayClock.mk |
| Priv-app has no CAMERA/LOCATION | privapp XML |
| Polybius not privileged | `Polybius/Android.mk` |
| Power-save only VPN | `sysconfig/crypt3x.xml` |
| Conceal refuses debug keys | `conceal-prebuilts.sh` |
