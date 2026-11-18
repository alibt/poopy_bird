"""Procedural cartoon subjects for Poopy Bird — built for readable 2D game sprites."""

from __future__ import annotations

import math
import random

import bpy
from mathutils import Euler

from common import (
    apply_loc_rot_scale,
    bevel,
    extrude_profile,
    join_objects,
    mesh_cone,
    mesh_cube,
    mesh_cylinder,
    mesh_uv_sphere,
    toon_material,
)


# ─── shared bits ─────────────────────────────────────────────────────────────


def _wheel(name: str, loc: tuple[float, float, float], radius: float = 0.22):
    rubber = toon_material(f"{name}_rubber", (0.07, 0.07, 0.08, 1.0), steps=2)
    hub = toon_material(f"{name}_hub", (0.78, 0.78, 0.82, 1.0), steps=2)
    rim = toon_material(f"{name}_rim", (0.35, 0.35, 0.38, 1.0), steps=2)
    tire = mesh_cylinder(
        name, radius=radius, depth=0.16, location=loc, material=rubber,
        vertices=20, rotation=(math.radians(90), 0, 0),
    )
    ring = mesh_cylinder(
        f"{name}_rim", radius=radius * 0.62, depth=0.17, location=loc,
        material=rim, vertices=16, rotation=(math.radians(90), 0, 0),
    )
    cap = mesh_cylinder(
        f"{name}_hub", radius=radius * 0.32, depth=0.18, location=loc,
        material=hub, vertices=12, rotation=(math.radians(90), 0, 0),
    )
    return [tire, ring, cap]


def _headlight(name: str, loc: tuple[float, float, float], lit: bool = True):
    color = (1.0, 0.95, 0.7, 1.0) if lit else (0.85, 0.55, 0.15, 1.0)
    return mesh_uv_sphere(
        name, 0.1, loc, toon_material(f"{name}_mat", color, steps=2),
        segments=12, ring_count=8, scale=(0.7, 0.55, 0.55),
    )


def _taillight(name: str, loc: tuple[float, float, float]):
    return mesh_uv_sphere(
        name, 0.08, loc,
        toon_material(f"{name}_mat", (0.9, 0.12, 0.1, 1.0), steps=2),
        segments=10, ring_count=6, scale=(0.55, 0.5, 0.45),
    )


# ─── cars ────────────────────────────────────────────────────────────────────


def _sedan_profile(length: float = 2.6, roof: float = 1.15) -> list[tuple[float, float]]:
    """Clockwise XZ silhouette of a cartoon sedan (nose at +X)."""
    L = length * 0.5
    return [
        (L * 0.98, 0.18),          # front bumper bottom
        (L * 1.02, 0.38),          # grille
        (L * 0.85, 0.58),          # hood front
        (L * 0.35, 0.68),          # hood / windshield base
        (L * 0.05, roof),          # roof front
        (-L * 0.35, roof),         # roof rear
        (-L * 0.55, 0.72),         # rear window
        (-L * 0.85, 0.62),         # trunk
        (-L * 1.0, 0.4),           # rear bumper top
        (-L * 0.98, 0.18),         # rear bumper bottom
        (-L * 0.55, 0.18),         # bottom
        (L * 0.55, 0.18),
    ]


def _sports_profile(length: float = 2.7) -> list[tuple[float, float]]:
    L = length * 0.5
    return [
        (L * 1.0, 0.15), (L * 1.05, 0.32), (L * 0.7, 0.42),
        (L * 0.15, 0.48), (-L * 0.05, 0.78), (-L * 0.45, 0.78),
        (-L * 0.7, 0.5), (-L * 1.0, 0.38), (-L * 0.98, 0.15),
        (L * 0.5, 0.15),
    ]


def _bus_profile(length: float = 3.4) -> list[tuple[float, float]]:
    L = length * 0.5
    return [
        (L * 0.95, 0.2), (L * 1.0, 0.55), (L * 0.9, 1.55),
        (-L * 0.9, 1.55), (-L * 1.0, 0.55), (-L * 0.95, 0.2),
        (L * 0.5, 0.2),
    ]


def _limo_profile(length: float = 4.0) -> list[tuple[float, float]]:
    L = length * 0.5
    return [
        (L * 0.98, 0.18), (L * 1.02, 0.38), (L * 0.8, 0.55),
        (L * 0.55, 0.62), (L * 0.35, 1.05), (-L * 0.55, 1.05),
        (-L * 0.75, 0.62), (-L * 0.98, 0.4), (-L * 0.96, 0.18),
        (L * 0.5, 0.18),
    ]


