#!/usr/bin/env python3
"""Static policy tests for CRYPT3X OS — no Android tree required."""

from __future__ import annotations

import pathlib
import re
import unittest
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


def strip_xml_comments(text: str) -> str:
    return re.sub(r"<!--.*?-->", "", text, flags=re.S)


def strip_hash_comments(text: str) -> str:
    lines = []
    for line in text.splitlines():
        if line.lstrip().startswith("#"):
            continue
        lines.append(re.sub(r"\s+#.*$", "", line))
    return "\n".join(lines)


def host_sinks(text: str) -> set[str]:
    out: set[str] = set()
    for line in text.splitlines():
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        parts = s.split()
        if len(parts) >= 2 and parts[0] in {"127.0.0.1", "::1", "0.0.0.0"}:
            out.update(parts[1:])
    return out


def permission_names(xml_text: str) -> set[str]:
    root = ET.fromstring(strip_xml_comments(xml_text))
    return {el.get("name", "") for el in root.iter("permission")}


class BuildHygiene(unittest.TestCase):
    def test_local_manifest_allowlists_andr36oid_only(self) -> None:
        xml = strip_xml_comments(read("local_manifests/crypt3x.xml"))
        self.assertIn("github.com/andr36oid", xml)
        remotes = re.findall(r'fetch="([^"]+)"', xml)
        self.assertEqual(remotes, ["https://github.com/andr36oid/"])
        blob = xml.lower()
        for needle in (
            "gapps",
            "microg",
            "gmscore",
            "phonesky",
            "firebase",
            "sentry",
            "crashlytics",
            "googleapis",
            "themuppets",
        ):
            self.assertNotIn(needle, blob, f"forbidden remote/project token: {needle}")

    def test_untrack_is_not_auto_applied(self) -> None:
        apply = read("apply.sh")
        self.assertIn("untrack.xml is NOT copied automatically", apply)

    def test_production_build_desc_is_release_keys_user(self) -> None:
        mk = read("lineage_r36s_crypt3x.mk")
        desc = re.search(r'PRIVATE_BUILD_DESC="([^"]+)"', mk)
        self.assertIsNotNone(desc)
        self.assertIn("release-keys", desc.group(1))
        self.assertNotIn("test-keys", desc.group(1))
        self.assertIn("lineage_r36s_crypt3x-user", desc.group(1))

    def test_conceal_refuses_debug_keys(self) -> None:
        script = read("conceal-prebuilts.sh")
        self.assertIn("CRYPT3X_ALLOW_DEBUG_KEYS", script)
        self.assertIn('KS="${CRYPT3X_KS:-}"', script)
        self.assertNotIn("${CRYPT3X_KS:-/tmp/crypt3x-debug.jks}", script)


