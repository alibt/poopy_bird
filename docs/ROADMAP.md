# Poopy Bird — Roadmap

Poopy Bird is a 2D arcade game built with Flutter + Flame. **You are a bird. You poop on cars.**
Everything in the game exists to serve that fantasy: every target is a car, food changes your
poop, hazards make aiming harder, and letting cars drive away clean makes the city angry.

Tick boxes (`- [x]`) as work lands so this file stays the source of truth for progress.

---

## Decisions

| Topic | Decision |
|---|---|
| Primary mode | Level-based campaign first; Endless mode unlocks later |
| Monetization | Both ads and in-app purchases (economy must be tuned for this) |
| Art | Redo all art in one consistent style using a Blender toon-render pipeline |
| Platforms | Android + iOS (landscape). Web/desktop used for development |
| Menus vs gameplay | Flutter widgets for menus/shop/trophy room; Flame for gameplay + HUD |

---

## Game design

### Core loop
Fly → eat food to fill your **Belly (ammo)** → poop on cars → build a **combo** →
keep the **Rage meter** low → complete level objectives → **results** (stars + coins) →
**upgrades** → next level.

### Losing
- Crashing into a car.
- Rage meter fills up: every car that escapes clean adds rage, every splat drains it.

### Cars (the targets)

| Car | Behaviour | Reward |
|---|---|---|
| Sedan | Baseline | Base points |
| Convertible | Top down | ×2 |
| Freshly washed car | Sparkling | ×3 |
| Sports car | Very fast, hard to hit | High |
| Bus / truck | Big, slow, needs several hits | Big bonus |
| Taxi | Changes lanes | Medium |
| Wedding limo | Rare, long | Jackpot |
| Police car | Hitting it raises Rage | Penalty |
| Sunroof / umbrella car | Opens and closes; timing challenge | Bonus |

### Bosses (also cars)
- **Car-wash truck**: cleans cars you've already splatted.
- **Mayor's armored limo**: only its weak spots can be hit.
- **Monster truck**: final boss.

### Food (power-ups)

| Food | Effect |
|---|---|
| Berries | Refill ammo |
| Chili | Rapid fire |
| Burrito | Big area splat |
| Coffee | Speed boost |
| Golden seed | Coin magnet |

### Hazards
Power lines, crows, drones, sprinklers, rain (reduced visibility / slippery flight).

### Worlds
5 worlds × 8 levels + 1 boss each (about 45 levels):

1. **Suburbs**: tutorial pace, 2 lanes.
2. **Downtown**: taxis and buses, power lines.
3. **Highway**: fast cars, 3 lanes.
4. **Beach Boardwalk**: convertibles, sprinklers.
5. **Night City**: limited visibility, police.

Levels are data-driven JSON (`assets/levels/w1_l3.json`): a timeline of spawn waves,
objectives (e.g. "splat 15 cars", "hit 3 convertibles", "5× combo", "don't hit a police car"),
and star thresholds. Difficulty rises with traffic speed, lane count, hazard density and rage sensitivity.

### Progression and upgrades (bought with coins)

| Upgrade | Levels | Effect |
|---|---|---|
| Belly Size | 5 | Max ammo |
| Digestion | 5 | Poop cooldown |
| Wing Power | 5 | Flap strength / control |
| Aim Assist | 3 | Shows where poop will land |
| Feather Shield | 3 | Survive one crash per run |
| Calm Mind | 3 | Slower rage build-up |

Cosmetics: bird skins and hats, bought with coins or unlocked by achievements.

### Achievements and trophies
- **Achievements** (about 30 one-time tasks): First Splat, Combo King (10×), Car Wash Nemesis,
  Limo Hunter, Pacifist (finish a level with 3 poops), Zen Bird (never above 20% rage),
  Bullseye (hit a convertible from the top of the screen), 100 / 1,000 / 10,000 cars splatted,
  one per boss, Endless distance tiers.
- **Trophy Room**: a bronze/silver/gold cup per world based on stars, plus special trophies
  for 100% completion, all bosses, and Endless milestones.
- **Daily challenge** (later): a seeded level with a bonus reward.

