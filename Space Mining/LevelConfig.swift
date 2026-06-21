//
//  LevelConfig.swift
//  Space Mining
//
//  A level is pure data. Each one is a selectable world with its own theme,
//  terrain tuning, ore table, hazards, objective and (later) enemies. Adding a
//  new level = adding one entry to `Levels.all` — the engine never changes.
//

import SpriteKit

/// value = min(base + slope·depth, max)
struct Curve {
    let base: Double
    let slope: Double
    let max: Double
    func value(_ depth: Int) -> Double { Swift.min(base + slope * Double(depth), max) }
}

/// A spawn curve gated by a minimum depth.
struct HazardCurve {
    let minDepth: Int
    let curve: Curve
    func chance(_ depth: Int) -> Double { depth > minDepth ? curve.value(depth) : 0 }
}

/// Per-ore spawn weight: weight = max(minWeight, base + slope·depth), still
/// gated by `OreKind.minDepth`. Omit an ore from a level to keep it out of it.
struct OreWeight {
    let kind: OreKind
    let base: Double
    let slope: Double
    let minWeight: Double
    func weight(_ depth: Int) -> Double { Swift.max(minWeight, base + slope * Double(depth)) }
}

/// Terrain / sky palette for a world (hex strings, resolved by TextureFactory).
struct Theme {
    let soilTop, soilBot: String
    let stoneTop, stoneBot: String
    let rockTop, rockBot: String
    let bedrockTop, bedrockBot: String
    let hazardRockTop, hazardRockBot: String
    let skyTop, skyGlow, voidColor: String

    /// Optional designed tile sprites per band [soil, stone, rock, bedrock].
    /// When nil, the procedural theme-colored tiles are used instead.
    var tileAssets: [String]? = nil

    /// Depth-layer colors indexed by band 0…3 (soil → bedrock).
    var bands: [(String, String)] {
        [(soilTop, soilBot), (stoneTop, stoneBot), (rockTop, rockBot), (bedrockTop, bedrockBot)]
    }
}

/// What completing a level requires. Worlds carry an objective (hybrid model).
enum Objective {
    case reachDepth(meters: Int)
    case earnCash(Int)
    case collectOre(count: Int)

    var label: String {
        switch self {
        case .reachDepth(let m):  return "Reach \(m)m deep"
        case .earnCash(let c):    return "Earn 💰\(c)"
        case .collectOre(let n):  return "Collect \(n) gems"
        }
    }
}

/// When a level becomes available.
enum Unlock {
    case always
    case afterLevel(String)   // id of the level that must be completed first
}

struct LevelConfig {
    let id: String
    let name: String
    let subtitle: String

    // World dimensions
    let cols: Int
    let skyRows: Int
    let groundRows: Int

    // Generation tuning
    let oreChance: Curve
    let rock: HazardCurve
    let lava: HazardCurve
    let ores: [OreWeight]

    let theme: Theme
    let objective: Objective
    let unlock: Unlock
    let enemies: [EnemySpawn]   // empty for now — hook for future enemy waves

    var totalRows: Int { skyRows + groundRows }
    var surfaceRow: Int { skyRows - 1 }
}