def build_car(
    kind: str,
    *,
    body_color: tuple[float, float, float, float],
    with_outline: bool = True,
    with_wheels: bool = False,
) -> bpy.types.Object:
    """Side-view car from a real extruded silhouette (not stacked boxes)."""
    body_mat = toon_material(f"{kind}_body", body_color, steps=3)
    glass = toon_material(f"{kind}_glass", (0.35, 0.65, 0.85, 1.0), steps=3)
    dark = toon_material(f"{kind}_trim", (0.1, 0.1, 0.12, 1.0), steps=2)
    chrome = toon_material(f"{kind}_chrome", (0.78, 0.8, 0.85, 1.0), steps=2)

    if kind == "sports":
        profile = _sports_profile()
        length = 2.7
    elif kind == "bus":
        profile = _bus_profile()
        length = 3.4
    elif kind in ("limo",):
        profile = _limo_profile()
        length = 4.0
    elif kind == "convertible":
        # Low roof — windscreen only.
        L = 1.3
        profile = [
            (L * 0.98, 0.18), (L * 1.02, 0.38), (L * 0.75, 0.55),
            (L * 0.2, 0.62), (L * 0.05, 0.85), (-L * 0.15, 0.7),
            (-L * 0.5, 0.58), (-L * 0.95, 0.55), (-L * 1.0, 0.35),
            (-L * 0.98, 0.18), (L * 0.5, 0.18),
        ]
        length = 2.6
    else:
        roof = 1.2 if kind != "sunroof" else 1.22
        profile = _sedan_profile(roof=roof)
        length = 2.6

    body = extrude_profile(f"{kind}_body", profile, width=1.15, material=body_mat)
    bevel(body, width=0.05, segments=3)
    parts: list[bpy.types.Object] = [body]

    # Window insert (inset silhouette on the cabin).
    if kind == "bus":
        win = extrude_profile(
            f"{kind}_win",
            [(1.2, 0.85), (1.3, 1.4), (-1.3, 1.4), (-1.2, 0.85)],
            width=1.18, material=glass,
        )
        parts.append(win)
        stripe = mesh_cube(
            f"{kind}_stripe", (3.3, 1.2, 0.14), (0, 0, 0.7),
            toon_material(f"{kind}_stripe", (1.0, 0.86, 0.12, 1.0), steps=2),
        )
        parts.append(stripe)
    elif kind == "convertible":
        seat = mesh_cube(
            f"{kind}_seat", (0.45, 0.7, 0.35), (0.0, 0, 0.55),
            toon_material(f"{kind}_seat", (0.45, 0.12, 0.12, 1.0), steps=2),
        )
        bevel(seat, width=0.05, segments=3)
        screen = mesh_cube(f"{kind}_screen", (0.06, 0.85, 0.4), (0.15, 0, 0.85), glass)
        parts.extend([seat, screen])
    else:
        # Glass band following the greenhouse roughly.
        if kind == "sports":
            win_pts = [(0.2, 0.5), (-0.05, 0.72), (-0.4, 0.72), (-0.55, 0.52)]
        elif kind == "limo":
            win_pts = [(1.2, 0.65), (0.9, 0.98), (-1.8, 0.98), (-2.2, 0.65)]
        else:
            win_pts = [(0.7, 0.7), (0.15, 1.08), (-0.7, 1.08), (-1.1, 0.72)]
        win = extrude_profile(f"{kind}_win", win_pts, width=1.18, material=glass)
        parts.append(win)

    # Bumpers + lights.
    parts.append(mesh_cube(f"{kind}_fb", (0.18, 1.2, 0.2), (length * 0.48, 0, 0.28), chrome))
    parts.append(mesh_cube(f"{kind}_rb", (0.16, 1.2, 0.18), (-length * 0.48, 0, 0.28), chrome))
    parts.append(_headlight(f"{kind}_hl", (length * 0.47, 0.35, 0.45)))
    parts.append(_taillight(f"{kind}_tl", (-length * 0.48, 0.35, 0.48)))

    mirror = mesh_cube(f"{kind}_mirror", (0.1, 0.2, 0.1), (length * 0.08, 0.6, 0.9), dark)
    bevel(mirror, width=0.02, segments=2)
    parts.append(mirror)

    if kind == "sports":
        spoiler = mesh_cube(
            f"{kind}_spoiler", (0.12, 1.1, 0.08), (-length * 0.42, 0, 0.85), body_mat
        )
        parts.append(spoiler)
    elif kind == "taxi":
        sign = mesh_cube(
            f"{kind}_sign", (0.42, 0.3, 0.22), (0.0, 0, 1.25),
            toon_material(f"{kind}_sign", (0.12, 0.12, 0.12, 1.0), steps=2),
        )
        glow = mesh_cube(
            f"{kind}_sg", (0.34, 0.24, 0.12), (0.0, 0, 1.28),
            toon_material(f"{kind}_sg", (1.0, 0.85, 0.1, 1.0), steps=2),
        )
        parts.extend([sign, glow])
    elif kind == "police":
        bar = mesh_cube(
            f"{kind}_bar", (0.55, 0.8, 0.14), (0.0, 0, 1.28),
            toon_material(f"{kind}_bar", (0.1, 0.1, 0.12, 1.0), steps=2),
        )
        blue = mesh_uv_sphere(
            f"{kind}_blue", 0.12, (-0.12, 0, 1.36),
            toon_material(f"{kind}_blue", (0.15, 0.45, 1.0, 1.0), steps=2),
            scale=(1.2, 0.8, 0.55),
        )
        red = mesh_uv_sphere(
            f"{kind}_red", 0.12, (0.12, 0, 1.36),
            toon_material(f"{kind}_red", (1.0, 0.15, 0.12, 1.0), steps=2),
            scale=(1.2, 0.8, 0.55),
        )
        stripe = mesh_cube(
            f"{kind}_stripe", (length * 0.85, 1.18, 0.12), (0, 0, 0.55),
            toon_material(f"{kind}_stripe", (0.95, 0.95, 0.97, 1.0), steps=2),
        )
        parts.extend([bar, blue, red, stripe])
    elif kind == "washed":
        spark = toon_material(f"{kind}_spark", (1.0, 1.0, 1.0, 1.0), steps=2)
        for i, loc in enumerate([(0.5, 0.2, 0.75), (0.0, -0.1, 1.1), (-0.4, 0.15, 1.05)]):
            parts.append(
                mesh_uv_sphere(f"{kind}_sp{i}", 0.09, loc, spark, scale=(1.0, 0.35, 1.0))
            )
    elif kind == "sunroof":
        hatch = mesh_cube(f"{kind}_hatch", (0.5, 0.5, 0.06), (-0.1, 0, 1.22), dark)
        g = mesh_cube(f"{kind}_hg", (0.36, 0.36, 0.05), (-0.1, 0, 1.25), glass)
        parts.extend([hatch, g])
    elif kind == "limo":
        for i, x in enumerate((-0.9, -0.15, 0.6)):
            parts.append(mesh_cube(f"{kind}_door{i}", (0.04, 1.18, 0.4), (x, 0, 0.55), chrome))

    if with_wheels:
        xs = (-length * 0.32, length * 0.3)
        if kind == "limo":
            xs = (-length * 0.38, -0.25, 0.4, length * 0.35)
        elif kind == "bus":
            xs = (-length * 0.35, 0.0, length * 0.32)
        for x in xs:
            for y in (-0.5, 0.5):
                parts.extend(_wheel(f"{kind}_w_{x:.2f}", (x, y, 0.24), 0.24))

    return join_objects(parts, f"car_{kind}")


