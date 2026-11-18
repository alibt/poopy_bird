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


def _arch(
    x0: float, x1: float, bottom: float = 0.05, top: float = 0.48
) -> list[tuple[float, float]]:
    """Wheel-arch notch along the bottom edge (x0 rear → x1 front)."""
    mid = (x0 + x1) * 0.5
    return [
        (x0, bottom),
        (x0 + (mid - x0) * 0.35, top),
        (mid, top),
        (x1 - (x1 - mid) * 0.35, top),
        (x1, bottom),
    ]


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
        *_arch(-L * 0.55, -L * 0.18),  # rear wheel
        *_arch(L * 0.15, L * 0.52),    # front wheel
        (L * 0.55, 0.18),
    ]


def _sports_profile(length: float = 2.7) -> list[tuple[float, float]]:
    L = length * 0.5
    return [
        (L * 1.0, 0.15), (L * 1.05, 0.32), (L * 0.7, 0.42),
        (L * 0.15, 0.48), (-L * 0.05, 0.78), (-L * 0.45, 0.78),
        (-L * 0.7, 0.5), (-L * 1.0, 0.38), (-L * 0.98, 0.15),
        *_arch(-L * 0.55, -L * 0.2, bottom=0.05, top=0.42),
        *_arch(L * 0.12, L * 0.5, bottom=0.05, top=0.42),
        (L * 0.5, 0.15),
    ]


def _bus_profile(length: float = 3.4) -> list[tuple[float, float]]:
    L = length * 0.5
    return [
        (L * 0.95, 0.2), (L * 1.0, 0.55), (L * 0.9, 1.55),
        (-L * 0.9, 1.55), (-L * 1.0, 0.55), (-L * 0.95, 0.2),
        *_arch(-L * 0.55, -L * 0.15, bottom=0.08, top=0.5),
        *_arch(-0.2, 0.25, bottom=0.08, top=0.5),
        *_arch(L * 0.2, L * 0.55, bottom=0.08, top=0.5),
        (L * 0.5, 0.2),
    ]


