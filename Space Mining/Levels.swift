//
//  Levels.swift
//  Space Mining
//
//  The level catalog. To add a world, append a LevelConfig here — nothing in
//  the engine needs to change. Levels are selectable, unlock in order, and stay
//  replayable once completed.
//

import Foundation

enum Levels {

    /// A constant-weight ore entry (weight doesn't change with depth).
    private static func ore(_ k: OreKind, _ w: Double) -> OreWeight {
        OreWeight(kind: k, base: w, slope: 0, minWeight: w)
    }

    // MARK: Level 1 — Deep Dig (the original tuning, exactly)

    static let deepDig = LevelConfig(
        id: "deepdig",
        name: "Deep Dig",
        subtitle: "Cozy Space Mining",
        cols: 9, skyRows: 6, groundRows: 92,
        oreChance: Curve(base: 0.12, slope: 0.002, max: 0.30),
        rock: HazardCurve(minDepth: 6, curve: Curve(base: 0.04, slope: 0.0012, max: 0.13)),
        lava: HazardCurve(minDepth: 12, curve: Curve(base: 0.015, slope: 0.0018, max: 0.14)),
        ores: [
            OreWeight(kind: .bronzium, base: 11, slope: -0.35, minWeight: 0.5),
            ore(.silverium, 8), ore(.gold, 7), ore(.ruby, 6),
            ore(.emerald, 5), ore(.diamond, 4), ore(.fossil, 0.7)
        ],
        theme: Theme(
            soilTop: "#6a5e82", soilBot: "#473c5e",
            stoneTop: "#3a4a86", stoneBot: "#2a3768",
            rockTop: "#4a3a78", rockBot: "#2c2050",
            bedrockTop: "#2c2050", bedrockBot: "#120e2c",
            hazardRockTop: "#2a3768", hazardRockBot: "#161f44",
            skyTop: "#34508f", skyGlow: "#14205a", voidColor: "#06091a",
            tileAssets: ["tile-topsoil", "tile-bluestone", "tile-deeprock", "tile-bedrock"]),
        objective: .reachDepth(meters: 500),
        unlock: .always,
        enemies: []
    )

    // MARK: Level 2 — Ember Hollow (lava-heavy, warm)

    static let ember = LevelConfig(
        id: "ember",
        name: "Ember Hollow",
        subtitle: "Mind the magma",
        cols: 9, skyRows: 6, groundRows: 110,
        oreChance: Curve(base: 0.13, slope: 0.0022, max: 0.32),
        rock: HazardCurve(minDepth: 5, curve: Curve(base: 0.05, slope: 0.0014, max: 0.15)),
        lava: HazardCurve(minDepth: 8, curve: Curve(base: 0.03, slope: 0.003, max: 0.22)),
        ores: [
            OreWeight(kind: .bronzium, base: 9, slope: -0.30, minWeight: 0.5),
            ore(.gold, 9), ore(.ruby, 8), ore(.emerald, 4),
            ore(.diamond, 5), ore(.fossil, 1.0)
        ],
        theme: Theme(
            soilTop: "#7a4a3a", soilBot: "#5a3326",
            stoneTop: "#8a4a2a", stoneBot: "#5a2e18",
            rockTop: "#6a2a20", rockBot: "#3a1410",
            bedrockTop: "#2a1010", bedrockBot: "#140606",
            hazardRockTop: "#5a2a20", hazardRockBot: "#2a1208",
            skyTop: "#5a2a3a", skyGlow: "#7a2a2a", voidColor: "#140608"),
        objective: .reachDepth(meters: 700),
        unlock: .afterLevel("deepdig"),
        enemies: []
    )

    // MARK: Level 3 — Glacio (icy, rock-heavy)

    static let glacio = LevelConfig(
        id: "glacio",
        name: "Glacio",
        subtitle: "Frozen to the core",
        cols: 9, skyRows: 6, groundRows: 130,
        oreChance: Curve(base: 0.12, slope: 0.0024, max: 0.32),
        rock: HazardCurve(minDepth: 4, curve: Curve(base: 0.07, slope: 0.0018, max: 0.20)),
        lava: HazardCurve(minDepth: 30, curve: Curve(base: 0.01, slope: 0.001, max: 0.06)),
        ores: [
            OreWeight(kind: .silverium, base: 11, slope: -0.20, minWeight: 1),
            ore(.gold, 6), ore(.ruby, 5), ore(.emerald, 6),
            ore(.diamond, 8), ore(.fossil, 1.2)
        ],
        theme: Theme(
            soilTop: "#5a7a9a", soilBot: "#3a5a7a",
            stoneTop: "#4a6a9a", stoneBot: "#2a4a7a",
            rockTop: "#3a4a8a", rockBot: "#1a2a5a",
            bedrockTop: "#16204a", bedrockBot: "#0a1230",
            hazardRockTop: "#2a3a6a", hazardRockBot: "#141f44",
            skyTop: "#5a7aaf", skyGlow: "#2a5a8a", voidColor: "#06091a"),
        objective: .reachDepth(meters: 900),
        unlock: .afterLevel("ember"),
        enemies: []
    )

    static let all: [LevelConfig] = [deepDig, ember, glacio]

    static func level(id: String) -> LevelConfig { all.first { $0.id == id } ?? deepDig }
}
