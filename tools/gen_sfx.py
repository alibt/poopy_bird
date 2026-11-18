#!/usr/bin/env python3
"""Generate simple procedural WAV stubs into assets/audio/ (no external samples)."""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio"
RATE = 22050


def write(name: str, samples: list[float], rate: int = RATE) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / name
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        frames = b"".join(
            struct.pack("<h", max(-32767, min(32767, int(s * 32767))))
            for s in samples
        )
        w.writeframes(frames)
    print(f"wrote {path} ({len(samples)} samples)")


def env(i: int, n: int, attack: float = 0.01, release: float = 0.08) -> float:
    t = i / n
    a = min(1.0, t / attack) if attack > 0 else 1.0
    r = min(1.0, (1 - t) / release) if release > 0 else 1.0
    return a * r


def main() -> None:
    n = int(RATE * 0.12)
    write(
        "flap.wav",
        [
            env(i, n, 0.005, 0.06)
            * 0.35
            * math.sin(2 * math.pi * (420 + i * 3) / RATE * i)
            * math.sin(2 * math.pi * 180 * i / RATE)
            for i in range(n)
        ],
    )

    n = int(RATE * 0.15)
    write(
        "poop.wav",
        [
            env(i, n, 0.01, 0.08)
            * 0.45
            * math.sin(2 * math.pi * (520 - i * 2.2) * i / RATE)
            for i in range(n)
        ],
    )

    rnd = random.Random(1)
    n = int(RATE * 0.2)
    write(
        "splat.wav",
        [
            env(i, n, 0.005, 0.12)
            * 0.55
            * ((rnd.random() * 2 - 1) * 0.7 + 0.3 * math.sin(2 * math.pi * 90 * i / RATE))
            for i in range(n)
        ],
    )

    n = int(RATE * 0.18)
    write(
        "miss.wav",
        [
            env(i, n, 0.01, 0.1)
            * 0.3
            * math.sin(2 * math.pi * (200 - i * 0.5) * i / RATE)
            for i in range(n)
        ],
    )

    n = int(RATE * 0.2)
    write(
        "eat.wav",
        [
            env(i, n, 0.01, 0.08)
            * 0.4
            * (
                math.sin(2 * math.pi * (660 + i) * i / RATE)
                + 0.5 * math.sin(2 * math.pi * 990 * i / RATE)
            )
            for i in range(n)
        ],
    )

    rnd = random.Random(2)
    n = int(RATE * 0.35)
    write(
        "crash.wav",
        [
            env(i, n, 0.01, 0.2)
            * 0.6
            * ((rnd.random() * 2 - 1) * 0.8 + 0.2 * math.sin(2 * math.pi * 60 * i / RATE))
            for i in range(n)
        ],
    )

    n = int(RATE * 0.22)
    write(
        "combo.wav",
        [
            env(i, n, 0.005, 0.1)
            * 0.4
            * math.sin(2 * math.pi * (440 * (1 + i / n)) * i / RATE)
            for i in range(n)
        ],
    )

    n = int(RATE * 0.06)
    write(
        "ui_tap.wav",
        [env(i, n, 0.002, 0.04) * 0.25 * math.sin(2 * math.pi * 880 * i / RATE) for i in range(n)],
    )

    n = int(RATE * 0.25)
    write(
        "coin.wav",
        [
            env(i, n, 0.005, 0.12)
            * 0.35
            * (
                math.sin(2 * math.pi * 1200 * i / RATE)
                + 0.4 * math.sin(2 * math.pi * 1800 * i / RATE)
            )
            for i in range(n)
        ],
    )

    n = int(RATE * 0.5)
    write(
        "achieve.wav",
        [
            env(i, n, 0.02, 0.2)
            * 0.35
            * math.sin(
                2
                * math.pi
                * (523 + (131 if i > n // 3 else 0) + (156 if i > 2 * n // 3 else 0))
                * i
                / RATE
            )
            for i in range(n)
        ],
    )

    notes = [262, 294, 330, 349, 392, 440, 494, 523]
    n = int(RATE * 4.0)
    write(
        "music_game.wav",
        [
            (
                0.12 * math.sin(2 * math.pi * notes[int(i / (RATE * 0.25)) % 8] * i / RATE)
                + 0.06
                * math.sin(2 * math.pi * notes[int(i / (RATE * 0.25)) % 8] * 2 * i / RATE)
            )
            * (0.7 + 0.3 * math.sin(2 * math.pi * i / RATE / 4))
            for i in range(n)
        ],
    )

    bass = [196, 247, 294, 330]
    write(
        "music_menu.wav",
        [
            0.1
            * math.sin(2 * math.pi * bass[int(i / (RATE * 0.5)) % 4] * i / RATE)
            * (0.5 + 0.5 * math.sin(2 * math.pi * i / RATE / 2))
            for i in range(n)
        ],
    )


if __name__ == "__main__":
    main()
