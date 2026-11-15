# Level format

Levels live in `assets/levels/` as JSON and are loaded through `LevelRepository`
(`lib/levels/level_repository.dart`). Today that reads bundled assets; a backend
implementation can serve the same JSON later. `test/levels/level_content_test.dart`
checks every shipped level, so run `flutter test` after editing.

## `worlds.json`

```json
{
  "worlds": [
    { "id": "w1", "name": "Suburbs", "levels": ["w1_l1", "...", "w1_boss"] },
    { "id": "w2", "name": "Downtown", "comingSoon": true }
  ]
}
```

Levels are listed in play order. The last level of a world is its boss.
A level unlocks when the previous one is beaten; a world unlocks when the
previous world is complete; Endless unlocks when World 1 is complete.

## `<level id>.json`

| Field | Type | Meaning |
|---|---|---|
| `id` | string | Stable id, must match the file name. Used in saved progress and results. |
| `version` | int | Bump when the level's content changes (results record it). Default 1. |
| `name`, `description` | string | Shown on the intro screen. |
| `timeLimit` | seconds | The level ends when time runs out; objectives are checked then. |
| `scrollSpeed` | px/s | How fast the world scrolls. |
| `rageFillPerEscape` | 0–1 | Rage added per car that escapes clean (1.0 = game over). |
| `food` | object | `types` (subset of `berries`, `chili`, `burrito`; `[]` for none), `minInterval`, `maxInterval` seconds. |
| `traffic` | list | Random traffic segments (below). |
| `scriptedSpawns` | list | Cars or bosses at set times (below). |
| `objectives` | list | All must be met to win (below). |
| `stars` | object | `two` and `three`: score thresholds. Winning gives 1 star. |
| `isBoss` | bool | Marks the world's boss level. |
| `endWhenObjectivesMet` | bool | Win immediately when all objectives are met (boss levels). |

### Traffic segment

```json
{ "from": 12, "to": 50, "interval": 2.0, "groundSpeed": [0, 60],
  "cars": { "sedan": 3, "sportsCar": 2 }, "lanes": [0, 1] }
```

Between `from` and `to` seconds, a car is attempted every `interval` seconds.
`cars` are relative weights. A car's screen speed is `scrollSpeed` + a random
ground speed in `groundSpeed` + the car type's own bonus. `lanes`: 0 is the far
lane, 1 the near lane (default both). Bosses can't appear in random traffic.

### Scripted spawn

```json
{ "at": 3, "car": "carWashTruck", "lane": 1, "groundSpeed": 25 }
```

If the lane is blocked at that moment, the spawn waits until there is room.

### Objectives

| `type` | Extra fields | Meaning |
|---|---|---|
| `splatCars` | `count`, optional `carType` | Fully splat that many cars (of that type). |
| `reachCombo` | `count` | Reach a combo of at least `count`. |
| `maxEscapes` | `count` | At most `count` cars escape clean. Exceeding it fails the level at once. |
| `reachScore` | `count` | Reach that score. |
| `defeatBoss` | | Defeat the level's boss. |

### Car types

| Name | Points per hit | Hits | Notes |
|---|---|---|---|
| `sedan` | 50 | 1 | |
| `sportsCar` | 100 | 1 | +70 ground speed |
| `carWashTruck` | 100 | 8 | World 1 boss; sprays water that washes nearby cars clean; loops back if not defeated; +1000 bonus |
