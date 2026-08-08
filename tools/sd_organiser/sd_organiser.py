#!/usr/bin/env python3
"""POLYBIUS PRESS — stage SD card layouts and flash OS images safely.

Examples:
  python tools/sd_organiser/sd_organiser.py list-profiles
  python tools/sd_organiser/sd_organiser.py stage --profile r36s-lineage --mode dual_card --polybius
  python tools/sd_organiser/sd_organiser.py flash --image ./lineage.img --disk /dev/sdX
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
import textwrap
from pathlib import Path

PROFILES = {
    "r36s-arkos": {
        "name": "R36S · ArkOS / dArkOS",
        "family": "r36",
        "modes": ["single", "dual_card", "dual_os_swap"],
        "polybius": "port",
    },
    "r36s-rocknix": {
        "name": "R36S · ROCKNIX",
        "family": "r36",
        "modes": ["single", "dual_card", "dual_os_swap"],
        "polybius": "port",
    },
    "r36s-lineage": {
        "name": "R36S · LineageOS (AndR36oid)",
        "family": "r36",
        "modes": ["single", "dual_card", "dual_os_swap"],
        "polybius": "apk",
        "notes": [
            "Flash clean install images from andr36oid/release_uploads — not OTA zips.",
            "After first boot TF1 is often f2fs; use TF2 for ROMs / extras.",
            "Optional: empty .noroms on BOOT before first boot to give storage to Android.",
        ],
    },
    "lilygo-tdeck": {
        "name": "LilyGO T-Deck",
        "family": "esp32",
        "modes": ["single"],
        "polybius": None,
    },
}


def die(msg: str, code: int = 1) -> None:
    print(f"error: {msg}", file=sys.stderr)
    raise SystemExit(code)


def cmd_list_profiles(_: argparse.Namespace) -> None:
    for pid, meta in PROFILES.items():
        modes = ", ".join(meta["modes"])
        print(f"{pid:16}  {meta['name']}  [{modes}]")


def write_readme(path: Path, body: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(textwrap.dedent(body).lstrip() + "\n", encoding="utf-8")


def build_tree(profile_id: str, mode: str, polybius: bool, out: Path) -> list[str]:
    meta = PROFILES[profile_id]
    created: list[str] = []

    def touch_dir(rel: str) -> Path:
        p = out / rel
        p.mkdir(parents=True, exist_ok=True)
        created.append(str(p.relative_to(out)))
        return p

    def touch_file(rel: str, body: str) -> None:
        p = out / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(textwrap.dedent(body).lstrip() + "\n", encoding="utf-8")
        created.append(str(p.relative_to(out)))

    touch_dir("downloads")
    touch_file(
        "MANIFEST.json",
        json.dumps(
            {
                "profile": profile_id,
                "mode": mode,
                "polybius": polybius,
                "name": meta["name"],
            },
            indent=2,
        )
        + "\n",
    )

    if meta["family"] == "esp32":
        touch_file(
            "FLASH.txt",
            """
            Place polybius-tdeck.bin in downloads/, then:

              esptool.py --chip esp32s3 --port /dev/ttyACM0 write_flash 0x0 downloads/polybius-tdeck.bin

            Or: pio run -e tdeck -t upload
            """,
        )
        return created

    touch_file(
        "downloads/PLACE_OS_IMAGE_HERE.txt",
        """
        Drop the decompressed .img here (from .xz / .gz / .zip).

        LineageOS (AndR36oid): https://github.com/andr36oid/release_uploads
        ArkOS Multipanel: https://github.com/AeolusUX/ArkOS-R3XS
        ROCKNIX RK3326: https://github.com/ROCKNIX/distribution/releases
        """,
    )

    if mode == "single":
        touch_dir("card_tf1")
        touch_file(
            "card_tf1/README.txt",
            "After flashing the OS image to this physical card, first-boot resize runs.",
        )
    elif mode == "dual_card":
        touch_dir("card_tf1_os")
        touch_dir("card_tf2_roms")
        touch_file(
            "card_tf2_roms/README.txt",
            """
            Leave TF2 empty until TF1 finishes first boot.
            ArkOS: Options → Advanced → Switch to SD2 for ROMs.
            Lineage: use TF2 for ROMs / extras after Android boots.
            """,
        )
    elif mode == "dual_os_swap":
        touch_dir("card_a_lineage_or_primary")
        touch_dir("card_b_arkos_or_secondary")
        touch_file(
            "card_a_lineage_or_primary/FLASH_THIS.txt",
            "Flash LineageOS (or primary OS) image to this physical microSD.",
        )
        touch_file(
            "card_b_arkos_or_secondary/FLASH_THIS.txt",
            "Flash ArkOS / ROCKNIX (or secondary OS) image to this physical microSD.",
        )
        touch_file(
            "SWAP_GUIDE.txt",
            "Insert the desired OS card in TF1 to boot. Swap cards to switch OS.",
        )

    if polybius and meta.get("polybius") == "apk":
        touch_dir("sideload")
        touch_file(
            "sideload/README.txt",
            """
            After Lineage boots, install:
              polybius-*-android-arm64.apk
              darth-cherry-*-android-arm64.apk (optional)
            via Files or: adb install -r polybius.apk
            """,
        )
    elif polybius and meta.get("polybius") == "port":
        ports = (
            "card_tf1_os/roms/ports"
            if mode == "dual_card"
            else "after_flash/roms/ports"
        )
        touch_dir(ports)
        touch_file(
            f"{ports}/README.txt",
            """
            Unzip polybius-*-r36s-port.zip and copy:
              Polybius.sh → /roms/ports/
              polybius/   → /roms/ports/polybius/
            Refresh Ports / reboot.
            """,
        )

    for note in meta.get("notes", []):
        # Notes already in MANIFEST / docs; keep stage lean.
        _ = note

    touch_file(
        "FLASH.txt",
        f"""
        # Flash TF1 / primary OS card (DESTROYS the target disk)

        python tools/sd_organiser/sd_organiser.py flash \\
          --image downloads/os-image.img \\
          --disk /dev/sdX

        # Or Balena Etcher / Rufus / dd if=os-image.img of=/dev/sdX bs=4M status=progress

        Profile: {profile_id}
        Mode: {mode}
        """,
    )
    return created


def cmd_stage(args: argparse.Namespace) -> None:
    profile_id = args.profile
    if profile_id not in PROFILES:
        die(f"unknown profile {profile_id!r}; run list-profiles")
    meta = PROFILES[profile_id]
    if args.mode not in meta["modes"]:
        die(f"mode {args.mode!r} not supported for {profile_id}")

    out = Path(args.out).expanduser().resolve()
    if out.exists() and any(out.iterdir()) and not args.force:
        die(f"output {out} is not empty (pass --force to overwrite staging files)")

    out.mkdir(parents=True, exist_ok=True)
    created = build_tree(profile_id, args.mode, args.polybius, out)
    print(f"Staged {len(created)} paths under {out}")
    for rel in created:
        print(f"  {rel}")


def is_likely_system_disk(disk: Path) -> bool:
    name = disk.name
    # Refuse whole-disk names that look like the boot disk on common layouts.
    forbidden_exact = {"sda", "nvme0n1", "mmcblk0", "vda", "xvda"}
    if name in forbidden_exact:
        return True
    # Refuse partitions as flash targets (want whole disk).
    if name.startswith("sd") and name[-1:].isdigit():
        return True
    if "p" in name and name[-1:].isdigit() and (
        name.startswith("nvme") or name.startswith("mmcblk")
    ):
        return True
    return False


def cmd_flash(args: argparse.Namespace) -> None:
    image = Path(args.image).expanduser().resolve()
    disk = Path(args.disk)

    if not image.is_file():
        die(f"image not found: {image}")
    if image.suffix.lower() in {".xz", ".gz", ".zip"}:
        die("decompress the image to .img first (.xz/.gz/.zip not supported directly)")

    if not disk.exists():
        die(f"disk not found: {disk}")

    if is_likely_system_disk(disk) and not args.i_know_what_im_doing:
        die(
            f"refusing to flash likely system disk {disk}. "
            "Pick the removable SD reader (e.g. /dev/sdb) or pass "
            "--i-know-what-im-doing after triple-checking."
        )

    size = image.stat().st_size
    print(f"Image: {image} ({size} bytes)")
    print(f"Disk:  {disk}")
    print("THIS WILL DESTROY ALL DATA ON THE TARGET DISK.")

    if not args.yes:
        confirm = input(f'Type the disk path exactly to continue ({disk}): ').strip()
        if confirm != str(disk):
            die("confirmation mismatch — aborting")

    dd = shutil.which("dd")
    if not dd:
        die("dd not found on PATH")

    # Prefer oflag=sync when available (GNU dd).
    cmd = [
        dd,
        f"if={image}",
        f"of={disk}",
        "bs=4M",
        "status=progress",
        "conv=fsync",
    ]
    print("Running:", " ".join(cmd))
    if args.dry_run:
        print("dry-run: not executing")
        return

    # Direct exec — requires root for raw disks.
    os.execvp(dd, cmd)


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="sd_organiser",
        description="POLYBIUS PRESS SD image organiser",
    )
    sub = p.add_subparsers(dest="command", required=True)

    list_p = sub.add_parser("list-profiles", help="List device profiles")
    list_p.set_defaults(func=cmd_list_profiles)

    stage_p = sub.add_parser("stage", help="Create a staging folder layout")
    stage_p.add_argument("--profile", required=True, choices=sorted(PROFILES))
    stage_p.add_argument(
        "--mode",
        default="single",
        choices=["single", "dual_card", "dual_os_swap"],
    )
    stage_p.add_argument(
        "--polybius",
        action="store_true",
        help="Include POLYBIUS port/APK staging folders",
    )
    stage_p.add_argument(
        "--out",
        default="./stage",
        help="Output directory (default: ./stage)",
    )
    stage_p.add_argument(
        "--force",
        action="store_true",
        help="Allow writing into a non-empty output directory",
    )
    stage_p.set_defaults(func=cmd_stage)

    flash_p = sub.add_parser("flash", help="Write an .img to a block device (destructive)")
    flash_p.add_argument("--image", required=True, help="Path to .img")
    flash_p.add_argument("--disk", required=True, help="Whole-disk path e.g. /dev/sdb")
    flash_p.add_argument("-y", "--yes", action="store_true", help="Skip interactive confirm")
    flash_p.add_argument(
        "--dry-run",
        action="store_true",
        help="Print dd command without executing",
    )
    flash_p.add_argument(
        "--i-know-what-im-doing",
        action="store_true",
        help="Override system-disk safety check",
    )
    flash_p.set_defaults(func=cmd_flash)

    return p


def main(argv: list[str] | None = None) -> None:
    parser = build_parser()
    args = parser.parse_args(argv)
    args.func(args)


if __name__ == "__main__":
    main()
