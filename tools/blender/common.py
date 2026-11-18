"""Shared helpers for Poopy Bird's headless Blender toon-render pipeline.

Run scripts with:
  /opt/homebrew/bin/blender -b -P tools/blender/export_all.py
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

import bpy
from mathutils import Euler, Vector

TOOLS_DIR = Path(__file__).resolve().parent
REPO_ROOT = TOOLS_DIR.parent.parent
IMAGES_DIR = REPO_ROOT / "assets" / "images"


def ensure_images_dir() -> Path:
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)
    return IMAGES_DIR


def reset_scene() -> bpy.types.Scene:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.render.resolution_percentage = 100
    scene.render.use_freestyle = False

    # Soft studio lighting — readable cel bands with a warm key + cool fill.
    world = bpy.data.worlds.new("ToonWorld")
    scene.world = world
    world.use_nodes = True
    nodes = world.node_tree.nodes
    links = world.node_tree.links
    nodes.clear()
    bg = nodes.new("ShaderNodeBackground")
    bg.inputs["Color"].default_value = (0.62, 0.78, 0.95, 1.0)
    bg.inputs["Strength"].default_value = 0.45
    out = nodes.new("ShaderNodeOutputWorld")
    links.new(bg.outputs["Background"], out.inputs["Surface"])

    sun = bpy.data.objects.new("KeyLight", bpy.data.lights.new("KeyLight", "SUN"))
    sun.data.energy = 5.2
    sun.data.angle = math.radians(8)
    sun.rotation_euler = Euler((math.radians(48), math.radians(18), math.radians(35)))
    scene.collection.objects.link(sun)

    fill = bpy.data.objects.new(
        "FillLight", bpy.data.lights.new("FillLight", "SUN")
    )
    fill.data.energy = 1.8
    fill.rotation_euler = Euler((math.radians(30), math.radians(-55), math.radians(-20)))
    scene.collection.objects.link(fill)

    rim = bpy.data.objects.new("RimLight", bpy.data.lights.new("RimLight", "SUN"))
    rim.data.energy = 2.4
    rim.rotation_euler = Euler((math.radians(-25), math.radians(155), 0))
    scene.collection.objects.link(rim)

    bounce = bpy.data.objects.new(
        "BounceLight", bpy.data.lights.new("BounceLight", "SUN")
    )
    bounce.data.energy = 0.7
    bounce.rotation_euler = Euler((math.radians(100), math.radians(10), 0))
    scene.collection.objects.link(bounce)
    return scene


def toon_material(
    name: str,
    color: tuple[float, float, float, float],
    *,
    steps: int = 4,
    roughness: float = 0.7,
    soft: bool = True,
) -> bpy.types.Material:
    """Cel-shaded material via ShaderToRGB + ColorRamp (soft bands + highlight)."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    output = nodes.new("ShaderNodeOutputMaterial")
    output.location = (700, 0)
    mix = nodes.new("ShaderNodeMixShader")
    mix.location = (500, 0)
    transparent = nodes.new("ShaderNodeBsdfTransparent")
    transparent.location = (300, -140)

    diffuse = nodes.new("ShaderNodeBsdfDiffuse")
    diffuse.location = (-500, 80)
    diffuse.inputs["Color"].default_value = color
    diffuse.inputs["Roughness"].default_value = roughness

    to_rgb = nodes.new("ShaderNodeShaderToRGB")
    to_rgb.location = (-280, 80)

    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.location = (-60, 80)
    ramp.color_ramp.interpolation = "LINEAR" if soft else "CONSTANT"
    elements = ramp.color_ramp.elements
    while len(elements) > 1:
        elements.remove(elements[-1])
    elements[0].position = 0.0
    shadow = tuple(max(0.0, c * 0.42) for c in color[:3]) + (1.0,)
    elements[0].color = shadow
    if steps >= 2:
        mid = elements.new(0.38)
        mid.color = tuple(max(0.0, c * 0.72) for c in color[:3]) + (1.0,)
    if steps >= 3:
        base = elements.new(0.62)
        base.color = color
    if steps >= 4:
        hi = elements.new(0.88)
        hi.color = tuple(min(1.0, c * 1.18 + 0.08) for c in color[:3]) + (1.0,)
    else:
        bright = elements.new(0.78 if steps >= 3 else 0.55)
        bright.color = tuple(min(1.0, c * 1.08) for c in color[:3]) + (1.0,)

    emission = nodes.new("ShaderNodeEmission")
    emission.location = (220, 80)
    emission.inputs["Strength"].default_value = 1.05

    links.new(diffuse.outputs["BSDF"], to_rgb.inputs["Shader"])
    links.new(to_rgb.outputs["Color"], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], emission.inputs["Color"])
    links.new(emission.outputs["Emission"], mix.inputs[1])
    links.new(transparent.outputs["BSDF"], mix.inputs[2])
    mix.inputs["Fac"].default_value = 1.0 - color[3]
    links.new(mix.outputs["Shader"], output.inputs["Surface"])

    if color[3] < 0.999:
        mat.blend_method = "BLEND"
    return mat


