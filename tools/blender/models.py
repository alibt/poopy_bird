"""Procedural low-poly subjects for Poopy Bird toon renders."""

from __future__ import annotations

import math
import random

import bpy
from mathutils import Euler

from common import (
    add_inverted_hull,
    join_objects,
    mesh_cube,
    mesh_cylinder,
    mesh_uv_sphere,
    toon_material,
)


def _wheel(name: str, loc: tuple[float, float, float], radius: float = 0.22):
    rubber = toon_material(f"{name}_rubber", (0.08, 0.08, 0.09, 1.0))
    hub = toon_material(f"{name}_hub", (0.72, 0.72, 0.74, 1.0))
    tire = mesh_cylinder(
        name,
        radius=radius,
        depth=0.14,
        location=loc,
        material=rubber,
        vertices=14,
        rotation=(math.radians(90), 0, 0),
    )
    cap = mesh_cylinder(
        f"{name}_hub",
        radius=radius * 0.4,
        depth=0.16,
        location=loc,
        material=hub,
        vertices=10,
        rotation=(math.radians(90), 0, 0),
    )
    return [tire, cap]


def build_car(
    kind: str,
    *,
    body_color: tuple[float, float, float, float],
    length: float = 2.4,
    height: float = 0.85,
    width: float = 1.1,
    cabin_scale: tuple[float, float, float] = (0.9, 0.95, 0.7),
    cabin_z: float = 0.55,
    with_outline: bool = True,
    with_wheels: bool = False,
) -> bpy.types.Object:
    """Car body facing +X. Wheels stay off by default — Flutter rolls tire.png."""
    body_mat = toon_material(f"{kind}_body", body_color)
    glass = toon_material(f"{kind}_glass", (0.45, 0.72, 0.88, 1.0), steps=2)
    dark = toon_material(f"{kind}_trim", (0.12, 0.12, 0.14, 1.0))

    # Sit the body above z=0 so Flutter can tuck tires under the chassis.
    body = mesh_cube(
        f"{kind}_body",
        (length, width * 0.9, height * 0.55),
        (0, 0, height * 0.45),
        body_mat,
    )
    cabin = mesh_cube(
        f"{kind}_cabin",
        (
            length * cabin_scale[0] * 0.45,
            width * cabin_scale[1] * 0.85,
            height * cabin_scale[2],
        ),
        (-length * 0.05, 0, cabin_z + 0.15),
        glass,
    )
    bumper = mesh_cube(
        f"{kind}_bumper",
        (0.18, width * 0.95, 0.22),
        (length * 0.48, 0, 0.35),
        dark,
    )
    parts = [body, cabin, bumper]
    if with_wheels:
        for x in (-length * 0.32, length * 0.28):
            for y in (-width * 0.42, width * 0.42):
                parts.extend(_wheel(f"{kind}_w_{x:.2f}_{y:.2f}", (x, y, 0.22)))

    if kind == "convertible":
        cabin.scale.z *= 0.35
        bpy.context.view_layer.objects.active = cabin
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        parts.append(
            mesh_cube(
                f"{kind}_seat",
                (0.35, 0.7, 0.25),
                (-0.1, 0, 0.45),
                toon_material(f"{kind}_seat", (0.35, 0.1, 0.1, 1.0)),
            )
        )
    elif kind == "washed":
        parts.append(
            mesh_cube(
                f"{kind}_shine",
                (length * 0.7, width * 0.2, 0.05),
                (0.1, width * 0.2, height * 0.55),
                toon_material(f"{kind}_shine", (1.0, 1.0, 1.0, 0.7)),
            )
        )
    elif kind == "bus":
        body.scale = (1.15, 1.05, 1.6)
        bpy.context.view_layer.objects.active = body
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        cabin.location.z = 1.05
        parts.append(
            mesh_cube(
                f"{kind}_stripe",
                (length * 1.05, width * 0.92, 0.12),
                (0, 0, 0.7),
                toon_material(f"{kind}_stripe", (1.0, 0.85, 0.15, 1.0)),
            )
        )
    elif kind == "taxi":
        parts.append(
            mesh_cube(
                f"{kind}_sign",
                (0.35, 0.25, 0.18),
                (0.0, 0, height * 0.95),
                toon_material(f"{kind}_sign", (0.95, 0.85, 0.1, 1.0)),
            )
        )
    elif kind == "limo":
        body.scale.x = 1.55
        bpy.context.view_layer.objects.active = body
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        cabin.scale.x = 1.4
        bpy.context.view_layer.objects.active = cabin
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    elif kind == "police":
        parts.append(
            mesh_cube(
                f"{kind}_lights",
                (0.5, 0.7, 0.14),
                (0.0, 0, height * 1.05),
                toon_material(f"{kind}_lights", (0.15, 0.35, 0.95, 1.0)),
            )
        )
        parts.append(
            mesh_cube(
                f"{kind}_stripe",
                (length * 0.9, width * 0.92, 0.12),
                (0, 0, 0.4),
                toon_material(f"{kind}_stripe", (0.95, 0.95, 0.95, 1.0)),
            )
        )
    elif kind == "sunroof":
        parts.append(
            mesh_cube(
                f"{kind}_hatch",
                (0.55, 0.55, 0.08),
                (-0.05, 0, height * 1.0),
                toon_material(f"{kind}_hatch", (0.2, 0.2, 0.22, 1.0)),
            )
        )
    elif kind == "sports":
        cabin.location = (-0.15, 0, 0.48)
        cabin.scale = (0.85, 0.9, 0.55)
        bpy.context.view_layer.objects.active = cabin
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        parts.append(
            mesh_cube(
                f"{kind}_spoiler",
                (0.12, 0.95, 0.08),
                (-length * 0.42, 0, 0.55),
                body_mat,
            )
        )

    root = join_objects(parts, f"car_{kind}")
    if with_outline:
        add_inverted_hull(root, thickness=0.05)
    return root


