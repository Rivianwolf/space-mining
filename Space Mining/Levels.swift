//
//  Levels.swift
//  Space Mining
//
//  The "Choose Your Dig" journey: a chain of progressively deeper, harder
//  worlds from The Crust down to The Core (boss). To add a stop, append a
//  LevelConfig here — the map screen and engine pick it up automatically.
//

import Foundation

enum Levels {

    /// Shared ore table — depth gating (OreKind.minDepth) provides the natural
    /// progression as deeper worlds expose rarer minerals.
    private static let ores: [OreWeight] = [
        OreWeight(kind: .bronzium, base: 11, slope: -0.35, minWeight: 0.5),
        OreWeight(kind: .silverium, base: 8, slope: 0, minWeight: 8),
        OreWeight(kind: .gold, base: 7, slope: 0, minWeight: 7),
        OreWeight(kind: .ruby, base: 6, slope: 0, minWeight: 6),
        OreWeight(kind: .emerald, base: 5, slope: 0, minWeight: 5),
        OreWeight(kind: .diamond, base: 4, slope: 0, minWeight: 4),
        OreWeight(kind: .fossil, base: 0.7, slope: 0, minWeight: 0.7)
    ]

    private static func world(_ id: String, _ name: String, _ sub: String,
                              ground: Int, depth: Int, tint: String,
                              theme: Theme, unlock: Unlock,
                              rock: HazardCurve, lava: HazardCurve,
                              boss: Bool = false) -> LevelConfig {
        LevelConfig(
            id: id, name: name, subtitle: sub,
            cols: 9, skyRows: 6, groundRows: ground,
            oreChance: Curve(base: 0.12, slope: 0.0022, max: 0.32),
            rock: rock, lava: lava, ores: ores,
            theme: theme, objective: .reachDepth(meters: depth),
            unlock: unlock, enemies: [], nodeTint: tint, isBoss: boss)
    }

    // MARK: Themes (terrain palettes per world)

    private static let crustTheme = Theme(
        soilTop: "#6a5e82", soilBot: "#473c5e", stoneTop: "#3a4a86", stoneBot: "#2a3768",
        rockTop: "#4a3a78", rockBot: "#2c2050", bedrockTop: "#2c2050", bedrockBot: "#120e2c",
        hazardRockTop: "#2a3768", hazardRockBot: "#161f44",
        skyTop: "#34508f", skyGlow: "#14205a", voidColor: "#06091a",
        tileAssets: ["tile-topsoil", "tile-bluestone", "tile-deeprock", "tile-bedrock"])

    private static let blueTheme = Theme(
        soilTop: "#3a5a8a", soilBot: "#2a4570", stoneTop: "#2f4f9a", stoneBot: "#1f3a78",
        rockTop: "#25408a", rockBot: "#162a60", bedrockTop: "#122046", bedrockBot: "#0a1430",
        hazardRockTop: "#2a3a7a", hazardRockBot: "#141f4a",
        skyTop: "#3f6fc0", skyGlow: "#2a5fae", voidColor: "#060a1a")

    private static let greenTheme = Theme(
        soilTop: "#2f6a52", soilBot: "#1f4a3a", stoneTop: "#2a6a6a", stoneBot: "#1a4a4a",
        rockTop: "#265a4a", rockBot: "#163a30", bedrockTop: "#0f3a2c", bedrockBot: "#06201a",
        hazardRockTop: "#2a5a55", hazardRockBot: "#143a35",
        skyTop: "#2f7a6a", skyGlow: "#2a8a6a", voidColor: "#04140e")

    private static let riftTheme = Theme(
        soilTop: "#5a4a2a", soilBot: "#3a2e18", stoneTop: "#6a5020", stoneBot: "#42300f",
        rockTop: "#5a3a18", rockBot: "#321e0c", bedrockTop: "#241606", bedrockBot: "#140c04",
        hazardRockTop: "#5a3a2a", hazardRockBot: "#2a1808",
        skyTop: "#4a3a5a", skyGlow: "#8a6a2a", voidColor: "#100a14")

    private static let magmaTheme = Theme(
        soilTop: "#7a3a2a", soilBot: "#5a2618", stoneTop: "#8a3a1a", stoneBot: "#5a2410",
        rockTop: "#6a2418", rockBot: "#3a120a", bedrockTop: "#2a0e08", bedrockBot: "#160604",
        hazardRockTop: "#6a2a18", hazardRockBot: "#3a1206",
        skyTop: "#6a2a2a", skyGlow: "#a82a1a", voidColor: "#140404")