class GoogleAndTelemetry(unittest.TestCase):
    def test_no_google_dns(self) -> None:
        props = strip_hash_comments(read("hardening.mk"))
        sh = strip_hash_comments(read("rootdir/harden.sh"))
        overlay = strip_xml_comments(
            read("polybius_overlay/frameworks/base/core/res/res/values/config.xml")
        )
        text = "\n".join([props, sh, overlay])
        for bad in ("8.8.8.8", "8.8.4.4", "dns.google", "1.1.1.1"):
            self.assertNotIn(bad, text, f"unexpected resolver {bad}")
        self.assertIn("net.dns1=9.9.9.9", props)
        self.assertIn("dns.quad9.net", sh)

    def test_ntp_is_not_google(self) -> None:
        overlay = strip_xml_comments(
            read("polybius_overlay/frameworks/base/core/res/res/values/config.xml")
        )
        match = re.search(
            r'<string name="config_ntpServer"[^>]*>([^<]*)</string>', overlay
        )
        self.assertIsNotNone(match)
        self.assertEqual(match.group(1), "2.android.pool.ntp.org")
        sinks = host_sinks(read("network/hosts"))
        self.assertIn("time.android.com", sinks)
        self.assertIn("time.google.com", sinks)

    def test_captive_portal_urls_empty_and_google_sinked(self) -> None:
        overlay = strip_xml_comments(
            read("polybius_overlay/frameworks/base/core/res/res/values/config.xml")
        )
        https = re.search(
            r'<string name="config_captive_portal_https_url"[^>]*>([^<]*)</string>',
            overlay,
        )
        self.assertIsNotNone(https)
        self.assertEqual(https.group(1), "")
        self.assertIn("captive_portal_mode=0", strip_hash_comments(read("hardening.mk")))
        sinks = host_sinks(read("network/hosts"))
        self.assertIn("connectivitycheck.gstatic.com", sinks)
        self.assertIn("stats.lineageos.org", sinks)

    def test_gms_and_updater_stripped(self) -> None:
        mk = read("polybius.mk")
        for pkg in (
            "remove-GmsCore",
            "remove-Phonesky",
            "remove-GoogleServicesFramework",
            "remove-Updater",
            "remove-LineageStats",
            "remove-Chrome",
            "remove-ConfigUpdater",
        ):
            self.assertIn(pkg, mk)
        remove = read("prebuilts/remove/Android.mk")
        self.assertIn("LOCAL_MODULE := remove-Updater", remove)
        self.assertIn("LOCAL_MODULE := remove-GmsCore", remove)

    def test_location_overlays_disabled(self) -> None:
        overlay = strip_xml_comments(
            read("polybius_overlay/frameworks/base/core/res/res/values/config.xml")
        )
        self.assertIn(
            '<bool name="config_enableNetworkLocationOverlay">false</bool>', overlay
        )
        self.assertIn(
            '<bool name="config_enableFusedLocationOverlay">false</bool>', overlay
        )


class UsbAdbPhysical(unittest.TestCase):
    def test_adb_not_default_gadget(self) -> None:
        mk = read("hardening.mk")
        default = mk.split("else", 1)[0]
        default_code = strip_hash_comments(default)
        self.assertIn("persist.sys.usb.config=none", default_code)
        self.assertNotIn("mtp,adb", default_code)

    def test_usb_permission_dialogs_enabled(self) -> None:
        overlay = strip_xml_comments(
            read("polybius_overlay/frameworks/base/core/res/res/values/config.xml")
        )
        self.assertIn(
            '<bool name="config_disableUsbPermissionDialogs">false</bool>', overlay
        )
        self.assertNotIn(
            '<bool name="config_disableUsbPermissionDialogs">true</bool>', overlay
        )

    def test_apply_never_writes_world_hidraw(self) -> None:
        apply = strip_hash_comments(read("apply.sh"))
        self.assertNotIn("hidraw*              0666", apply)
        self.assertIn("/dev/ttyACM*              0660   system     system", apply)
        self.assertIn("Removed world-accessible hidraw", read("apply.sh"))

    def test_privapp_enforce(self) -> None:
        self.assertIn(
            "ro.control_privapp_permissions=enforce",
            strip_hash_comments(read("hardening.mk")),
        )


class Permissions(unittest.TestCase):
    def test_privapp_has_no_dangerous_runtime_perms(self) -> None:
        xml = read("permissions/privapp-permissions-polybius.xml")
        names = permission_names(xml)
        for perm in (
            "android.permission.CAMERA",
            "android.permission.ACCESS_FINE_LOCATION",
            "android.permission.ACCESS_COARSE_LOCATION",
            "android.permission.INTERNET",
            "android.permission.RECORD_AUDIO",
            "android.permission.READ_CONTACTS",
            "android.permission.WRITE_SECURE_SETTINGS",
            "android.permission.INTERACT_ACROSS_USERS",
            "android.permission.MANAGE_ROLE_HOLDERS",
        ):
            self.assertNotIn(perm, names)
        self.assertIn("android.permission.FACTORY_RESET", names)
        self.assertIn("com.polybius.doomsday_clock", xml)
        self.assertNotIn("com.polybius.polybius.user", strip_xml_comments(xml))

    def test_polybius_not_privileged(self) -> None:
        user = strip_hash_comments(read("prebuilts/Polybius/Android.mk"))
        hq = strip_hash_comments(read("prebuilts/PolybiusHq/Android.mk"))
        self.assertNotIn("LOCAL_PRIVILEGED_MODULE := true", user)
        self.assertNotIn("LOCAL_PRIVILEGED_MODULE := true", hq)

    def test_doomsday_does_not_steal_daijishou(self) -> None:
        mk = strip_hash_comments(read("prebuilts/DoomsdayClock/Android.mk"))
        self.assertNotIn("LOCAL_OVERRIDES_PACKAGES", mk)
        self.assertNotIn("Daijishou", mk)


