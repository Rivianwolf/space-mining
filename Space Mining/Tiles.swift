//
//  Tiles.swift
//  Space Mining
//
//  Core world model: tile kinds, ore kinds, and grid directions.
//

import SpriteKit

enum Direction {
    case up, down, left, right
    var d: (col: Int, row: Int) {
        switch self {
        case .up:    return (0, -1)
        case .down:  return (0,  1)
        case .left:  return (-1, 0)
        case .right: return (1,  0)
        }
    }
}

/// The shiny things you dig up. Value/rarity scale with depth.
enum OreKind: CaseIterable {
    case bronzium, silverium, gold, ruby, emerald, diamond, fossil

    var value: Int {
        switch self {
        case .bronzium: return 4
        case .silverium: return 12
        case .gold: return 30
        case .ruby: return 70
        case .emerald: return 140
        case .diamond: return 320
        case .fossil: return 500
        }
    }
    var name: String {
        switch self {
        case .bronzium: return "Bronzium"
        case .silverium: return "Silverium"
        case .gold: return "Gold"
        case .ruby: return "Ruby"
        case .emerald: return "Emerald"
        case .diamond: return "Diamond"
        case .fossil: return "Alien Fossil"
        }
    }
    var symbol: String {
        switch self {
        case .bronzium: return "🟤"
        case .silverium: return "⚪️"
        case .gold: return "🟡"
        case .ruby: return "🔴"
        case .emerald: return "🟢"
        case .diamond: return "💎"
        case .fossil: return "🦴"
        }
    }
    var color: SKColor {
        switch self {
        case .bronzium:  return SKColor(red: 0.72, green: 0.45, blue: 0.20, alpha: 1)
        case .silverium: return SKColor(red: 0.80, green: 0.82, blue: 0.88, alpha: 1)
        case .gold:      return SKColor(red: 0.95, green: 0.80, blue: 0.20, alpha: 1)
        case .ruby:      return SKColor(red: 0.90, green: 0.20, blue: 0.30, alpha: 1)
        case .emerald:   return SKColor(red: 0.20, green: 0.80, blue: 0.45, alpha: 1)
        case .diamond:   return SKColor(red: 0.55, green: 0.88, blue: 1.00, alpha: 1)
        case .fossil:    return SKColor(red: 0.88, green: 0.84, blue: 0.62, alpha: 1)
        }
    }
    /// Asset-catalog image name for the designed mineral sprite.
    var asset: String {
        switch self {
        case .bronzium:  return "ore-copper"
        case .silverium: return "ore-silver"
        case .gold:      return "gem-goldra"
        case .ruby:      return "gem-rubex"
        case .emerald:   return "gem-verdil"
        case .diamond:   return "gem-aquite"
        case .fossil:    return "gem-voidstone"
        }
    }
    /// Minimum depth row before this ore can appear.
    var minDepth: Int {
        switch self {
        case .bronzium: return 0
        case .silverium: return 7
        case .gold: return 15
        case .ruby: return 27
        case .emerald: return 42
        case .diamond: return 60
        case .fossil: return 20
        }
    }
}

enum TileKind {
    case empty
    case dirt
    case rock      // hard — needs a strong drill
    case lava      // hazard — damages hull when drilled
    case ore(OreKind)

    var solid: Bool { if case .empty = self { return false }; return true }
    var isOre: Bool { if case .ore = self { return true }; return false }
}