def build_car_wash_truck(*, with_outline: bool = True) -> bpy.types.Object:
    blue = toon_material("cwt_cab", (0.12, 0.45, 0.9, 1.0))
    tank = toon_material("cwt_tank", (0.55, 0.82, 0.95, 1.0))
    yellow = toon_material("cwt_brush", (1.0, 0.85, 0.12, 1.0))
    white = toon_material("cwt_stripe", (0.96, 0.96, 0.98, 1.0))
    glass = toon_material("cwt_glass", (0.5, 0.78, 0.95, 1.0), steps=2)
    dark = toon_material("cwt_dark", (0.12, 0.12, 0.14, 1.0), steps=2)

    cab = mesh_cube("cwt_cab", (1.2, 1.25, 1.2), (1.5, 0, 0.85), blue)
    bevel(cab, width=0.08, segments=3)
    window = mesh_cube("cwt_window", (0.12, 0.95, 0.5), (2.05, 0, 1.05), glass)
    tank_body = mesh_cylinder(
        "cwt_tank", 0.7, 2.6, (-0.4, 0, 1.0), tank,
        vertices=24, rotation=(0, math.radians(90), 0),
    )
    tank_body.scale = (1.0, 0.9, 1.0)
    apply_loc_rot_scale(tank_body)
    stripe = mesh_cube("cwt_stripe", (2.5, 1.3, 0.16), (-0.4, 0, 0.85), white)
    # Spinning wash brushes — fluffy spheres on poles.
    parts = [cab, window, tank_body, stripe]
    for i, x in enumerate((-0.2, -1.2)):
        pole = mesh_cylinder(f"cwt_pole{i}", 0.06, 0.7, (x, 0, 1.55), dark)
        brush = mesh_uv_sphere(
            f"cwt_brush{i}", 0.38, (x, 0, 1.95), yellow,
            segments=16, scale=(1.0, 1.0, 0.85),
        )
        bristle = mesh_uv_sphere(
            f"cwt_br{i}", 0.42, (x, 0, 1.9),
            toon_material(f"cwt_br{i}", (1.0, 0.92, 0.35, 1.0), steps=2),
            segments=12, scale=(1.15, 1.15, 0.55),
        )
        parts.extend([pole, brush, bristle])
    for x in (-1.5, -0.2, 1.4):
        for y in (-0.55, 0.55):
            parts.extend(_wheel(f"cwt_w_{x}_{y}", (x, y, 0.28), 0.28))
    # Hose reel.
    reel = mesh_cylinder("cwt_reel", 0.25, 0.2, (0.7, 0.55, 1.2), dark,
                         rotation=(math.radians(90), 0, 0))
    parts.append(reel)
    return join_objects(parts, "boss_car_wash")


