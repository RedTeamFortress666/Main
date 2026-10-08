#!/usr/bin/env python3
"""Render the CRYPT3X OS boot sequence.

Timeline (24 fps, 5.5s):
  0.0–3.0s  interlocking gears rotate and click over the crest
  3.0–4.2s  a keyhole of light blooms in the center
  4.2–5.5s  black card: "Brought to you by GÅMÊ ØVĒR"
"""

from __future__ import annotations

import math
import os
import struct
import wave
import zipfile
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent
CREST_PATH = ROOT / "crypt3x_crest.png"
OUT_DIR = ROOT / "build"
FRAMES_HD = OUT_DIR / "frames_hd"
FRAMES_BOOT = OUT_DIR / "boot_frames"
ZIP_PATH = ROOT / "bootanimation.zip"
WAV_PATH = OUT_DIR / "clicks.wav"
MP4_PATH = Path(os.environ.get("CRYPT3X_MP4", "/opt/cursor/artifacts/crypt3x_os_boot.mp4"))

W, H = 1280, 720
BOOT_W, BOOT_H = 640, 480
FPS = 24
GEAR_SEC = 3.0
KEY_SEC = 1.2
TEXT_SEC = 1.3
DURATION = GEAR_SEC + KEY_SEC + TEXT_SEC
NFRAMES = int(DURATION * FPS)
GEAR_END = int(GEAR_SEC * FPS)
KEY_END = int((GEAR_SEC + KEY_SEC) * FPS)

NAVY = (6, 10, 22)
CYAN = (0, 210, 255)
BRONZE = (176, 126, 62)
STEEL = (158, 168, 184)
IRON = (72, 78, 88)
GOLD = (212, 168, 74)