def build_car_wash_truck(*, with_outline: bool = True) -> bpy.types.Object:
    blue = toon_material("cwt_cab", (0.12, 0.42, 0.85, 1.0))
    tank = toon_material("cwt_tank", (0.55, 0.78, 0.95, 1.0))
    yellow = toon_material("cwt_brush", (0.95, 0.85, 0.15, 1.0))
    white = toon_material("cwt_stripe", (0.95, 0.95, 0.97, 1.0))
    glass = toon_material("cwt_glass", (0.55, 0.8, 0.95, 1.0), steps=2)

    parts = [
        mesh_cube("cwt_cab", (1.1, 1.2, 1.1), (1.4, 0, 0.75), blue),
        mesh_cube("cwt_window", (0.15, 0.9, 0.45), (1.95, 0, 0.95), glass),
        mesh_cube("cwt_tank", (2.6, 1.25, 1.3), (-0.5, 0, 0.9), tank),
        mesh_cube("cwt_stripe", (2.55, 1.28, 0.18), (-0.5, 0, 0.7), white),
        mesh_uv_sphere("cwt_brush_l", 0.32, (-0.2, 0, 1.75), yellow, scale=(1.0, 1.0, 0.7)),
        mesh_uv_sphere("cwt_brush_r", 0.32, (-1.3, 0, 1.75), yellow, scale=(1.0, 1.0, 0.7)),
    ]
    for x in (-1.4, -0.1, 1.3):
        for y in (-0.55, 0.55):
            parts.extend(_wheel(f"cwt_w_{x}_{y}", (x, y, 0.28), radius=0.28))

    root = join_objects(parts, "boss_car_wash")
    if with_outline:
        add_inverted_hull(root, thickness=0.055)
    return root