class Usability(unittest.TestCase):
    def test_daijishou_not_removed(self) -> None:
        product = read("polybius.mk")
        remove = read("prebuilts/remove/Android.mk")
        self.assertNotIn("remove-Daijishou", product)
        self.assertNotIn("remove-Daijishou", remove)

    def test_cromite_not_removed(self) -> None:
        product = read("polybius.mk")
        remove = read("prebuilts/remove/Android.mk")
        self.assertNotIn("remove-Cromite", product)
        self.assertNotIn("remove-Cromite", remove)

    def test_usb_host_and_audio_not_stripped(self) -> None:
        product = read("polybius.mk")
        self.assertIn("android.hardware.usb.host.xml", product)
        self.assertIn("PRODUCT_PACKAGES += Files", product)

    def test_wifi_bt_default_off(self) -> None:
        defaults = strip_xml_comments(
            read(
                "polybius_overlay/frameworks/base/packages/SettingsProvider/res/values/defaults.xml"
            )
        )
        self.assertIn('<bool name="def_bluetooth_on">false</bool>', defaults)
        self.assertIn('<bool name="def_wifi_on">false</bool>', defaults)
        self.assertIn(
            '<bool name="def_wifi_scan_always_available">false</bool>', defaults
        )


class SysconfigAndHosts(unittest.TestCase):
    def test_power_save_only_vpn(self) -> None:
        xml = strip_xml_comments(read("sysconfig/crypt3x.xml"))
        self.assertIn("org.torproject.android", xml)
        self.assertIn("com.wireguard.android", xml)
        for pkg in (
            "com.brave.browser",
            "ch.protonmail.android",
            "org.fdroid.fdroid",
            "com.polybius.red_veil",
        ):
            self.assertNotIn(pkg, xml)

    def test_hosts_does_not_block_needed_services(self) -> None:
        sinks = host_sinks(read("network/hosts"))
        for keep in ("f-droid.org", "proton.me", "dns.quad9.net", "pool.ntp.org", "www.google.com", "google.com"):
            self.assertNotIn(keep, sinks)

    def test_usb_filter_has_no_wildcard_hid(self) -> None:
        xml = strip_xml_comments(read("permissions/polybius-usb-filter.xml"))
        self.assertNotIn('class="3"', xml)


class InitAndKernel(unittest.TestCase):
    def test_harden_script_clamps(self) -> None:
        sh = strip_hash_comments(read("rootdir/harden.sh"))
        for key in (
            "captive_portal_mode 0",
            "private_dns_specifier dns.quad9.net",
            "adb_enabled 0",
            "ble_scan_always_enabled 0",
            "lineage_stats_collection 0",
            "trust_restrict_usb 1",
        ):
            self.assertIn(key, sh)

    def test_bridge_disabled_and_localhost_documented(self) -> None:
        rc = read("rootdir/init.polybius.rc")
        self.assertIn("disabled", rc)
        self.assertIn("127.0.0.1", rc)
        py = read("scripts/polybius_bridge.py")
        self.assertIn("127.0.0.1", py)
        self.assertIn("never 0.0.0.0", py)

    def test_kernel_hardening_fragment(self) -> None:
        cfg = read("kernel/lineageos_r36s_polybius.config")
        self.assertIn("CONFIG_USB_ACM=y", cfg)
        self.assertIn("CONFIG_SECURITY_DMESG_RESTRICT=y", cfg)
        self.assertIn("# CONFIG_DEVMEM is not set", cfg)
        self.assertIn("# CONFIG_KEXEC is not set", cfg)


class FetchScripts(unittest.TestCase):
    def test_brave_is_opt_in(self) -> None:
        script = read("fetch-cover-apks.sh")
        self.assertIn("Skipping Brave", script)
        self.assertNotIn("brave-browser-apk-release.s3.brave.com", script)


if __name__ == "__main__":
    unittest.main()