TAGLINE = "Brought to you by GÅMÊ ØVĒR"


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
    ]
    for path in candidates:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def make_gear(diameter: int, teeth: int, body, hub, rim) -> Image.Image:
    pad = 8
    size = diameter + pad * 2
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = cy = size / 2
    r = diameter / 2
    tooth_w = 2 * math.pi / teeth
    tooth_len = r * 0.16
    inner = r * 0.78
    pts = []
    for i in range(teeth):
        a0 = i * tooth_w
        for t, rad in (
            (a0 - tooth_w * 0.18, inner),
            (a0 - tooth_w * 0.10, r),
            (a0 + tooth_w * 0.10, r),
            (a0 + tooth_w * 0.18, inner),
        ):
            pts.append((cx + rad * math.cos(t), cy + rad * math.sin(t)))
    d.polygon(pts, fill=body + (255,))
    d.ellipse((cx - inner, cy - inner, cx + inner, cy + inner), fill=body + (255,), outline=rim + (255,), width=3)
    hole = r * 0.22
    spoke_r = r * 0.55
    for i in range(6):
        a = i * math.pi / 3
        x1, y1 = cx + hole * math.cos(a), cy + hole * math.sin(a)
        x2, y2 = cx + spoke_r * math.cos(a), cy + spoke_r * math.sin(a)
        d.line((x1, y1, x2, y2), fill=hub + (255,), width=max(3, diameter // 28))
    d.ellipse((cx - spoke_r, cy - spoke_r, cx + spoke_r, cy + spoke_r), outline=rim + (220,), width=2)
    d.ellipse((cx - hole, cy - hole, cx + hole, cy + hole), fill=NAVY + (255,), outline=GOLD + (255,), width=2)
    return img.filter(ImageFilter.SMOOTH_MORE)


def keyhole_mask(w: int, h: int, scale: float) -> Image.Image:
    mask = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(mask)
    cx, cy = w // 2, int(h * 0.46)
    head = int(min(w, h) * 0.13 * scale)
    slot_w = int(head * 0.42)
    slot_h = int(head * 1.15)
    d.ellipse((cx - head, cy - head, cx + head, cy + head), fill=255)
    d.polygon(
        [
            (cx - slot_w, cy + head * 0.35),
            (cx + slot_w, cy + head * 0.35),
            (cx + slot_w * 1.55, cy + head + slot_h),
            (cx - slot_w * 1.55, cy + head + slot_h),
        ],
        fill=255,
    )
    return mask.filter(ImageFilter.GaussianBlur(radius=max(1, 6 * scale)))


def draw_matrix(draw: ImageDraw.ImageDraw, frame: int, rng: np.random.Generator) -> None:
    cols = 28
    for i in range(cols):
        x = int((i + 0.5) * W / cols)
        seed = (i * 17 + frame) % 40
        for row in range(14):
            y = (seed * 18 + row * 22 + frame * 3) % (H + 40) - 20
            ch = chr(48 + (i * 13 + row * 7 + frame) % 10)
            alpha = max(20, 140 - row * 9)
            draw.text((x, y), ch, fill=(0, 160, 220, alpha), font=font(11))


def load_crest() -> Image.Image:
    crest = Image.open(CREST_PATH).convert("RGBA")
    # Fill the 16:9 frame, slight overscan so gears sit in the mechanical field.
    scale = max(W / crest.width, H / crest.height) * 1.08
    nw, nh = int(crest.width * scale), int(crest.height * scale)
    crest = crest.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (W, H), NAVY + (255,))
    canvas.paste(crest, ((W - nw) // 2, (H - nh) // 2), crest)
    return canvas


def build_click_track(click_times: list[float]) -> None:
    sr = 44100
    n = int(DURATION * sr) + sr // 4
    audio = np.zeros(n, dtype=np.float32)
    t = np.arange(int(0.035 * sr)) / sr
    click = (
        0.55 * np.sin(2 * np.pi * 2450 * t) * np.exp(-t * 90)
        + 0.25 * np.sin(2 * np.pi * 4100 * t) * np.exp(-t * 140)
        + 0.12 * (np.random.default_rng(3).standard_normal(t.size)) * np.exp(-t * 80)
    )
    for when in click_times:
        start = int(when * sr)
        end = min(n, start + click.size)
        audio[start:end] += click[: end - start]
    audio = np.clip(audio, -1, 1)
    pcm = (audio * 22000).astype(np.int16)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    with wave.open(str(WAV_PATH), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sr)
        wf.writeframes(pcm.tobytes())


def main() -> None:
    FRAMES_HD.mkdir(parents=True, exist_ok=True)
    FRAMES_BOOT.mkdir(parents=True, exist_ok=True)

    base = load_crest()
    gears = [
        {"img": make_gear(310, 14, STEEL, IRON, CYAN), "xy": (-40, -30), "rpm": 18, "teeth": 14},
        {"img": make_gear(240, 11, BRONZE, IRON, GOLD), "xy": (1040, -20), "rpm": -22, "teeth": 11},
        {"img": make_gear(280, 16, IRON, STEEL, CYAN), "xy": (-30, 470), "rpm": -15, "teeth": 16},
        {"img": make_gear(210, 10, BRONZE, IRON, GOLD), "xy": (1085, 500), "rpm": 26, "teeth": 10},
        {"img": make_gear(150, 9, STEEL, IRON, CYAN), "xy": (560, -55), "rpm": 32, "teeth": 9},
        {"img": make_gear(130, 8, BRONZE, IRON, GOLD), "xy": (40, 300), "rpm": -28, "teeth": 8},
        {"img": make_gear(120, 8, STEEL, IRON, CYAN), "xy": (1120, 280), "rpm": 30, "teeth": 8},
    ]

    click_times: list[float] = []
    last_tooth = {i: -1 for i in range(len(gears))}
    title_font = font(54, bold=True)
    small_font = font(22, bold=True)
    wordmark = font(72, bold=True)

    for f in range(NFRAMES):
        t = f / FPS
        frame = Image.new("RGBA", (W, H), NAVY + (255,))
        # Slow Ken Burns on the crest during the gear act.
        zoom = 1.0 + 0.03 * min(1.0, t / GEAR_SEC)
        cw, ch = int(W * zoom), int(H * zoom)
        crest = base.resize((cw, ch), Image.Resampling.BILINEAR)
        frame.paste(crest, ((W - cw) // 2, (H - ch) // 2))

        overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        od = ImageDraw.Draw(overlay)
        draw_matrix(od, f, np.random.default_rng(1))

        for i, g in enumerate(gears):
            angle = (t * g["rpm"] * 6.0) % 360  # deg
            tooth = int((angle / 360.0) * g["teeth"])
            if tooth != last_tooth[i] and t <= GEAR_SEC + 0.15:
                last_tooth[i] = tooth
                # One click per mesh event, de-duped to ~8–10 Hz max.
                if not click_times or t - click_times[-1] > 0.09:
                    click_times.append(t)
            rot = g["img"].rotate(-angle, resample=Image.Resampling.BICUBIC, expand=True)
            x, y = g["xy"]
            # Keep the visual center near the intended corner.
            px = x - (rot.width - g["img"].width) // 2
            py = y - (rot.height - g["img"].height) // 2
            overlay.alpha_composite(rot, (px, py))

        frame = Image.alpha_composite(frame, overlay)

        # Keyhole of light.
        if f >= GEAR_END:
            kprog = min(1.0, (t - GEAR_SEC) / KEY_SEC)
            bloom = 0.35 + 1.8 * (kprog ** 1.15)
            kh = keyhole_mask(W, H, bloom)
            light = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            gd = ImageDraw.Draw(glow)
            # Soft wash so the later black type has a pale field.
            wash = int(40 + 200 * kprog)
            gd.rectangle((0, 0, W, H), fill=(210, 230, 245, wash))
            core = Image.new("RGBA", (W, H), (255, 255, 255, 0))
            cd = ImageDraw.Draw(core)
            cd.rectangle((0, 0, W, H), fill=(180, 245, 255, 255))
            core.putalpha(kh.point(lambda p: min(255, int(p * (0.4 + 0.6 * kprog)))))
            light = Image.alpha_composite(glow, core)
            # Extra halo
            halo = kh.filter(ImageFilter.GaussianBlur(radius=28))
            halo_img = Image.new("RGBA", (W, H), (0, 220, 255, 0))
            ha = halo.point(lambda p: min(255, int(p * 0.85 * kprog)))
            halo_img.putalpha(ha)
            light = Image.alpha_composite(halo_img, light)
            frame = Image.alpha_composite(frame, light)

        # End card: black type on the light.
        if f >= KEY_END:
            tprog = min(1.0, (t - GEAR_SEC - KEY_SEC) / 0.35)
            card = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            cd = ImageDraw.Draw(card)
            # Pale field so black type reads.
            cd.rectangle((0, 0, W, H), fill=(236, 242, 248, int(235 * tprog)))
            # Thin cyan circuit bars
            cd.rectangle((180, H // 2 - 70, W - 180, H // 2 - 66), fill=(0, 180, 220, int(200 * tprog)))
            cd.rectangle((180, H // 2 + 78, W - 180, H // 2 + 82), fill=(0, 180, 220, int(200 * tprog)))
            mark = "CRYPT3X OS"
            bbox = cd.textbbox((0, 0), mark, font=wordmark)
            tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
            cd.text(((W - tw) // 2, H // 2 - 118), mark, font=wordmark, fill=(10, 12, 16, int(255 * tprog)))
            bbox = cd.textbbox((0, 0), TAGLINE, font=title_font)
            tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
            cd.text(((W - tw) // 2, H // 2 - 8), TAGLINE, font=title_font, fill=(0, 0, 0, int(255 * tprog)))
            sub = "SECURITY & PRIVACY BY DESIGN"
            bbox = cd.textbbox((0, 0), sub, font=small_font)
            tw = bbox[2] - bbox[0]
            cd.text(((W - tw) // 2, H // 2 + 58), sub, font=small_font, fill=(20, 28, 40, int(220 * tprog)))
            frame = Image.alpha_composite(frame, card)

        rgb = frame.convert("RGB")
        rgb.save(FRAMES_HD / f"{f:04d}.png", optimize=True)
        rgb.resize((BOOT_W, BOOT_H), Image.Resampling.LANCZOS).save(
            FRAMES_BOOT / f"{f:04d}.png", optimize=True
        )
        if f % 24 == 0:
            print(f"rendered {f}/{NFRAMES}")

    build_click_track(click_times)
    print(f"clicks: {len(click_times)}  wav={WAV_PATH}")

    # Android bootanimation.zip — three parts matching the acts.
    part0, part1, part2 = OUT_DIR / "part0", OUT_DIR / "part1", OUT_DIR / "part2"
    for p in (part0, part1, part2):
        if p.exists():
            for old in p.glob("*.png"):
                old.unlink()
        p.mkdir(parents=True, exist_ok=True)
    for i in range(GEAR_END):
        os.link(FRAMES_BOOT / f"{i:04d}.png", part0 / f"{i:04d}.png")
    for i in range(GEAR_END, KEY_END):
        os.link(FRAMES_BOOT / f"{i:04d}.png", part1 / f"{i - GEAR_END:04d}.png")
    for i in range(KEY_END, NFRAMES):
        os.link(FRAMES_BOOT / f"{i:04d}.png", part2 / f"{i - KEY_END:04d}.png")

    desc = f"{BOOT_W} {BOOT_H} {FPS}\np 1 0 part0\np 1 0 part1\np 1 30 part2\n"
    (OUT_DIR / "desc.txt").write_text(desc)
    if ZIP_PATH.exists():
        ZIP_PATH.unlink()
    with zipfile.ZipFile(ZIP_PATH, "w", compression=zipfile.ZIP_STORED) as zf:
        zf.write(OUT_DIR / "desc.txt", "desc.txt")
        for part in ("part0", "part1", "part2"):
            for png in sorted((OUT_DIR / part).glob("*.png")):
                zf.write(png, f"{part}/{png.name}")
    print(f"bootanimation.zip {ZIP_PATH.stat().st_size} bytes")

    MP4_PATH.parent.mkdir(parents=True, exist_ok=True)
    cmd = (
        f'ffmpeg -y -framerate {FPS} -i "{FRAMES_HD}/%04d.png" -i "{WAV_PATH}" '
        f'-c:v libx264 -pix_fmt yuv420p -crf 18 -c:a aac -b:a 160k -shortest '
        f'"{MP4_PATH}"'
    )
    rc = os.system(cmd)
    if rc != 0:
        raise SystemExit(f"ffmpeg failed: {rc}")
    print(f"wrote {MP4_PATH}")


if __name__ == "__main__":
    main()