def build_mayor_limo(*, with_outline: bool = True) -> bpy.types.Object:
    black = toon_material("mayor_body", (0.08, 0.08, 0.1, 1.0))
    gold = toon_material("mayor_trim", (0.85, 0.7, 0.2, 1.0))
    glass = toon_material("mayor_glass", (0.25, 0.3, 0.38, 1.0), steps=2)
    parts = [
        mesh_cube("mayor_body", (4.2, 1.25, 0.85), (0, 0, 0.55), black),
        mesh_cube("mayor_cabin", (2.6, 1.1, 0.7), (0.2, 0, 1.15), glass),
        mesh_cube("mayor_crest", (0.35, 0.35, 0.12), (1.6, 0, 1.45), gold),
    ]
    for x in (-1.5, -0.4, 0.7, 1.6):
        for y in (-0.55, 0.55):
            parts.extend(_wheel(f"mayor_w_{x}", (x, y, 0.28), radius=0.26))
    root = join_objects(parts, "boss_mayor_limo")
    if with_outline:
        add_inverted_hull(root, thickness=0.055)
    return root


def build_monster_truck(*, with_outline: bool = True) -> bpy.types.Object:
    red = toon_material("mt_body", (0.85, 0.15, 0.12, 1.0))
    dark = toon_material("mt_frame", (0.15, 0.15, 0.16, 1.0))
    glass = toon_material("mt_glass", (0.45, 0.72, 0.88, 1.0), steps=2)
    parts = [
        mesh_cube("mt_body", (2.6, 1.6, 1.0), (0, 0, 1.35), red),
        mesh_cube("mt_cabin", (1.1, 1.3, 0.8), (0.4, 0, 2.1), glass),
        mesh_cube("mt_frame", (2.2, 1.3, 0.35), (0, 0, 0.85), dark),
    ]
    for x in (-0.85, 0.85):
        for y in (-0.75, 0.75):
            parts.extend(_wheel(f"mt_w_{x}_{y}", (x, y, 0.55), radius=0.55))
    root = join_objects(parts, "boss_monster_truck")
    if with_outline:
        add_inverted_hull(root, thickness=0.06)
    return root


def build_bird(wing_angle: float = 0.0, *, with_outline: bool = True) -> bpy.types.Object:
    """Side-view bird facing +X. One wing in the silhouette (camera on +Y)."""
    yellow = toon_material("bird_body", (1.0, 0.86, 0.2, 1.0), steps=2)
    orange = toon_material("bird_beak", (1.0, 0.5, 0.12, 1.0), steps=2)
    white = toon_material("bird_eye", (1.0, 1.0, 1.0, 1.0), steps=2)
    black = toon_material("bird_pupil", (0.05, 0.05, 0.06, 1.0), steps=2)
    wing_mat = toon_material("bird_wing", (0.98, 0.7, 0.1, 1.0), steps=2)
    belly_mat = toon_material("bird_belly", (1.0, 0.94, 0.6, 1.0), steps=2)

    body = mesh_uv_sphere(
        "bird_body", 0.55, (0, 0, 0.05), yellow, scale=(1.2, 0.7, 1.0)
    )
    head = mesh_uv_sphere("bird_head", 0.36, (0.58, 0, 0.42), yellow, scale=(1.0, 0.75, 1.0))
    beak = mesh_cube("bird_beak", (0.32, 0.16, 0.16), (0.95, 0, 0.38), orange)
    # Near-side eye only (readable in side view).
    eye = mesh_uv_sphere("bird_eye", 0.11, (0.78, 0.28, 0.52), white)
    pupil = mesh_uv_sphere("bird_pupil", 0.055, (0.86, 0.32, 0.52), black)
    belly = mesh_uv_sphere(
        "bird_belly", 0.38, (0.08, 0, -0.08), belly_mat, scale=(1.05, 0.65, 0.75)
    )
    # Wing as an oval in the XZ silhouette; flap = rotate around Y.
    wing = mesh_uv_sphere(
        "bird_wing", 0.42, (-0.05, 0.15, 0.2), wing_mat, scale=(0.85, 0.2, 1.15)
    )
    wing.rotation_euler = Euler((0, math.radians(wing_angle), math.radians(-8)))
    bpy.ops.object.select_all(action="DESELECT")
    wing.select_set(True)
    bpy.context.view_layer.objects.active = wing
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

    root = join_objects([body, head, beak, eye, pupil, belly, wing], "bird")
    if with_outline:
        add_inverted_hull(root, thickness=0.028)
    return root