def build_mayor_limo(*, with_outline: bool = True) -> bpy.types.Object:
    black = toon_material("mayor_body", (0.06, 0.06, 0.08, 1.0))
    gold = toon_material("mayor_trim", (0.9, 0.72, 0.2, 1.0))
    glass = toon_material("mayor_glass", (0.2, 0.28, 0.35, 1.0), steps=2)
    body = mesh_cube("mayor_body", (4.4, 1.3, 0.9), (0, 0, 0.65), black)
    bevel(body, width=0.1, segments=4)
    cabin = mesh_cube("mayor_cabin", (2.8, 1.15, 0.75), (0.15, 0, 1.3), glass)
    bevel(cabin, width=0.08, segments=3)
    crest = mesh_cube("mayor_crest", (0.4, 0.4, 0.14), (1.7, 0, 1.65), gold)
    flag = mesh_cube("mayor_flag", (0.08, 0.25, 0.35), (2.0, 0.4, 1.55),
                     toon_material("mayor_flag", (0.75, 0.1, 0.12, 1.0), steps=2))
    armor = mesh_cube("mayor_armor", (4.35, 1.35, 0.2), (0, 0, 0.35),
                      toon_material("mayor_armor", (0.15, 0.15, 0.18, 1.0), steps=2))
    parts = [body, cabin, crest, flag, armor]
    parts.append(_headlight("mayor_hl", (2.15, 0.35, 0.7)))
    parts.append(_headlight("mayor_hl2", (2.15, -0.35, 0.7)))
    for x in (-1.6, -0.45, 0.7, 1.7):
        for y in (-0.55, 0.55):
            parts.extend(_wheel(f"mayor_w_{x}", (x, y, 0.28), 0.27))
    return join_objects(parts, "boss_mayor_limo")


def build_monster_truck(*, with_outline: bool = True) -> bpy.types.Object:
    red = toon_material("mt_body", (0.9, 0.12, 0.1, 1.0))
    dark = toon_material("mt_frame", (0.12, 0.12, 0.14, 1.0))
    glass = toon_material("mt_glass", (0.45, 0.75, 0.9, 1.0), steps=2)
    flame = toon_material("mt_flame", (1.0, 0.55, 0.1, 1.0), steps=2)
    body = mesh_cube("mt_body", (2.7, 1.7, 1.05), (0, 0, 1.55), red)
    bevel(body, width=0.12, segments=4)
    cabin = mesh_cube("mt_cabin", (1.15, 1.35, 0.85), (0.45, 0, 2.35), glass)
    bevel(cabin, width=0.08, segments=3)
    frame = mesh_cube("mt_frame", (2.3, 1.4, 0.4), (0, 0, 0.95), dark)
    roll = mesh_cylinder("mt_roll", 0.06, 1.2, (-0.3, 0, 2.6), dark,
                         rotation=(0, 0, math.radians(90)))
    blaze = mesh_cube("mt_blaze", (1.8, 1.72, 0.25), (-0.2, 0, 1.35), flame)
    parts = [body, cabin, frame, roll, blaze]
    for x in (-0.9, 0.9):
        for y in (-0.8, 0.8):
            parts.extend(_wheel(f"mt_w_{x}_{y}", (x, y, 0.6), 0.58))
    return join_objects(parts, "boss_monster_truck")


# ─── bird (animated) ─────────────────────────────────────────────────────────


def _wing_piece(name: str, mat, tip_mat, shoulder, angle_deg: float):
    """One solid cartoon wing (no floating shards), pivoted at the shoulder."""
    rad = math.radians(angle_deg)
    dx, dz = -math.sin(rad), math.cos(rad)
    # Build a wing silhouette in local space then rotate into pose.
    # Local: shoulder at origin, wing extends +Z (up).
    local = [
        (0.05, 0.0),
        (0.35, 0.35),
        (0.45, 0.75),
        (0.2, 1.05),
        (-0.05, 1.15),
        (-0.35, 0.95),
        (-0.4, 0.5),
        (-0.25, 0.15),
    ]
    # Rotate local (x,z) by angle around Y, then offset to shoulder.
    posed = []
    for lx, lz in local:
        # rotate in XZ: angle 0 keeps +Z up
        px = lx * math.cos(rad) + lz * (-math.sin(rad))
        pz = lx * math.sin(rad) + lz * math.cos(rad)
        posed.append((shoulder[0] + px, shoulder[2] + pz))
    wing = extrude_profile(f"{name}_solid", posed, width=0.22, material=mat)
    bevel(wing, width=0.03, segments=2)
    # Soft tip accent (attached, smaller, same pose).
    tip_local = [(0.05, 0.7), (0.15, 0.95), (-0.05, 1.12), (-0.2, 0.9)]
    tip_posed = []
    for lx, lz in tip_local:
        px = lx * math.cos(rad) + lz * (-math.sin(rad))
        pz = lx * math.sin(rad) + lz * math.cos(rad)
        tip_posed.append((shoulder[0] + px, shoulder[2] + pz))
    tip = extrude_profile(f"{name}_tip", tip_posed, width=0.18, material=tip_mat)
    return [wing, tip]