def outline_material(name: str = "Outline") -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    # Flipped outline faces point inward; cull fronts so only the rim shows.
    mat.use_backface_culling = False
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()
    emission = nodes.new("ShaderNodeEmission")
    emission.inputs["Color"].default_value = (0.02, 0.02, 0.03, 1.0)
    emission.inputs["Strength"].default_value = 1.0
    output = nodes.new("ShaderNodeOutputMaterial")
    links.new(emission.outputs["Emission"], output.inputs["Surface"])
    return mat


def assign_material(obj: bpy.types.Object, mat: bpy.types.Material) -> None:
    if obj.data.materials:
        obj.data.materials[0] = mat
    else:
        obj.data.materials.append(mat)


def add_inverted_hull(
    obj: bpy.types.Object,
    thickness: float = 0.03,
    mat: bpy.types.Material | None = None,
) -> bpy.types.Object:
    """No-op placeholder. Outlines are applied in PNG post (see ``png_outline``)."""
    return obj


def png_outline(
    path: Path,
    *,
    width: int = 5,
    color: tuple[int, int, int] = (20, 20, 28),
) -> None:
    """Dilate alpha into a dark rim via system Python (Blender's Python lacks PIL)."""
    import subprocess

    path = Path(path)
    script = TOOLS_DIR / "outline_png.py"
    subprocess.run(
        [
            "python3",
            str(script),
            str(path),
            "--width",
            str(width),
            "--color",
            f"{color[0]},{color[1]},{color[2]}",
        ],
        check=True,
    )