def build_food(kind: str, *, with_outline: bool = True) -> bpy.types.Object:
    if kind == "berries":
        berry = toon_material("berry", (0.45, 0.1, 0.55, 1.0))
        leaf = toon_material("berry_leaf", (0.2, 0.55, 0.2, 1.0))
        parts = [
            mesh_uv_sphere("b1", 0.28, (-0.22, 0.05, 0.0), berry),
            mesh_uv_sphere("b2", 0.28, (0.22, 0.05, 0.0), berry),
            mesh_uv_sphere("b3", 0.28, (0.0, -0.05, 0.25), berry),
            mesh_cube("leaf", (0.35, 0.12, 0.08), (0.15, 0.0, 0.55), leaf),
        ]
    elif kind == "chili":
        red = toon_material("chili", (0.85, 0.12, 0.1, 1.0))
        green = toon_material("chili_stem", (0.2, 0.5, 0.15, 1.0))
        parts = [
            mesh_uv_sphere(
                "chili_body", 0.45, (0, 0, 0), red, scale=(0.55, 0.55, 1.2)
            ),
            mesh_uv_sphere("chili_tip", 0.18, (0.05, 0, -0.55), red),
            mesh_cylinder("chili_stem", 0.07, 0.25, (0, 0, 0.6), green),
        ]
    else:
        tortilla = toon_material("burrito", (0.9, 0.75, 0.4, 1.0))
        filling = toon_material("burrito_fill", (0.45, 0.28, 0.15, 1.0))
        parts = [
            mesh_cylinder(
                "burrito_body",
                0.35,
                1.1,
                (0, 0, 0),
                tortilla,
                rotation=(0, math.radians(90), 0),
            ),
            mesh_uv_sphere("burrito_end", 0.32, (0.55, 0, 0), filling),
        ]

    root = join_objects(parts, f"food_{kind}")
    if with_outline:
        add_inverted_hull(root, thickness=0.035)
    return root


def build_coin(*, with_outline: bool = True) -> bpy.types.Object:
    gold = toon_material("coin_gold", (0.95, 0.75, 0.15, 1.0))
    rim = toon_material("coin_rim", (0.8, 0.55, 0.1, 1.0))
    disc = mesh_cylinder("coin", 0.55, 0.12, (0, 0, 0), gold, vertices=24)
    edge = mesh_cylinder("coin_edge", 0.58, 0.08, (0, 0, 0), rim, vertices=24)
    root = join_objects([disc, edge], "coin")
    root.rotation_euler = Euler((math.radians(90), 0, 0))
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    if with_outline:
        add_inverted_hull(root, thickness=0.03)
    return root


def build_trophy(tier: str, *, with_outline: bool = True) -> bpy.types.Object:
    colors = {
        "bronze": (0.72, 0.42, 0.18, 1.0),
        "silver": (0.78, 0.8, 0.85, 1.0),
        "gold": (0.95, 0.78, 0.18, 1.0),
    }
    metal = toon_material(f"trophy_{tier}", colors[tier])
    dark = toon_material(f"trophy_{tier}_base", (0.2, 0.15, 0.1, 1.0))
    parts = [
        mesh_cylinder(f"{tier}_cup", 0.4, 0.55, (0, 0, 0.85), metal),
        mesh_cylinder(f"{tier}_stem", 0.12, 0.45, (0, 0, 0.4), metal),
        mesh_cube(f"{tier}_base", (0.7, 0.5, 0.18), (0, 0, 0.08), dark),
        mesh_cylinder(
            f"{tier}_hl",
            0.06,
            0.35,
            (-0.42, 0, 0.9),
            metal,
            rotation=(0, 0, math.radians(90)),
        ),
        mesh_cylinder(
            f"{tier}_hr",
            0.06,
            0.35,
            (0.42, 0, 0.9),
            metal,
            rotation=(0, 0, math.radians(90)),
        ),
    ]
    root = join_objects(parts, f"trophy_{tier}")
    if with_outline:
        add_inverted_hull(root, thickness=0.035)
    return root