def build_bird(
    *,
    wing_angle: float = 20.0,
    body_bob: float = 0.0,
    squash: float = 1.0,
    blink: float = 1.0,
    tail_fan: float = 0.0,
    with_outline: bool = True,
) -> bpy.types.Object:
    """Cartoon mascot bird facing +X — big flap silhouette for sprite animation."""
    yellow = toon_material("bird_body", (1.0, 0.88, 0.2, 1.0), steps=3)
    wing_mat = toon_material("bird_wing", (1.0, 0.7, 0.1, 1.0), steps=3)
    wing_tip = toon_material("bird_tip", (0.95, 0.4, 0.05, 1.0), steps=2)
    belly_mat = toon_material("bird_belly", (1.0, 0.95, 0.7, 1.0), steps=2)
    orange = toon_material("bird_beak", (1.0, 0.5, 0.08, 1.0), steps=2)
    white = toon_material("bird_eye", (1.0, 1.0, 1.0, 1.0), steps=2)
    black = toon_material("bird_pupil", (0.05, 0.05, 0.07, 1.0), steps=2)
    blush = toon_material("bird_blush", (1.0, 0.5, 0.4, 1.0), steps=2)
    crest_mat = toon_material("bird_crest", (1.0, 0.45, 0.1, 1.0), steps=2)
    foot_mat = toon_material("bird_foot", (1.0, 0.42, 0.08, 1.0), steps=2)

    z0 = body_bob
    sx, sz = 1.0 / math.sqrt(squash), squash

    # Clear head/body separation (not one blob).
    body = mesh_uv_sphere(
        "bird_body", 0.62, (0.05, 0.0, z0 - 0.05), yellow,
        segments=48, ring_count=28, scale=(1.35 * sx, 0.78, 1.1 * sz),
    )
    belly = mesh_uv_sphere(
        "bird_belly", 0.42, (0.18, 0.08, z0 - 0.18), belly_mat,
        segments=32, scale=(1.15 * sx, 0.55, 0.85 * sz),
    )
    neck = mesh_uv_sphere(
        "bird_neck", 0.22, (0.45, 0.0, z0 + 0.28), yellow,
        segments=24, scale=(0.9, 0.7, 0.85),
    )
    head = mesh_uv_sphere(
        "bird_head", 0.42, (0.72, 0.0, z0 + 0.55), yellow,
        segments=40, scale=(1.05, 0.85, 1.05),
    )

    beak_u = mesh_cone(
        "bird_beak_u", 0.14, 0.38, (1.12, 0.0, z0 + 0.55), orange,
        vertices=14, rotation=(0, math.radians(90), math.radians(-6)),
    )
    beak_l = mesh_cone(
        "bird_beak_l", 0.1, 0.26, (1.08, 0.0, z0 + 0.45), orange,
        vertices=12, rotation=(0, math.radians(90), math.radians(14)),
    )

    eye = mesh_uv_sphere(
        "bird_eye", 0.16, (0.92, 0.3, z0 + 0.62), white,
        segments=18, scale=(1.0, 0.9, blink),
    )
    pupil = mesh_uv_sphere(
        "bird_pupil", 0.085, (1.0, 0.34, z0 + 0.62), black,
        segments=14, scale=(1.0, 0.95, blink),
    )
    highlight = mesh_uv_sphere(
        "bird_hi", 0.04, (1.04, 0.38, z0 + 0.68), white,
        segments=8, scale=(1.0, 1.0, blink),
    )
    cheek = mesh_uv_sphere(
        "bird_cheek", 0.09, (0.82, 0.34, z0 + 0.48), blush,
        segments=12, scale=(1.15, 0.45, 0.7),
    )

    # Twin crest feathers.
    crest_l = mesh_cone(
        "bird_crest_l", 0.08, 0.32, (0.62, 0.06, z0 + 0.95), crest_mat,
        vertices=8, rotation=(math.radians(8), math.radians(-20), 0),
    )
    crest_r = mesh_cone(
        "bird_crest_r", 0.07, 0.28, (0.7, -0.02, z0 + 0.92), crest_mat,
        vertices=8, rotation=(math.radians(-5), math.radians(-35), 0),
    )

    # Big flapping wing — angle 0 = straight up, 90 = forward, 180 = down.
    shoulder = (-0.05, 0.22, z0 + 0.15)
    wing_parts = _wing_piece("bird_wing", wing_mat, wing_tip, shoulder, wing_angle)

    # Tail fan.
    tail_parts = []
    for i, spread in enumerate((-28 - tail_fan, -10, 10, 28 + tail_fan)):
        t = mesh_cone(
            f"bird_tail{i}", 0.12, 0.5,
            (-0.7, 0.04 * (i - 1.5), z0 + 0.05),
            wing_tip if i in (0, 3) else wing_mat,
            vertices=9, rotation=(0, math.radians(spread + 180), 0),
        )
        tail_parts.append(t)

    # Visible cartoon feet.
    leg_l = mesh_cylinder(
        "bird_leg_l", 0.04, 0.22, (0.2, 0.14, z0 - 0.55), foot_mat, vertices=8
    )
    leg_r = mesh_cylinder(
        "bird_leg_r", 0.04, 0.22, (0.2, -0.06, z0 - 0.55), foot_mat, vertices=8
    )
    foot_l = mesh_cube(
        "bird_foot_l", (0.22, 0.1, 0.06), (0.28, 0.14, z0 - 0.66), foot_mat
    )
    foot_r = mesh_cube(
        "bird_foot_r", (0.22, 0.1, 0.06), (0.28, -0.06, z0 - 0.66), foot_mat
    )
    bevel(foot_l, width=0.02, segments=2)
    bevel(foot_r, width=0.02, segments=2)

    parts = [
        body, belly, neck, head, beak_u, beak_l, eye, pupil, highlight, cheek,
        crest_l, crest_r, *wing_parts, *tail_parts, leg_l, leg_r, foot_l, foot_r,
    ]
    return join_objects(parts, "bird", smooth=True)


