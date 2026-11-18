"""Render every Poopy Bird toon asset into assets/images/.

Usage:
  /opt/homebrew/bin/blender -b -P tools/blender/export_all.py

Optional argv after ``--``:
  --only bird,cars,food,ui,bg
"""

from __future__ import annotations

import sys
from pathlib import Path

# Blender puts the script path on argv but not always on sys.path.
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
)

CAR_COLORS = {
    "sedan": (0.85, 0.18, 0.16, 1.0),
    "sports": (0.95, 0.78, 0.12, 1.0),
    "convertible": (0.15, 0.55, 0.85, 1.0),
    "washed": (0.92, 0.92, 0.95, 1.0),
    "bus": (0.2, 0.55, 0.35, 1.0),
    "taxi": (0.95, 0.8, 0.1, 1.0),
    "limo": (0.08, 0.08, 0.1, 1.0),
    "police": (0.12, 0.2, 0.55, 1.0),
    "sunroof": (0.55, 0.25, 0.65, 1.0),
}


def _parse_only() -> set[str] | None:
    if "--" not in sys.argv:
        return None
    args = sys.argv[sys.argv.index("--") + 1 :]
    for i, arg in enumerate(args):
        if arg == "--only" and i + 1 < len(args):
            return {p.strip() for p in args[i + 1].split(",") if p.strip()}
    return None


def _visible_meshes():
    return [
        o
        for o in bpy.context.scene.objects
        if o.type == "MESH" and not o.name.endswith("_outline")
    ]


def _render_subject(
    path: str,
    builder,
    *,
    axis: str = "Y",
    resolution=(512, 512),
    outline: int = 5,
):
    reset_scene()
    builder()
    subjects = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    setup_ortho_camera(subjects, axis=axis, resolution=resolution)
    bpy.context.scene.world.node_tree.nodes["Background"].inputs[
        "Strength"
    ].default_value = 0.0
    out = render_png(IMAGES_DIR / path)
    if outline > 0:
        png_outline(out, width=outline)


def export_bird():
    # 8 flap frames; angle sweeps up/down.
    angles = [0, 25, 45, 30, 5, -20, -35, -15]
    for i, angle in enumerate(angles, start=1):
        reset_scene()
        build_bird(wing_angle=angle)
        subjects = [o for o in bpy.context.scene.objects if o.type == "MESH"]
        setup_ortho_camera(subjects, axis="Y", resolution=(512, 512))
        bpy.context.scene.world.node_tree.nodes["Background"].inputs[
            "Strength"
        ].default_value = 0.0
        primary = render_png(IMAGES_DIR / f"bird_{i:02d}.png")
        png_outline(primary, width=6)
        # Legacy alias for mid-migrate loaders.
        import shutil

        shutil.copyfile(primary, IMAGES_DIR / f"frame-{i}.png")


def export_cars():
    for kind, color in CAR_COLORS.items():
        _render_subject(
            f"car_{kind}.png",
            lambda k=kind, c=color: build_car(k, body_color=c),
            axis="Y",
            resolution=(640, 360),
        )
    # Compatibility alias for the sedan body used by older code paths.
    import shutil

    shutil.copyfile(IMAGES_DIR / "car_sedan.png", IMAGES_DIR / "car-body.png")

    _render_subject(
        "boss_car_wash.png", build_car_wash_truck, axis="Y", resolution=(768, 420)
    )
    _render_subject(
        "boss_mayor_limo.png", build_mayor_limo, axis="Y", resolution=(768, 360)
    )
    _render_subject(
        "boss_monster_truck.png",
        build_monster_truck,
        axis="Y",
        resolution=(640, 480),
    )
    _render_subject("tire.png", build_tire, axis="Y", resolution=(256, 256))


def export_food():
    for kind in ("berries", "chili", "burrito"):
        _render_subject(
            f"food_{kind}.png",
            lambda k=kind: build_food(k),
            axis="Y",
            resolution=(256, 256),
        )


def export_ui():
    _render_subject("coin.png", build_coin, axis="Y", resolution=(256, 256))
    for tier in ("bronze", "silver", "gold"):
        _render_subject(
            f"trophy_{tier}.png",
            lambda t=tier: build_trophy(t),
            axis="Y",
            resolution=(256, 320),
        )
    _render_subject("medal.png", build_medal, axis="Y", resolution=(256, 320))


def export_backgrounds():
    # Soft parallax plates — no hard outline (distance read).
    reset_scene()
    clouds = build_cloud_tile()
    setup_ortho_camera(clouds, axis="Y", resolution=(1400, 400), padding=1.05)
    bpy.context.scene.world.node_tree.nodes["Background"].inputs[
        "Strength"
    ].default_value = 0.0
    render_png(IMAGES_DIR / "bg_clouds.png")

    reset_scene()
    far = build_skyline_tile(seed=1, near=False)
    setup_ortho_camera(far, axis="Y", resolution=(1200, 500), padding=1.02)
    bpy.context.scene.world.node_tree.nodes["Background"].inputs[
        "Strength"
    ].default_value = 0.0
    render_png(IMAGES_DIR / "bg_skyline_far.png")

    reset_scene()
    near = build_skyline_tile(seed=2, near=True)
    setup_ortho_camera(near, axis="Y", resolution=(1200, 420), padding=1.02)
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