def _limo_profile(length: float = 4.0) -> list[tuple[float, float]]:
    L = length * 0.5
    return [
        (L * 0.98, 0.18), (L * 1.02, 0.38), (L * 0.8, 0.55),
        (L * 0.55, 0.62), (L * 0.35, 1.05), (-L * 0.55, 1.05),
        (-L * 0.75, 0.62), (-L * 0.98, 0.4), (-L * 0.96, 0.18),
        *_arch(-L * 0.55, -L * 0.25),
        *_arch(-0.45, -0.05),
        *_arch(0.2, 0.55),
        *_arch(L * 0.2, L * 0.52),
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
            (-L * 0.98, 0.18),
            *_arch(-L * 0.55, -L * 0.18),
            *_arch(L * 0.15, L * 0.52),
            (L * 0.5, 0.18),
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

    # Bumpers + grille + lights.
    parts.append(mesh_cube(f"{kind}_fb", (0.18, 1.2, 0.2), (length * 0.48, 0, 0.28), chrome))
    parts.append(mesh_cube(f"{kind}_rb", (0.16, 1.2, 0.18), (-length * 0.48, 0, 0.28), chrome))
    grille = mesh_cube(
        f"{kind}_grille", (0.06, 0.7, 0.22), (length * 0.50, 0, 0.42), dark
    )
    parts.append(grille)
    for i, gy in enumerate((-0.18, 0.0, 0.18)):
        parts.append(
            mesh_cube(
                f"{kind}_gbar{i}", (0.04, 0.08, 0.18),
                (length * 0.505, gy, 0.42), chrome,
            )
        )
    parts.append(_headlight(f"{kind}_hl", (length * 0.47, 0.35, 0.45)))
    parts.append(_headlight(f"{kind}_hl2", (length * 0.47, -0.35, 0.45)))
    parts.append(_taillight(f"{kind}_tl", (-length * 0.48, 0.35, 0.48)))
    parts.append(_taillight(f"{kind}_tl2", (-length * 0.48, -0.35, 0.48)))

    # Character line + door seam for silhouette interest.
    parts.append(
        mesh_cube(
            f"{kind}_cline", (length * 0.7, 1.17, 0.04), (0.05, 0, 0.48),
            toon_material(f"{kind}_cline", tuple(max(0, c * 0.75) for c in body_color[:3]) + (1.0,), steps=2),
        )
    )
    parts.append(mesh_cube(f"{kind}_door", (0.03, 1.18, 0.45), (0.05, 0, 0.55), dark))

    mirror = mesh_cube(f"{kind}_mirror", (0.1, 0.2, 0.1), (length * 0.08, 0.6, 0.9), dark)
    bevel(mirror, width=0.02, segments=2)
    parts.append(mirror)

    # Wheel arches so the body doesn't read as a floating slab.
    arch_mat = toon_material(f"{kind}_arch", (0.06, 0.06, 0.08, 1.0), steps=2)
    arch_xs = (-length * 0.32, length * 0.3)
    if kind == "limo":
        arch_xs = (-length * 0.38, -0.25, 0.4, length * 0.35)
    elif kind == "bus":
        arch_xs = (-length * 0.35, 0.0, length * 0.32)
    for x in arch_xs:
        arch = mesh_cylinder(
            f"{kind}_arch_{x:.2f}", 0.30, 1.22, (x, 0, 0.06), arch_mat,
            vertices=18, rotation=(math.radians(90), 0, 0),
        )
        parts.append(arch)

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
        # Wheels sit inside the arched body silhouette.
        for x in xs:
            for y in (-0.52, 0.52):
                parts.extend(
                    _wheel(f"{kind}_w_{x:.2f}_{y:.1f}", (x, y, 0.24), 0.24)
                )

    return join_objects(parts, f"car_{kind}")


def build_car_wash_truck(*, with_outline: bool = True) -> bpy.types.Object:
    blue = toon_material("cwt_cab", (0.12, 0.45, 0.9, 1.0))
    tank = toon_material("cwt_tank", (0.55, 0.82, 0.95, 1.0))
    yellow = toon_material("cwt_brush", (1.0, 0.88, 0.08, 1.0), steps=3)
    white = toon_material("cwt_stripe", (0.96, 0.96, 0.98, 1.0))
    glass = toon_material("cwt_glass", (0.5, 0.78, 0.95, 1.0), steps=2)
    dark = toon_material("cwt_dark", (0.12, 0.12, 0.14, 1.0), steps=2)

    cab = mesh_cube("cwt_cab", (1.2, 1.25, 1.2), (1.5, 0, 0.85), blue)
    bevel(cab, width=0.08, segments=3)
    window = mesh_cube("cwt_window", (0.12, 0.95, 0.5), (2.05, 0, 1.05), glass)
    tank_body = mesh_cylinder(
        "cwt_tank", 0.75, 2.7, (-0.45, 0, 1.05), tank,
        vertices=28, rotation=(0, math.radians(90), 0),
    )
    tank_body.scale = (1.0, 0.92, 1.0)
    apply_loc_rot_scale(tank_body)
    stripe = mesh_cube("cwt_stripe", (2.6, 1.32, 0.18), (-0.45, 0, 0.9), white)
    # Spinning wash brushes — bright fluffy spheres on poles.
    parts = [cab, window, tank_body, stripe]
    for i, x in enumerate((-0.15, -1.25)):
        pole = mesh_cylinder(f"cwt_pole{i}", 0.07, 0.85, (x, 0, 1.65), dark)
        brush = mesh_uv_sphere(
            f"cwt_brush{i}", 0.48, (x, 0, 2.15), yellow,
            segments=24, ring_count=16, scale=(1.05, 1.05, 0.9),
        )
        bristle = mesh_uv_sphere(
            f"cwt_br{i}", 0.55, (x, 0, 2.1),
            toon_material(f"cwt_br{i}", (1.0, 0.95, 0.25, 1.0), steps=2),
            segments=18, scale=(1.2, 1.2, 0.5),
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
    yellow = toon_material("bird_body", (1.0, 0.86, 0.18, 1.0), steps=4)
    wing_mat = toon_material("bird_wing", (1.0, 0.68, 0.08, 1.0), steps=4)
    wing_tip = toon_material("bird_tip", (0.95, 0.38, 0.05, 1.0), steps=3)
    belly_mat = toon_material("bird_belly", (1.0, 0.96, 0.78, 1.0), steps=3)
    orange = toon_material("bird_beak", (1.0, 0.48, 0.06, 1.0), steps=3)
    white = toon_material("bird_eye", (1.0, 1.0, 1.0, 1.0), steps=2)
    black = toon_material("bird_pupil", (0.05, 0.05, 0.07, 1.0), steps=2)
    blush = toon_material("bird_blush", (1.0, 0.48, 0.42, 1.0), steps=2)
    crest_mat = toon_material("bird_crest", (1.0, 0.42, 0.08, 1.0), steps=3)
    foot_mat = toon_material("bird_foot", (1.0, 0.4, 0.06, 1.0), steps=3)
    brow = toon_material("bird_brow", (0.85, 0.55, 0.1, 1.0), steps=2)

    z0 = body_bob
    sx, sz = 1.0 / math.sqrt(squash), squash

    # Plumper mascot: clear head/body, soft belly, readable beak.
    body = mesh_uv_sphere(
        "bird_body", 0.68, (0.02, 0.0, z0 - 0.02), yellow,
        segments=56, ring_count=32, scale=(1.28 * sx, 0.82, 1.12 * sz),
    )
    belly = mesh_uv_sphere(
        "bird_belly", 0.48, (0.22, 0.1, z0 - 0.2), belly_mat,
        segments=36, scale=(1.2 * sx, 0.58, 0.9 * sz),
    )
    neck = mesh_uv_sphere(
        "bird_neck", 0.24, (0.48, 0.0, z0 + 0.32), yellow,
        segments=28, scale=(0.95, 0.72, 0.9),
    )
    head = mesh_uv_sphere(
        "bird_head", 0.46, (0.78, 0.0, z0 + 0.58), yellow,
        segments=44, scale=(1.08, 0.88, 1.08),
    )

    beak_u = mesh_cone(
        "bird_beak_u", 0.15, 0.42, (1.22, 0.0, z0 + 0.58), orange,
        vertices=16, rotation=(0, math.radians(90), math.radians(-8)),
    )
    beak_l = mesh_cone(
        "bird_beak_l", 0.11, 0.28, (1.16, 0.0, z0 + 0.46), orange,
        vertices=14, rotation=(0, math.radians(90), math.radians(16)),
    )

    # Near eye (big) + far eye peek so the face reads in 3/4.
    eye = mesh_uv_sphere(
        "bird_eye", 0.18, (0.98, 0.32, z0 + 0.66), white,
        segments=20, scale=(1.05, 0.95, blink),
    )
    pupil = mesh_uv_sphere(
        "bird_pupil", 0.09, (1.08, 0.36, z0 + 0.66), black,
        segments=16, scale=(1.0, 0.95, blink),
    )
    highlight = mesh_uv_sphere(
        "bird_hi", 0.045, (1.12, 0.4, z0 + 0.72), white,
        segments=10, scale=(1.0, 1.0, blink),
    )
    eye_f = mesh_uv_sphere(
        "bird_eye_f", 0.12, (0.95, -0.22, z0 + 0.64), white,
        segments=16, scale=(0.9, 0.85, blink * 0.95),
    )
    pupil_f = mesh_uv_sphere(
        "bird_pupil_f", 0.055, (1.0, -0.24, z0 + 0.64), black,
        segments=12, scale=(1.0, 0.9, blink * 0.95),
    )
    cheek = mesh_uv_sphere(
        "bird_cheek", 0.1, (0.88, 0.36, z0 + 0.5), blush,
        segments=14, scale=(1.2, 0.42, 0.75),
    )
    eyebrow = mesh_cube(
        "bird_brow", (0.16, 0.06, 0.05), (0.95, 0.34, z0 + 0.8), brow
    )
    bevel(eyebrow, width=0.015, segments=2)

    crest_l = mesh_cone(
        "bird_crest_l", 0.09, 0.38, (0.68, 0.08, z0 + 1.02), crest_mat,
        vertices=10, rotation=(math.radians(10), math.radians(-18), 0),
    )
    crest_r = mesh_cone(
        "bird_crest_r", 0.08, 0.32, (0.78, -0.04, z0 + 0.98), crest_mat,
        vertices=10, rotation=(math.radians(-6), math.radians(-38), 0),
    )
    crest_m = mesh_cone(
        "bird_crest_m", 0.06, 0.26, (0.72, 0.02, z0 + 1.05), wing_tip,
        vertices=8, rotation=(math.radians(2), math.radians(-28), 0),
    )

    shoulder = (-0.02, 0.26, z0 + 0.18)
    wing_parts = _wing_piece("bird_wing", wing_mat, wing_tip, shoulder, wing_angle)
    # Far-side stub wing for volume.
    far_wing = mesh_uv_sphere(
        "bird_wing_far", 0.28, (-0.05, -0.35, z0 + 0.05), wing_mat,
        segments=18, scale=(1.1, 0.35, 0.7),
    )

    tail_parts = []
    for i, spread in enumerate((-32 - tail_fan, -12, 8, 28 + tail_fan, 42 + tail_fan * 0.5)):
        t = mesh_cone(
            f"bird_tail{i}", 0.11, 0.55,
            (-0.78, 0.05 * (i - 2), z0 + 0.06),
            wing_tip if i in (0, 4) else wing_mat,
            vertices=10, rotation=(0, math.radians(spread + 180), 0),
        )
        tail_parts.append(t)

    leg_l = mesh_cylinder(
        "bird_leg_l", 0.045, 0.26, (0.22, 0.16, z0 - 0.58), foot_mat, vertices=8
    )
    leg_r = mesh_cylinder(
        "bird_leg_r", 0.045, 0.26, (0.22, -0.08, z0 - 0.58), foot_mat, vertices=8
    )
    foot_l = mesh_cube(
        "bird_foot_l", (0.26, 0.12, 0.07), (0.32, 0.16, z0 - 0.72), foot_mat
    )
    foot_r = mesh_cube(
        "bird_foot_r", (0.26, 0.12, 0.07), (0.32, -0.08, z0 - 0.72), foot_mat
    )
    bevel(foot_l, width=0.025, segments=2)
    bevel(foot_r, width=0.025, segments=2)
    # Tiny toes.
    for i, ox in enumerate((0.08, 0.0, -0.08)):
        toe = mesh_cube(
            f"bird_toe{i}", (0.1, 0.04, 0.035),
            (0.42, 0.16 + ox * 0.3, z0 - 0.72), foot_mat,
        )
        tail_parts.append(toe)

    parts = [
        body, belly, neck, head, beak_u, beak_l, eye, pupil, highlight, eye_f,
        pupil_f, cheek, eyebrow, crest_l, crest_r, crest_m, far_wing,
        *wing_parts, *tail_parts, leg_l, leg_r, foot_l, foot_r,
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
            b = mesh_uv_sphere(f"b{i}", 0.26, (ox, oy, oz + bounce), berry, segments=32, ring_count=20)
            h = mesh_uv_sphere(
                f"bh{i}", 0.08, (ox + 0.08, oy + 0.1, oz + 0.1 + bounce), highlight,
                segments=12, scale=(1.0, 0.6, 0.7),
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
    """Circular face with bold 5-spoke hub so in-game spin is readable.

    Built in the XZ plane, then tipped so a +Y camera sees the face.
    """
    rubber = toon_material("tire", (0.07, 0.07, 0.08, 1.0), steps=2)
    hub = toon_material("tire_hub", (0.88, 0.88, 0.90, 1.0), steps=2)
    rim = toon_material("tire_rim", (0.35, 0.35, 0.38, 1.0), steps=2)
    spoke_mat = toon_material("tire_spoke", (0.95, 0.8, 0.18, 1.0), steps=2)
    # Cylinder along Y so +Y camera looks straight at the circular face.
    tire = mesh_cylinder(
        "tire", 0.52, 0.22, (0, 0, 0), rubber, vertices=28,
        rotation=(math.radians(90), 0, 0),
    )
    ring = mesh_cylinder(
        "rim", 0.34, 0.24, (0, 0, 0), rim, vertices=20,
        rotation=(math.radians(90), 0, 0),
    )
    cap = mesh_cylinder(
        "hub", 0.14, 0.28, (0, 0, 0), hub, vertices=14,
        rotation=(math.radians(90), 0, 0),
    )
    parts = [tire, ring, cap]
    for i in range(5):
        a = i * (math.pi * 2 / 5)
        spoke = mesh_cube(
            f"spoke{i}",
            (0.3, 0.1, 0.09),
            (math.cos(a) * 0.2, 0.02, math.sin(a) * 0.2),
            spoke_mat,
        )
        spoke.rotation_euler = Euler((0, 0, a))
        apply_loc_rot_scale(spoke)
        parts.append(spoke)
    # Valve stem — off-center cue for spin.
    parts.append(
        mesh_uv_sphere(
            "valve", 0.06, (0.0, 0.06, 0.42), hub,
            segments=10, ring_count=8,
        )
    )
    return join_objects(parts, "tire")


def build_skyline_tile(*, seed: int, near: bool, length: float = 12.0):
    """Apartment row sitting on a continuous sidewalk plinth (z=0)."""
    rng = random.Random(seed)
    if near:
        body_c = (0.38, 0.46, 0.58, 1.0)
        accent_c = (0.30, 0.38, 0.50, 1.0)
        shop_c = (0.55, 0.38, 0.28, 1.0)
        win_c = (1.0, 0.93, 0.62, 1.0)
        win_off = (0.28, 0.34, 0.45, 1.0)
        h_range = (1.8, 3.6)
        depth = 1.05
    else:
        body_c = (0.58, 0.68, 0.80, 1.0)
        accent_c = (0.48, 0.58, 0.70, 1.0)
        shop_c = (0.52, 0.56, 0.62, 1.0)
        win_c = (0.86, 0.92, 0.98, 1.0)
        win_off = (0.46, 0.54, 0.64, 1.0)
        h_range = (2.4, 5.0)
        depth = 0.78

    body_mat = toon_material(f"sky_{seed}_body", body_c, steps=3)
    accent_mat = toon_material(f"sky_{seed}_acc", accent_c, steps=2)
    shop_mat = toon_material(f"sky_{seed}_shop", shop_c, steps=2)
    win_mat = toon_material(f"sky_{seed}_win", win_c, steps=2)
    win_off_mat = toon_material(f"sky_{seed}_wo", win_off, steps=2)
    curb_mat = toon_material(
        f"sky_{seed}_curb", (0.72, 0.74, 0.76, 1.0), steps=2
    )
    walk_mat = toon_material(
        f"sky_{seed}_walk", (0.62, 0.64, 0.66, 1.0), steps=2
    )

    # Continuous sidewalk that pins the strip to the street line.
    objs = [
        mesh_cube(
            f"walk_{seed}", (length + 0.4, depth + 0.35, 0.18),
            (0, 0.05, 0.09), walk_mat,
        ),
        mesh_cube(
            f"curb_{seed}", (length + 0.4, 0.22, 0.28),
            (0, depth * 0.55, 0.14), curb_mat,
        ),
    ]

    x = -length * 0.5
    while x < length * 0.5:
        w = 0.85 + rng.random() * 1.15
        h = h_range[0] + rng.random() * (h_range[1] - h_range[0])
        style = rng.choice(["block", "setback", "tower", "ledge"])
        cx = x + w * 0.5
        # Buildings sit ON the sidewalk (base at z≈0.18).
        base_z = 0.18

        b = mesh_cube(
            f"b_{seed}_{len(objs)}", (w, depth, h),
            (cx, 0, base_z + h * 0.5), body_mat,
        )
        # Tiny bevel only — sharp apartments, not melted clay.
        bevel(b, width=0.02, segments=1)
        objs.append(b)

        if near:
            objs.append(
                mesh_cube(
                    f"shop_{len(objs)}", (w * 0.92, depth + 0.04, 0.55),
                    (cx, 0.02, base_z + 0.35), shop_mat,
                )
            )
            # Door
            objs.append(
                mesh_cube(
                    f"door_{len(objs)}", (0.22, 0.06, 0.42),
                    (cx - w * 0.15, depth * 0.52, base_z + 0.28),
                    toon_material(f"door_{len(objs)}", (0.2, 0.16, 0.14, 1.0), steps=2),
                )
            )

        if style == "setback" and h > 2.4:
            objs.append(
                mesh_cube(
                    f"set_{len(objs)}", (w * 0.7, depth * 0.85, 0.7),
                    (cx, 0, base_z + h + 0.25), accent_mat,
                )
            )
        elif style == "tower":
            objs.append(
                mesh_cube(
                    f"tow_{len(objs)}", (w * 0.32, depth * 0.7, 1.1),
                    (cx + w * 0.18, 0, base_z + h + 0.4), accent_mat,
                )
            )
            objs.append(
                mesh_cylinder(
                    f"ant_{len(objs)}", 0.03, 0.65,
                    (cx + w * 0.18, 0, base_z + h + 1.15), accent_mat, vertices=6,
                )
            )
        elif style == "ledge":
            objs.append(
                mesh_cube(
                    f"led_{len(objs)}", (w * 1.05, depth * 1.08, 0.12),
                    (cx, 0, base_z + h * 0.55), accent_mat,
                )
            )
            objs.append(
                mesh_cube(
                    f"corn_{len(objs)}", (w * 1.02, depth * 1.05, 0.14),
                    (cx, 0, base_z + h + 0.05), accent_mat,
                )
            )
        else:
            objs.append(
                mesh_cube(
                    f"roof_{len(objs)}", (w * 1.02, depth * 1.05, 0.12),
                    (cx, 0, base_z + h + 0.04), accent_mat,
                )
            )
            if rng.random() > 0.45:
                objs.append(
                    mesh_cylinder(
                        f"tank_{len(objs)}", 0.16, 0.28,
                        (cx - w * 0.22, 0, base_z + h + 0.22), accent_mat,
                        vertices=10, rotation=(0, math.radians(90), 0),
                    )
                )

        # Ordered window grid.
        wy = base_z + (0.95 if near else 0.7)
        while wy < base_z + h - 0.25:
            wx = x + 0.18
            while wx < x + w - 0.18:
                lit = rng.random() > (0.25 if near else 0.4)
                objs.append(
                    mesh_cube(
                        f"w_{seed}_{len(objs)}",
                        (0.16, 0.06, 0.22),
                        (wx, depth * 0.52, wy),
                        win_mat if lit else win_off_mat,
                    )
                )
                wx += 0.32
            wy += 0.42
        x += w + 0.08 + rng.random() * 0.22
    return objs


def build_tree(*, seed: int = 0) -> list[bpy.types.Object]:
    """Cartoon roadside tree — trunk + layered canopy."""
    rng = random.Random(seed)
    bark = toon_material("tree_bark", (0.45, 0.28, 0.14, 1.0), steps=3)
    leaf_a = toon_material("tree_leaf_a", (0.18, 0.58, 0.22, 1.0), steps=3)
    leaf_b = toon_material("tree_leaf_b", (0.12, 0.42, 0.16, 1.0), steps=2)
    leaf_c = toon_material("tree_leaf_c", (0.28, 0.70, 0.26, 1.0), steps=2)
    trunk = mesh_cylinder("trunk", 0.16, 1.5, (0, 0, 0.75), bark, vertices=12)
    canopy = [
        mesh_uv_sphere(
            "canopy_main", 0.85, (0, 0, 2.05), leaf_a,
            segments=20, ring_count=14, scale=(1.25, 1.05, 1.0),
        ),
        mesh_uv_sphere(
            "canopy_l", 0.55, (-0.55, 0.12, 1.85), leaf_b,
            segments=16, ring_count=12, scale=(1.15, 1.0, 0.95),
        ),
        mesh_uv_sphere(
            "canopy_r", 0.5, (0.58, -0.08, 1.9), leaf_c,
            segments=16, ring_count=12, scale=(1.1, 0.95, 0.9),
        ),
        mesh_uv_sphere(
            "canopy_top", 0.45, (0.05, 0.08, 2.6), leaf_c,
            segments=14, ring_count=12, scale=(1.05, 0.95, 0.85),
        ),
        mesh_uv_sphere(
            "canopy_back", 0.4, (-0.1, -0.25, 2.15), leaf_b,
            segments=12, ring_count=10, scale=(1.0, 0.85, 0.9),
        ),
    ]
    lean = (rng.random() - 0.5) * 0.1
    for obj in [trunk, *canopy]:
        obj.rotation_euler = Euler((0, lean, 0))
        apply_loc_rot_scale(obj)
    return [trunk, *canopy]


def build_street_tile(*, length: float = 10.0) -> list[bpy.types.Object]:
    """Asphalt strip with curbs only — lane dashes are drawn in-game (one line)."""
    asphalt = toon_material("street_asphalt", (0.22, 0.24, 0.26, 1.0), steps=2)
    curb = toon_material("street_curb", (0.78, 0.80, 0.82, 1.0), steps=2)
    shoulder = toon_material("street_shoulder", (0.32, 0.34, 0.36, 1.0), steps=2)
    # Lay out in XY so a Z-down camera sees the road surface.
    return [
        mesh_cube("asphalt", (length, 3.2, 0.08), (0, 0, 0), asphalt),
        mesh_cube("shoulder_n", (length, 0.4, 0.09), (0, 1.4, 0.02), shoulder),
        mesh_cube("shoulder_f", (length, 0.4, 0.09), (0, -1.4, 0.02), shoulder),
        mesh_cube("curb_n", (length, 0.22, 0.18), (0, 1.7, 0.06), curb),
        mesh_cube("curb_f", (length, 0.22, 0.18), (0, -1.7, 0.06), curb),
    ]


def build_cloud_tile():
    white = toon_material("cloud", (0.99, 0.99, 1.0, 1.0), steps=3)
    soft = toon_material("cloud_soft", (0.9, 0.93, 1.0, 1.0), steps=2)
    blobs = [
        ((-3.5, 0, 1.2), 0.95, white),
        ((-2.5, 0, 1.45), 0.75, white),
        ((-1.7, 0, 1.2), 0.85, soft),
        ((0.8, 0, 2.1), 1.15, white),
        ((1.9, 0, 2.35), 0.9, soft),
        ((2.9, 0, 2.0), 0.75, white),
        ((4.6, 0, 1.1), 0.8, soft),
        ((5.5, 0, 1.25), 0.6, white),
        ((-0.4, 0, 1.8), 0.55, soft),
        ((3.6, 0, 2.4), 0.5, white),
    ]
    return [
        mesh_uv_sphere(
            f"cloud_{i}", r, loc, mat, segments=20, scale=(1.75, 0.78, 0.98)
        )
        for i, (loc, r, mat) in enumerate(blobs)
    ]