def bird_pose(frame: int) -> dict:
    """8-frame flap: wing_angle is degrees from UP (0) toward DOWN (180)."""
    table = [
        # wing_from_up, bob, squash, blink, tail_fan
        (25, 0.04, 0.98, 1.0, 6),
        (5, 0.1, 0.9, 1.0, 14),       # wings high
        (15, 0.08, 0.92, 1.0, 10),
        (55, 0.02, 1.0, 1.0, 4),
        (100, -0.04, 1.08, 1.0, -4),   # sweeping down
        (145, -0.1, 1.15, 1.0, -10),   # full downstroke
        (110, -0.05, 1.08, 0.2, -4),   # blink + recover
        (50, 0.0, 1.0, 1.0, 2),
    ]
    wing, bob, squash, blink, fan = table[(frame - 1) % 8]
    return {
        "wing_angle": wing,
        "body_bob": bob,
        "squash": squash,
        "blink": blink,
        "tail_fan": fan,
    }


# ─── food (spin poses) ───────────────────────────────────────────────────────


def build_food(
    kind: str,
    *,
    spin: float = 0.0,
    bounce: float = 0.0,
    with_outline: bool = True,
) -> bpy.types.Object:
    if kind == "berries":
        berry = toon_material("berry", (0.55, 0.12, 0.65, 1.0))
        leaf = toon_material("berry_leaf", (0.25, 0.65, 0.22, 1.0), steps=2)
        highlight = toon_material("berry_hi", (0.85, 0.45, 0.9, 1.0), steps=2)
        parts = []
        for i, (ox, oy, oz) in enumerate(
            [(-0.22, 0.08, 0.0), (0.24, 0.05, 0.02), (0.02, -0.08, 0.28),
             (-0.05, 0.18, 0.2)]
        ):
            b = mesh_uv_sphere(f"b{i}", 0.26, (ox, oy, oz + bounce), berry, segments=18)
            h = mesh_uv_sphere(
                f"bh{i}", 0.08, (ox + 0.08, oy + 0.1, oz + 0.1 + bounce), highlight,
                segments=8, scale=(1.0, 0.6, 0.7),
            )
            parts.extend([b, h])
        stem = mesh_cylinder("stem", 0.03, 0.2, (0.05, 0, 0.55 + bounce), leaf)
        leaf_a = mesh_uv_sphere(
            "leaf", 0.2, (0.2, 0.05, 0.58 + bounce), leaf,
            scale=(1.4, 0.25, 0.7),
        )
        parts.extend([stem, leaf_a])
        root = join_objects(parts, "food_berries")
    elif kind == "chili":
        red = toon_material("chili", (0.92, 0.1, 0.08, 1.0))
        green = toon_material("chili_stem", (0.25, 0.6, 0.18, 1.0), steps=2)
        # Curved pepper silhouette extruded for a real chili shape.
        chili_pts = [
            (0.05, 0.55 + bounce), (0.22, 0.35 + bounce), (0.28, 0.0 + bounce),
            (0.18, -0.35 + bounce), (0.05, -0.65 + bounce), (-0.02, -0.55 + bounce),
            (-0.12, -0.2 + bounce), (-0.15, 0.15 + bounce), (-0.08, 0.45 + bounce),
        ]
        body = extrude_profile("chili_body", chili_pts, width=0.45, material=red)
        bevel(body, width=0.04, segments=3)
        stem = mesh_cylinder("chili_stem", 0.06, 0.2, (0.0, 0, 0.68 + bounce), green)
        leaf_a = mesh_uv_sphere(
            "chili_leaf_a", 0.16, (0.14, 0.05, 0.72 + bounce), green,
            scale=(1.4, 0.25, 0.7),
        )
        leaf_b = mesh_uv_sphere(
            "chili_leaf_b", 0.12, (-0.1, -0.04, 0.7 + bounce), green,
            scale=(1.2, 0.25, 0.6),
        )
        shine = mesh_uv_sphere(
            "chili_shine", 0.08, (0.12, 0.15, 0.15 + bounce),
            toon_material("chili_hi", (1.0, 0.45, 0.35, 1.0), steps=2),
            scale=(0.7, 0.4, 1.2),
        )
        root = join_objects([body, stem, leaf_a, leaf_b, shine], "food_chili")
    else:
        tortilla = toon_material("burrito", (0.92, 0.78, 0.42, 1.0))
        filling = toon_material("burrito_fill", (0.5, 0.28, 0.12, 1.0), steps=2)
        green = toon_material("burrito_lettuce", (0.35, 0.65, 0.25, 1.0), steps=2)
        body = mesh_cylinder(
            "burrito_body", 0.36, 1.15, (0, 0, bounce), tortilla,
            vertices=20, rotation=(0, math.radians(90), 0),
        )
        end = mesh_uv_sphere("burrito_end", 0.34, (0.58, 0, bounce), filling, segments=14)
        wrap = mesh_uv_sphere(
            "burrito_wrap", 0.38, (-0.5, 0, bounce), tortilla,
            segments=14, scale=(0.7, 1.0, 1.0),
        )
        lettuce = mesh_cube(
            "burrito_g", (0.15, 0.25, 0.08), (0.35, 0.15, 0.2 + bounce), green
        )
        root = join_objects([body, end, wrap, lettuce], "food_burrito")

    root.rotation_euler = Euler((math.radians(spin * 0.35), math.radians(spin), 0))
    apply_loc_rot_scale(root)
    return root


