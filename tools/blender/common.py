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

    # Flat, stable lighting for toon stills.
    world = bpy.data.worlds.new("ToonWorld")
    scene.world = world
    world.use_nodes = True
    nodes = world.node_tree.nodes
    links = world.node_tree.links
    nodes.clear()
    bg = nodes.new("ShaderNodeBackground")
    bg.inputs["Color"].default_value = (0.55, 0.72, 0.88, 1.0)
    bg.inputs["Strength"].default_value = 0.35
    out = nodes.new("ShaderNodeOutputWorld")
    links.new(bg.outputs["Background"], out.inputs["Surface"])

    sun = bpy.data.objects.new("KeyLight", bpy.data.lights.new("KeyLight", "SUN"))
    sun.data.energy = 2.4
    sun.rotation_euler = Euler((math.radians(45), math.radians(15), math.radians(35)))
    scene.collection.objects.link(sun)

    fill = bpy.data.objects.new(
        "FillLight", bpy.data.lights.new("FillLight", "SUN")
    )
    fill.data.energy = 0.7
    fill.rotation_euler = Euler((math.radians(20), math.radians(-40), math.radians(-20)))
    scene.collection.objects.link(fill)
    return scene


def toon_material(
    name: str,
    color: tuple[float, float, float, float],
    *,
    steps: int = 3,
    roughness: float = 0.85,
) -> bpy.types.Material:
    """Cel-shaded material via ShaderToRGB + ColorRamp."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    output = nodes.new("ShaderNodeOutputMaterial")
    output.location = (500, 0)
    mix = nodes.new("ShaderNodeMixShader")
    mix.location = (300, 0)
    transparent = nodes.new("ShaderNodeBsdfTransparent")
    transparent.location = (100, -120)

    diffuse = nodes.new("ShaderNodeBsdfDiffuse")
    diffuse.location = (-400, 80)
    diffuse.inputs["Color"].default_value = color
    diffuse.inputs["Roughness"].default_value = roughness

    to_rgb = nodes.new("ShaderNodeShaderToRGB")
    to_rgb.location = (-180, 80)

    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.location = (0, 80)
    ramp.color_ramp.interpolation = "CONSTANT"
    elements = ramp.color_ramp.elements
    while len(elements) > 1:
        elements.remove(elements[-1])
    elements[0].position = 0.0
    dark = tuple(max(0.0, c * 0.55) for c in color[:3]) + (1.0,)
    elements[0].color = dark
    if steps >= 2:
        mid = elements.new(0.45)
        mid.color = tuple(max(0.0, c * 0.82) for c in color[:3]) + (1.0,)
    bright = elements.new(0.72 if steps >= 3 else 0.55)
    bright.color = color

    emission = nodes.new("ShaderNodeEmission")
    emission.location = (100, 80)
    emission.inputs["Strength"].default_value = 1.0

    # Keep alpha from the base colour for windows etc.
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
    segments: int = 16,
    ring_count: int = 10,
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


def join_objects(objects: list[bpy.types.Object], name: str) -> bpy.types.Object:
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    result = bpy.context.active_object
    result.name = name
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