### Screens
Splash → Main Menu → World Map → Level Select → Level Intro (objectives) → Gameplay (HUD, Pause)
→ Results → Shop/Upgrades, Achievements, Trophy Room, Endless, Settings
(music, SFX, haptics, left-handed controls), Tutorial.

---

## Technical architecture

```
lib/
  main.dart            app entry (MaterialApp + GameWidget)
  game/                FlameGame, config/constants
  components/          bird, poop, cars, scenery, HUD, hazards, food
  systems/             pure-Dart logic: score, rage, combo, economy, achievements, save data
  levels/              level JSON parsing + spawn timeline runner
  ui/                  Flutter overlays and menu screens
assets/
  images/  levels/  audio/
tools/blender/         asset generation scripts
```

- World uses a top-left-anchored camera, so world coordinates are screen pixels. HUD lives on the camera viewport.
- Game rules live in pure-Dart `systems/` classes so they can be unit-tested without Flame.
- Persistence: retry `shared_preferences` (the network now has a Flutter mirror); fall back to a JSON save file.
- Audio: `flame_audio`, with CC0 sound packs (e.g. Kenney).
- Tests: unit tests for systems and level parsing; `flame_test` for collisions and game flow.

### Asset pipeline (Blender)
Blender runs headless (`blender -b -P tools/blender/<script>.py`). Scripts build low-poly models,
render them orthographically with a toon shader and inverted-hull outlines onto transparent PNGs,
then pack the frames into sprite sheets. This covers the new bird, all car variants, bosses, food,
coins, trophies and medals, and parallax city backgrounds.

Check the licence of the current placeholder art before any release; it will all be replaced.

---

## Milestones

### M0 — Stabilise and restructure
- [x] Fix distance score never increasing (per-frame rounding to 0)
- [x] Splatted cars score once only and stay visibly splatted
- [x] Cars are removed off-screen instead of recycled (no invisible cars, no unbounded growth)
- [x] Cars in a lane never overlap; car art faces the direction of travel
- [x] Consistent road/lane/tree layout derived from screen size
- [x] Restructure into `game/`, `components/`, `systems/`, `ui/`; central `GameConfig`
- [x] Camera/world/viewport setup; HUD on the viewport
- [x] Keyboard controls for desktop/web testing
- [x] Unit tests (score, rage) and game-flow tests (splat, escape, crash, restart)

### M1 — Core feel
- [x] Poop falls under gravity and inherits the bird's dive speed; landing shadow under the bird
- [x] Splat effects: droplet particles, car squash, floating points, road splats on misses
- [x] Combo multiplier (up to ×5; broken by a miss or a 2.5s pause)
- [x] Belly/ammo (6 poops, slow digestion) + food pickups: berries, chili (rapid fire), burrito (big area poops)
- [x] Hold the poop side (or key) to keep pooping
- [x] Parallax background layers (clouds, far and near skyline)
- [x] Difficulty ramp within a run (scroll speed, car speed, spawn rate over 3 minutes)

### M2 — Levels and menus
- [ ] Level JSON format + loader + spawn timeline runner
- [ ] Objectives and star calculation
- [ ] World 1: 8 levels + boss
- [ ] Main menu, world map, level select, level intro, pause, results screens

### M3 — Persistence and economy
- [ ] Save system (progress, stars, coins, settings)
- [ ] Coins and rewards
- [ ] Shop: upgrades + cosmetics
- [ ] Ads + IAP integration plan (rewarded ads for coin bonus / continue)

### M4 — Achievements, trophies, Endless
- [ ] Achievement system + notifications
- [ ] Trophy Room screen
- [ ] Endless mode + leaderboard-ready scoring

### M5 — Art and content
- [ ] Blender pipeline scripts in `tools/blender/`
- [ ] New bird, car variants, food, coins, trophies, backgrounds
- [ ] Worlds 2–5 + bosses

### M6 — Polish
- [ ] Music and SFX
- [ ] Juice: screen shake, haptics, transitions
- [ ] Tutorial level; settings screen

### M7 — Release
- [ ] Real bundle id (replace `com.example.poopy_bird`), app icons, splash
- [ ] Ads/IAP live configuration
- [ ] Store listings and release builds