def food_pose(frame: int) -> dict:
    """6-frame tumble/spin for pickups."""
    spins = [0, 60, 120, 180, 240, 300]
    bounces = [0.0, 0.06, 0.1, 0.05, -0.02, 0.03]
    i = (frame - 1) % 6
    return {"spin": spins[i], "bounce": bounces[i]}


# ─── UI props ────────────────────────────────────────────────────────────────


def build_coin(*, spin: float = 0.0, with_outline: bool = True) -> bpy.types.Object:
    gold = toon_material("coin_gold", (1.0, 0.8, 0.15, 1.0))
    rim = toon_material("coin_rim", (0.85, 0.55, 0.08, 1.0), steps=2)
    emblem = toon_material("coin_em", (0.95, 0.7, 0.1, 1.0), steps=2)
    disc = mesh_cylinder("coin", 0.55, 0.1, (0, 0, 0), gold, vertices=32)
    edge = mesh_cylinder("coin_edge", 0.58, 0.07, (0, 0, 0), rim, vertices=32)
    star = mesh_uv_sphere(
        "coin_star", 0.22, (0, 0.02, 0), emblem, segments=12, scale=(1.0, 0.3, 1.0)
    )
    root = join_objects([disc, edge, star], "coin")
    # Flip for a coin-spin cycle (thin when edge-on).
    root.rotation_euler = Euler((math.radians(90), math.radians(spin), 0))
    apply_loc_rot_scale(root)
    return root


def build_trophy(tier: str, *, with_outline: bool = True) -> bpy.types.Object:
    colors = {
        "bronze": (0.75, 0.42, 0.18, 1.0),
        "silver": (0.8, 0.82, 0.88, 1.0),
        "gold": (1.0, 0.8, 0.15, 1.0),
    }
    metal = toon_material(f"trophy_{tier}", colors[tier])
    dark = toon_material(f"trophy_{tier}_base", (0.18, 0.12, 0.08, 1.0), steps=2)
    cup = mesh_cylinder(f"{tier}_cup", 0.42, 0.55, (0, 0, 0.95), metal, vertices=24)
    # Cup flare.
    rim = mesh_cylinder(f"{tier}_rim", 0.5, 0.1, (0, 0, 1.2), metal, vertices=24)
    stem = mesh_cylinder(f"{tier}_stem", 0.1, 0.5, (0, 0, 0.45), metal, vertices=12)
    base = mesh_cube(f"{tier}_base", (0.75, 0.55, 0.2), (0, 0, 0.1), dark)
    bevel(base, width=0.04, segments=2)
    hl = mesh_cylinder(
        f"{tier}_hl", 0.07, 0.4, (-0.48, 0, 0.95), metal,
        rotation=(0, 0, math.radians(90)), vertices=10,
    )
    hr = mesh_cylinder(
        f"{tier}_hr", 0.07, 0.4, (0.48, 0, 0.95), metal,
        rotation=(0, 0, math.radians(90)), vertices=10,
    )
    return join_objects([cup, rim, stem, base, hl, hr], f"trophy_{tier}")


