# Blender toon-render pipeline

Headless Blender 5.3 scripts that build low-poly subjects, apply soft cel shading
(ShaderToRGB + multi-step ColorRamp), post-process PNG outlines, and write
transparent sprites into `assets/images/`.

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
| `bird_01.png` … `bird_08.png` | Flap cycle (wing + squash/bob/blink); also `frame-N.png` |
| `car_sedan.png`, `car_sports.png`, … | Car variants (extruded side profiles) |
| `boss_car_wash.png`, `boss_mayor_limo.png`, `boss_monster_truck.png` | Bosses |
| `food_<kind>_01.png` … `_06.png` | Pickup tumble animation (+ still alias `food_<kind>.png`) |
| `coin_01.png` … `coin_06.png` | Coin flip frames (+ still `coin.png`) |
| `trophy_*.png`, `medal.png` | UI |
| `bg_clouds.png`, `bg_skyline_*.png` | Parallax strips |
| `tire.png`, `car-body.png` | Wheels + sedan alias |

## Modules

- `common.py` — scene reset, toon materials, ortho camera, PNG render
- `models.py` — procedural meshes
- `export_all.py` — batch entry point
