"""Render every Poopy Bird toon asset into assets/images/.

Usage:
  /opt/homebrew/bin/blender -b -P tools/blender/export_all.py

Optional argv after ``--``:
  --only bird,cars,food,ui,bg
"""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import bpy  # noqa: E402

from common import (  # noqa: E402
    IMAGES_DIR,
    ensure_images_dir,
    png_outline,
    render_png,
    reset_scene,
    setup_ortho_camera,
)
from models import (  # noqa: E402
    bird_pose,
    build_bird,
    build_car,
    build_car_wash_truck,
    build_cloud_tile,
    build_coin,
    build_food,
    build_mayor_limo,
    build_medal,
    build_monster_truck,
    build_skyline_tile,
    build_tire,
    build_trophy,
    food_pose,
)

CAR_COLORS = {
    "sedan": (0.88, 0.16, 0.14, 1.0),
    "sports": (0.98, 0.78, 0.08, 1.0),
    "convertible": (0.12, 0.55, 0.9, 1.0),
    "washed": (0.93, 0.93, 0.96, 1.0),
    "bus": (0.18, 0.58, 0.38, 1.0),
    "taxi": (0.98, 0.82, 0.08, 1.0),
    "limo": (0.07, 0.07, 0.09, 1.0),
    "police": (0.12, 0.22, 0.58, 1.0),
    "sunroof": (0.58, 0.22, 0.7, 1.0),
}


def _parse_only() -> set[str] | None:
    if "--" not in sys.argv:
        return None
    args = sys.argv[sys.argv.index("--") + 1 :]
    for i, arg in enumerate(args):
        if arg == "--only" and i + 1 < len(args):
            return {p.strip() for p in args[i + 1].split(",") if p.strip()}
    return None


def _render_subject(
    path: str,
    builder,
    *,
    axis: str = "Y",
    resolution=(512, 512),
    outline: int = 5,
    padding: float = 1.18,
):
    reset_scene()
    builder()
    subjects = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    setup_ortho_camera(subjects, axis=axis, resolution=resolution, padding=padding)
    bpy.context.scene.world.node_tree.nodes["Background"].inputs[
        "Strength"
    ].default_value = 0.0
    out = render_png(IMAGES_DIR / path)
    if outline > 0:
        png_outline(out, width=outline)
    return out


def export_bird():
    for i in range(1, 9):
        pose = bird_pose(i)
        reset_scene()
        build_bird(**pose)
        subjects = [o for o in bpy.context.scene.objects if o.type == "MESH"]
        # Slight 3/4 so the wing reads in depth; still faces +X (right).
        setup_ortho_camera(subjects, axis="CHAR", resolution=(720, 720), padding=1.3)
        bpy.context.scene.world.node_tree.nodes["Background"].inputs[
            "Strength"
        ].default_value = 0.0
        primary = render_png(IMAGES_DIR / f"bird_{i:02d}.png")
        png_outline(primary, width=7)
        shutil.copyfile(primary, IMAGES_DIR / f"frame-{i}.png")


def export_cars():
    for kind, color in CAR_COLORS.items():
        _render_subject(
            f"car_{kind}.png",
            lambda k=kind, c=color: build_car(k, body_color=c),
            axis="Y",
            resolution=(768, 420),
            outline=6,
            padding=1.2,
        )
    shutil.copyfile(IMAGES_DIR / "car_sedan.png", IMAGES_DIR / "car-body.png")

    _render_subject(
        "boss_car_wash.png",
        build_car_wash_truck,
        axis="Y",
        resolution=(900, 480),
        outline=6,
    )
    _render_subject(
        "boss_mayor_limo.png",
        build_mayor_limo,
        axis="Y",
        resolution=(900, 400),
        outline=6,
    )
    _render_subject(
        "boss_monster_truck.png",
        build_monster_truck,
        axis="Y",
        resolution=(768, 560),
        outline=6,
    )
    _render_subject("tire.png", build_tire, axis="Y", resolution=(320, 320), outline=5)


def export_food():
    for kind in ("berries", "chili", "burrito"):
        # Animated tumble cycle + a still alias for menus.
        for i in range(1, 7):
            pose = food_pose(i)
            _render_subject(
                f"food_{kind}_{i:02d}.png",
                lambda k=kind, p=pose: build_food(k, **p),
                axis="Y",
                resolution=(320, 320),
                outline=5,
            )
        shutil.copyfile(
            IMAGES_DIR / f"food_{kind}_01.png", IMAGES_DIR / f"food_{kind}.png"
        )


def export_ui():
    # Coin spin frames for juice; frame 01 is the static badge.
    for i, spin in enumerate((0, 30, 60, 90, 120, 150), start=1):
        _render_subject(
            f"coin_{i:02d}.png",
            lambda s=spin: build_coin(spin=s),
            axis="Y",
            resolution=(256, 256),
            outline=5,
        )
    shutil.copyfile(IMAGES_DIR / "coin_01.png", IMAGES_DIR / "coin.png")

    for tier in ("bronze", "silver", "gold"):
        _render_subject(
            f"trophy_{tier}.png",
            lambda t=tier: build_trophy(t),
            axis="Y",
            resolution=(320, 400),
            outline=5,
        )
    _render_subject("medal.png", build_medal, axis="Y", resolution=(288, 360), outline=5)


def export_backgrounds():
    reset_scene()
    clouds = build_cloud_tile()
    setup_ortho_camera(clouds, axis="Y", resolution=(1400, 400), padding=1.05)
    bpy.context.scene.world.node_tree.nodes["Background"].inputs[
        "Strength"
    ].default_value = 0.0
    render_png(IMAGES_DIR / "bg_clouds.png")

    reset_scene()
    far = build_skyline_tile(seed=1, near=False)
    setup_ortho_camera(far, axis="Y", resolution=(1200, 520), padding=1.02)
    bpy.context.scene.world.node_tree.nodes["Background"].inputs[
        "Strength"
    ].default_value = 0.0
    render_png(IMAGES_DIR / "bg_skyline_far.png")

    reset_scene()
    near = build_skyline_tile(seed=2, near=True)
    setup_ortho_camera(near, axis="Y", resolution=(1200, 440), padding=1.02)
    bpy.context.scene.world.node_tree.nodes["Background"].inputs[
        "Strength"
    ].default_value = 0.0
    render_png(IMAGES_DIR / "bg_skyline_near.png")


def main():
    ensure_images_dir()
    only = _parse_only()
    print(f"[poopy-bird] exporting to {IMAGES_DIR} (only={only})")

    jobs = [
        ("bird", export_bird),
        ("cars", export_cars),
        ("food", export_food),
        ("ui", export_ui),
        ("bg", export_backgrounds),
    ]
    for name, fn in jobs:
        if only is not None and name not in only:
            continue
        print(f"[poopy-bird] === {name} ===")
        fn()
    print("[poopy-bird] done")


if __name__ == "__main__":
    main()