def build_medal(*, with_outline: bool = True) -> bpy.types.Object:
    gold = toon_material("medal", (0.9, 0.7, 0.15, 1.0))
    ribbon = toon_material("medal_ribbon", (0.75, 0.15, 0.2, 1.0))
    disc = mesh_cylinder("medal_disc", 0.4, 0.08, (0, 0, 0), gold, vertices=20)
    disc.rotation_euler = Euler((math.radians(90), 0, 0))
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    rib = mesh_cube("medal_ribbon", (0.35, 0.08, 0.55), (0, 0, 0.45), ribbon)
    root = join_objects([disc, rib], "medal")
    if with_outline:
        add_inverted_hull(root, thickness=0.03)
    return root


def build_tire(*, with_outline: bool = True) -> bpy.types.Object:
    rubber = toon_material("tire", (0.08, 0.08, 0.09, 1.0))
    hub = toon_material("tire_hub", (0.7, 0.7, 0.72, 1.0))
    tire = mesh_cylinder("tire", 0.5, 0.22, (0, 0, 0), rubber, vertices=16)
    cap = mesh_cylinder("hub", 0.2, 0.24, (0, 0, 0), hub, vertices=10)
    root = join_objects([tire, cap], "tire")
    root.rotation_euler = Euler((0, math.radians(90), 0))
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    if with_outline:
        add_inverted_hull(root, thickness=0.03)
    return root


def build_skyline_tile(*, seed: int, near: bool, length: float = 12.0):
    rng = random.Random(seed)
    if near:
        body_c = (0.42, 0.52, 0.62, 1.0)
        win_c = (0.95, 0.9, 0.55, 1.0)
        h_range = (1.2, 2.8)
    else:
        body_c = (0.62, 0.72, 0.82, 1.0)
        win_c = (0.78, 0.86, 0.92, 1.0)
        h_range = (1.8, 4.0)

    body_mat = toon_material(f"sky_{seed}_body", body_c)
    win_mat = toon_material(f"sky_{seed}_win", win_c)
    objs = []
    x = -length * 0.5
    while x < length * 0.5:
        w = 0.7 + rng.random() * 1.1
        h = h_range[0] + rng.random() * (h_range[1] - h_range[0])
        objs.append(
            mesh_cube(
                f"b_{seed}_{len(objs)}",
                (w, 0.6, h),
                (x + w * 0.5, 0, h * 0.5),
                body_mat,
            )
        )
        wy = 0.4
        while wy < h - 0.3:
            wx = x + 0.15
            while wx < x + w - 0.25:
                objs.append(
                    mesh_cube(
                        f"w_{seed}_{len(objs)}",
                        (0.18, 0.05, 0.22),
                        (wx, 0.32, wy),
                        win_mat,
                    )
                )
                wx += 0.35
            wy += 0.45
        x += w + 0.15 + rng.random() * 0.35
    return objs


def build_cloud_tile():
    white = toon_material("cloud", (0.98, 0.98, 1.0, 0.95))
    blobs = [
        ((-3.5, 0, 1.2), 0.9),
        ((-2.6, 0, 1.4), 0.7),
        ((-1.8, 0, 1.15), 0.8),
        ((1.0, 0, 2.0), 1.1),
        ((2.0, 0, 2.2), 0.85),
        ((2.9, 0, 1.9), 0.7),
        ((4.5, 0, 1.0), 0.75),
        ((5.3, 0, 1.15), 0.55),
    ]
    return [
        mesh_uv_sphere(f"cloud_{i}", r, loc, white, scale=(1.6, 0.7, 0.9))
        for i, (loc, r) in enumerate(blobs)
    ]