def mesh_cube(
    name: str,
    size: tuple[float, float, float],
    location: tuple[float, float, float],
    material: bpy.types.Material,
    *,
    scale: tuple[float, float, float] | None = None,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale or size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    assign_material(obj, material)
    return obj


def mesh_cylinder(
    name: str,
    radius: float,
    depth: float,
    location: tuple[float, float, float],
    material: bpy.types.Material,
    *,
    vertices: int = 16,
    rotation: tuple[float, float, float] = (0, 0, 0),
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices, radius=radius, depth=depth, location=location
    )
    obj = bpy.context.active_object
    obj.name = name
    obj.rotation_euler = Euler(rotation)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    assign_material(obj, material)
    return obj


def mesh_uv_sphere(
    name: str,
    radius: float,
    location: tuple[float, float, float],
    material: bpy.types.Material,
    *,
    segments: int = 24,
    ring_count: int = 16,
    scale: tuple[float, float, float] | None = None,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=segments, ring_count=ring_count, radius=radius, location=location
    )
    obj = bpy.context.active_object
    obj.name = name
    if scale:
        obj.scale = scale
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    assign_material(obj, material)
    return obj


def mesh_cone(
    name: str,
    radius1: float,
    depth: float,
    location: tuple[float, float, float],
    material: bpy.types.Material,
    *,
    radius2: float = 0.0,
    vertices: int = 16,
    rotation: tuple[float, float, float] = (0, 0, 0),
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cone_add(
        vertices=vertices,
        radius1=radius1,
        radius2=radius2,
        depth=depth,
        location=location,
    )
    obj = bpy.context.active_object
    obj.name = name
    obj.rotation_euler = Euler(rotation)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    assign_material(obj, material)
    return obj


def extrude_profile(
    name: str,
    points_xz: list[tuple[float, float]],
    *,
    width: float = 1.0,
    material: bpy.types.Material,
) -> bpy.types.Object:
    """Build a solid by extruding an XZ silhouette along Y (true side-view shapes)."""
    import bmesh

    mesh = bpy.data.meshes.new(name)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)

    bm = bmesh.new()
    half = width * 0.5
    # Front and back rings.
    front = [bm.verts.new((x, half, z)) for x, z in points_xz]
    back = [bm.verts.new((x, -half, z)) for x, z in points_xz]
    bm.verts.ensure_lookup_table()
    n = len(points_xz)
    bm.faces.new(front)
    bm.faces.new(list(reversed(back)))
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new([front[i], front[j], back[j], back[i]])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    assign_material(obj, material)
    return obj


def bevel(
    obj: bpy.types.Object,
    *,
    width: float = 0.06,
    segments: int = 3,
) -> bpy.types.Object:
    """Round hard edges so silhouettes read as toy-like, not Minecraft."""
    mod = obj.modifiers.new("Bevel", "BEVEL")
    mod.width = width
    mod.segments = segments
    mod.limit_method = "ANGLE"
    mod.angle_limit = math.radians(30)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def apply_loc_rot_scale(obj: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)


def join_objects(
    objects: list[bpy.types.Object],
    name: str,
    *,
    smooth: bool = False,
) -> bpy.types.Object:
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    result = bpy.context.active_object
    result.name = name
    if smooth:
        bpy.ops.object.shade_smooth()
    return result


def framing_bounds(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
    coords: list[Vector] = []
    for obj in objects:
        for corner in obj.bound_box:
            coords.append(obj.matrix_world @ Vector(corner))
    xs = [c.x for c in coords]
    ys = [c.y for c in coords]
    zs = [c.z for c in coords]
    return Vector((min(xs), min(ys), min(zs))), Vector((max(xs), max(ys), max(zs)))


def setup_ortho_camera(
    objects: list[bpy.types.Object],
    *,
    axis: str = "Y",
    padding: float = 1.18,
    resolution: tuple[int, int] = (512, 512),
) -> bpy.types.Object:
    """Orthographic camera looking at the subject from +Y (side) or +X/+Z."""
    scene = bpy.context.scene
    scene.render.resolution_x = resolution[0]
    scene.render.resolution_y = resolution[1]

    mn, mx = framing_bounds(objects)
    center = (mn + mx) * 0.5
    size = mx - mn
    extent = max(size.x, size.y, size.z, 0.001)

    cam_data = bpy.data.cameras.new("ToonCam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = extent * padding
    cam = bpy.data.objects.new("ToonCam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam

    if axis.upper() == "Y":
        # Side view: traffic faces +X, camera on +Y looking toward origin.
        cam.location = (center.x, center.y + extent * 3, center.z)
        cam.rotation_euler = Euler((math.radians(90), 0, math.radians(180)))
    elif axis.upper() == "CAR":
        # Near-side view with a hint of 3/4 so panels read as volume.
        dist = extent * 3.05
        cam.location = (
            center.x + dist * 0.06,
            center.y + dist,
            center.z + dist * 0.05,
        )
        direction = center - cam.location
        cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    elif axis.upper() == "CHAR":
        # Slight 3/4 for characters — more dimension, still sprite-readable.
        dist = extent * 3.35
        cam.location = (
            center.x + dist * 0.22,
            center.y + dist,
            center.z + dist * 0.14,
        )
        direction = center - cam.location
        rot = direction.to_track_quat("-Z", "Y").to_euler()
        cam.rotation_euler = rot
    elif axis.upper() == "Z":
        cam.location = (center.x, center.y, center.z + extent * 3)
        cam.rotation_euler = Euler((0, 0, 0))
    else:  # X — front-ish
        cam.location = (center.x + extent * 3, center.y, center.z)
        cam.rotation_euler = Euler((math.radians(90), 0, math.radians(90)))
    return cam


def render_png(path: Path) -> Path:
    ensure_images_dir()
    path = Path(path)
    if not path.is_absolute():
        path = IMAGES_DIR / path
    path.parent.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    print(f"[poopy-bird] wrote {path}")
    return path


def link_collection(objs: list[bpy.types.Object]) -> None:
    for obj in objs:
        if obj.name not in bpy.context.scene.collection.objects:
            bpy.context.scene.collection.objects.link(obj)


def set_parent(children: list[bpy.types.Object], parent: bpy.types.Object) -> None:
    for child in children:
        child.parent = parent