def build_medal(*, with_outline: bool = True) -> bpy.types.Object:
    gold = toon_material("medal", (0.95, 0.75, 0.15, 1.0))
    ribbon = toon_material("medal_ribbon", (0.8, 0.12, 0.18, 1.0), steps=2)
    disc = mesh_cylinder("medal_disc", 0.42, 0.08, (0, 0, 0), gold, vertices=28)
    disc.rotation_euler = Euler((math.radians(90), 0, 0))
    apply_loc_rot_scale(disc)
    star = mesh_uv_sphere(
        "medal_star", 0.16, (0, 0.02, 0), gold, scale=(1.0, 0.35, 1.0)
    )
    rib_l = mesh_cube("medal_rl", (0.16, 0.06, 0.55), (-0.1, 0, 0.5), ribbon)
    rib_r = mesh_cube("medal_rr", (0.16, 0.06, 0.55), (0.1, 0, 0.5), ribbon)
    return join_objects([disc, star, rib_l, rib_r], "medal")


def build_tire(*, with_outline: bool = True) -> bpy.types.Object:
    rubber = toon_material("tire", (0.08, 0.08, 0.09, 1.0), steps=2)
    hub = toon_material("tire_hub", (0.75, 0.75, 0.78, 1.0), steps=2)
    rim = toon_material("tire_rim", (0.4, 0.4, 0.42, 1.0), steps=2)
    tire = mesh_cylinder("tire", 0.52, 0.24, (0, 0, 0), rubber, vertices=24)
    ring = mesh_cylinder("rim", 0.32, 0.26, (0, 0, 0), rim, vertices=16)
    cap = mesh_cylinder("hub", 0.18, 0.28, (0, 0, 0), hub, vertices=12)
    # Tread nubs.
    nubs = []
    for i in range(8):
        a = i * (math.pi * 2 / 8)
        nubs.append(
            mesh_cube(
                f"tread{i}",
                (0.08, 0.26, 0.1),
                (math.cos(a) * 0.5, 0, math.sin(a) * 0.5),
                rubber,
            )
        )
    root = join_objects([tire, ring, cap, *nubs], "tire")
    root.rotation_euler = Euler((0, math.radians(90), 0))
    apply_loc_rot_scale(root)
    return root


def build_skyline_tile(*, seed: int, near: bool, length: float = 12.0):
    rng = random.Random(seed)
    if near:
        body_c = (0.38, 0.48, 0.58, 1.0)
        win_c = (0.98, 0.9, 0.5, 1.0)
        h_range = (1.4, 3.2)
    else:
        body_c = (0.58, 0.68, 0.8, 1.0)
        win_c = (0.75, 0.85, 0.92, 1.0)
        h_range = (2.0, 4.5)

    body_mat = toon_material(f"sky_{seed}_body", body_c, steps=2)
    win_mat = toon_material(f"sky_{seed}_win", win_c, steps=2)
    objs = []
    x = -length * 0.5
    while x < length * 0.5:
        w = 0.75 + rng.random() * 1.2
        h = h_range[0] + rng.random() * (h_range[1] - h_range[0])
        b = mesh_cube(
            f"b_{seed}_{len(objs)}", (w, 0.7, h), (x + w * 0.5, 0, h * 0.5), body_mat
        )
        bevel(b, width=0.04, segments=2)
        objs.append(b)
        # Roof water tower / antenna occasionally.
        if rng.random() > 0.65:
            objs.append(
                mesh_cylinder(
                    f"ant_{len(objs)}", 0.04, 0.45,
                    (x + w * 0.5, 0, h + 0.2), body_mat, vertices=6,
                )
            )
        wy = 0.45
        while wy < h - 0.35:
            wx = x + 0.18
            while wx < x + w - 0.28:
                if rng.random() > 0.15:
                    objs.append(
                        mesh_cube(
                            f"w_{seed}_{len(objs)}",
                            (0.16, 0.06, 0.2),
                            (wx, 0.36, wy),
                            win_mat,
                        )
                    )
                wx += 0.32
            wy += 0.42
        x += w + 0.12 + rng.random() * 0.4
    return objs


def build_cloud_tile():
    white = toon_material("cloud", (0.98, 0.98, 1.0, 1.0), steps=2)
    blobs = [
        ((-3.5, 0, 1.2), 0.95),
        ((-2.5, 0, 1.45), 0.75),
        ((-1.7, 0, 1.2), 0.85),
        ((0.8, 0, 2.1), 1.15),
        ((1.9, 0, 2.35), 0.9),
        ((2.9, 0, 2.0), 0.75),
        ((4.6, 0, 1.1), 0.8),
        ((5.5, 0, 1.25), 0.6),
    ]
    return [
        mesh_uv_sphere(
            f"cloud_{i}", r, loc, white, segments=18, scale=(1.7, 0.75, 0.95)
        )
        for i, (loc, r) in enumerate(blobs)
    ]
