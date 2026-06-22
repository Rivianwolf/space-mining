# Deep Dig — Space Mining

A cozy-space, **Motherload-style** mining game for iOS, built with **SpriteKit**.
Pilot a little drill pod down through tile worlds, dig up shiny gems, manage fuel
and cargo, haul your haul back to the surface base to sell and upgrade — then
dive deeper. Seven themed worlds, from **The Crust** to the **The Core** boss.

> Built programmatically (no Storyboard/SKS gameplay) and rendered mostly with
> **procedural Core Graphics art**, with designed sprites from the *Deep Dig*
> design pack (gems, ores, tiles, pod, icon, tow-drone, planets).

---

## Gameplay

- **Dig** through a tile grid: drill down/left/right, thrust up through the
  tunnels you've carved. Gravity pulls you down through empty space.
- **Collect** minerals (bronzium, silverium, gold, ruby, emerald, diamond, and
  the rare alien fossil) — value and rarity scale with depth.
- **Manage** three resources:
  - ⛽️ **Fuel** — drains while you're away from the surface and per action.
  - 📦 **Cargo** — limited hold; sell at the base to empty it.
  - 🛡️ **Hull** — damaged by lava and hard falls.
- **Return to base** to **sell, refuel, repair, and buy upgrades**
  (drill, fuel tank, cargo bay, hull, engine).
- **Complete the objective** (reach a target depth) to finish a world and unlock
  the next, earning a **0–3 star** rating for efficiency and haul.
- **Run out of fuel?** A **tow-drone rescue** descends the shaft, clamps your
  pod, and hauls it home — cargo is the tow fee.

### Controls (on-screen)

| Button | Action |
|---|---|
| ◀ ▶ | move / drill sideways |
| 🔽 | drill straight down |
| 🔼 | thrust up through dug tunnels (uses fuel) |

## The journey

A scrolling-free **"Choose Your Dig"** level map shows all seven worlds along a
winding trail. Completed stops show a number + star rating, the current stop
gets a **PLAY** button, and locked stops show a padlock. Tapping a world plays a
themed entrance dive before the level loads.

1. **The Crust** — where every miner starts
2. **Bluestone Belt** — cool, dense rock (ringed ocean world)
3. **Echo Cavern** — hollow and humming
4. **Deep Rift** — the drop-off
5. **Magma Vein** — mind the molten pockets
6. **Void Layer** — cold, dark, valuable
7. **The Core** — the boss; the deepest dig of all

Progress (cash, upgrades, completion, best depth, stars) persists across
sessions; the tile world regenerates each visit.

---

## Architecture

`GameScene` was split into focused files; **levels are data**, so adding a world
is a single entry in `Levels.swift` — the engine doesn't change.

```
Space Mining/
├─ App
│   ├─ AppDelegate.swift / SceneDelegate.swift
│   └─ GameViewController.swift        # launches the level map
├─ Model
│   ├─ Tiles.swift                     # TileKind / OreKind / Direction
│   ├─ Enemy.swift                     # stub for a future enemies feature
│   └─ PlayerState.swift               # cash, upgrades, per-level progress + stars
├─ Levels
│   ├─ LevelConfig.swift               # a level as pure data
│   └─ Levels.swift                    # the 7-world catalog
├─ World
│   └─ WorldGenerator.swift            # LevelConfig → tile grid
├─ Art
│   ├─ TextureFactory.swift            # procedural terrain/pod/gems/etc.
│   ├─ LevelMapArt.swift               # planet nodes, bg planets, saucer
│   └─ Palette.swift                   # hex → color helper
└─ Scenes
    ├─ GameScene.swift                 # core: state, loop, camera, input
    ├─ GameScene+World.swift           # terrain / pod / base build
    ├─ GameScene+HUD.swift             # HUD, chrome, controls
    ├─ GameScene+Drilling.swift        # movement, digging, objective
    ├─ GameScene+Effects.swift         # particles, dust, banners
    ├─ GameScene+Shop.swift            # base shop + transactions
    ├─ GameScene+Rescue.swift          # out-of-fuel tow-drone cutscene
    ├─ LevelSelectScene.swift          # the "Choose Your Dig" map
    └─ LevelEntrance.swift             # per-world entrance dive transitions
```

> Note: files live flat in the `Space Mining/` group; the table groups them by
> responsibility for clarity. The Xcode project uses file-system-synchronized
> groups, so new `.swift` files compile automatically.

**Patterns:** data-driven level configs, factories (`WorldGenerator`,
`TextureFactory`, `LevelMapArt`), a shared `PlayerState` singleton, a dedicated
UI layer above the world, and SpriteKit's scene/node tree + game loop.

---

## Build & run

- **Xcode** with the iOS SDK.
- Open `Space Mining.xcodeproj`, scheme **Space Mining**, run on an iPhone
  simulator (developed against **iPhone 17 / iOS 26**).

```bash
xcodebuild -project "Space Mining.xcodeproj" -scheme "Space Mining" \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build
```

No external dependencies.

## Art & design

All in-game art is either drawn procedurally (Core Graphics → `SKTexture`) or
sourced from the *Deep Dig* design pack (app icon, mineral/tile/pod sprites,
tow-drone). The level map and per-world entrance transitions are reproduced from
the *Deep Dig Level Map* design.
