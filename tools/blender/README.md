# Blender toon-render pipeline

Headless Blender 5.3 scripts that build low-poly subjects, apply cel shading
(ShaderToRGB + ColorRamp), add inverted-hull outlines, and write transparent
PNGs into `assets/images/`.

## Requirements

- Blender 5.3+ (`/opt/homebrew/bin/blender` on this machine)
- Run from the repo root

## Export everything

```bash
/opt/homebrew/bin/blender -b -P tools/blender/export_all.py
```

## Export a subset

```bash
/opt/homebrew/bin/blender -b -P tools/blender/export_all.py -- --only bird,cars
# groups: bird | cars | food | ui | bg
```

## Output layout

| File | Used for |
|---|---|
| `bird_01.png` … `bird_08.png` | Flap animation (also mirrored to legacy `frame-N.png`) |
| `car_sedan.png`, `car_sports.png`, … | Car variants |
| `boss_car_wash.png`, `boss_mayor_limo.png`, `boss_monster_truck.png` | Bosses |
| `food_berries.png`, `food_chili.png`, `food_burrito.png` | Pickups |
| `coin.png`, `trophy_*.png`, `medal.png` | UI |
| `bg_clouds.png`, `bg_skyline_*.png` | Parallax strips |
| `tire.png`, `car-body.png` | Wheels + sedan alias |

## Modules

- `common.py` — scene reset, toon materials, ortho camera, PNG render
- `models.py` — procedural meshes
- `export_all.py` — batch entry point