    private static let voidTheme = Theme(
        soilTop: "#4a3a6a", soilBot: "#2e2450", stoneTop: "#3a2a6a", stoneBot: "#241a50",
        rockTop: "#2e1f5a", rockBot: "#180f3a", bedrockTop: "#140a2c", bedrockBot: "#0a0420",
        hazardRockTop: "#2e2055", hazardRockBot: "#160c34",
        skyTop: "#3a2a6f", skyGlow: "#6a3ab0", voidColor: "#07041a")

    private static let coreTheme = Theme(
        soilTop: "#5a2a5a", soilBot: "#3a1838", stoneTop: "#4a1f4a", stoneBot: "#2e1230",
        rockTop: "#3a1538", rockBot: "#200a22", bedrockTop: "#160616", bedrockBot: "#0a020a",
        hazardRockTop: "#4a1a3a", hazardRockBot: "#280a22",
        skyTop: "#3a1a4a", skyGlow: "#b03a8a", voidColor: "#0a020a")

    // MARK: The journey (bottom → boss)

    static let all: [LevelConfig] = [
        world("crust", "The Crust", "Where every miner starts",
              ground: 70, depth: 300, tint: "#6f6aa8", theme: crustTheme, unlock: .always,
              rock: HazardCurve(minDepth: 6, curve: Curve(base: 0.04, slope: 0.0012, max: 0.12)),
              lava: HazardCurve(minDepth: 16, curve: Curve(base: 0.01, slope: 0.0012, max: 0.09))),

        world("bluestone", "Bluestone Belt", "Cool, dense rock",
              ground: 90, depth: 450, tint: "#4a78c8", theme: blueTheme,
              unlock: .afterLevel("crust"),
              rock: HazardCurve(minDepth: 5, curve: Curve(base: 0.06, slope: 0.0015, max: 0.16)),
              lava: HazardCurve(minDepth: 18, curve: Curve(base: 0.01, slope: 0.001, max: 0.08))),

        world("echo", "Echo Cavern", "Hollow and humming",
              ground: 110, depth: 600, tint: "#3fbe82", theme: greenTheme,
              unlock: .afterLevel("bluestone"),
              rock: HazardCurve(minDepth: 5, curve: Curve(base: 0.07, slope: 0.0016, max: 0.18)),
              lava: HazardCurve(minDepth: 14, curve: Curve(base: 0.015, slope: 0.0015, max: 0.12))),

        world("rift", "Deep Rift", "The drop-off",
              ground: 130, depth: 800, tint: "#ffd574", theme: riftTheme,
              unlock: .afterLevel("echo"),
              rock: HazardCurve(minDepth: 5, curve: Curve(base: 0.06, slope: 0.0016, max: 0.18)),
              lava: HazardCurve(minDepth: 10, curve: Curve(base: 0.02, slope: 0.002, max: 0.16))),

        world("magma", "Magma Vein", "Mind the molten pockets",
              ground: 150, depth: 1000, tint: "#ff5a1e", theme: magmaTheme,
              unlock: .afterLevel("rift"),
              rock: HazardCurve(minDepth: 5, curve: Curve(base: 0.05, slope: 0.0014, max: 0.15)),
              lava: HazardCurve(minDepth: 8, curve: Curve(base: 0.035, slope: 0.0032, max: 0.24))),

        world("void", "Void Layer", "Cold, dark, valuable",
              ground: 170, depth: 1200, tint: "#a06be0", theme: voidTheme,
              unlock: .afterLevel("magma"),
              rock: HazardCurve(minDepth: 4, curve: Curve(base: 0.08, slope: 0.0018, max: 0.20)),
              lava: HazardCurve(minDepth: 12, curve: Curve(base: 0.02, slope: 0.002, max: 0.16))),

        world("core", "The Core", "The deepest dig of all",
              ground: 200, depth: 1500, tint: "#7a4fd6", theme: coreTheme,
              unlock: .afterLevel("void"),
              rock: HazardCurve(minDepth: 4, curve: Curve(base: 0.09, slope: 0.002, max: 0.22)),
              lava: HazardCurve(minDepth: 8, curve: Curve(base: 0.03, slope: 0.003, max: 0.22)),
              boss: true)
    ]

    /// First level — the safe default when a scene needs one before selection.
    static let deepDig = all[0]

    static func level(id: String) -> LevelConfig { all.first { $0.id == id } ?? all[0] }
}
