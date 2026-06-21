//
//  WorldGenerator.swift
//  Space Mining
//
//  Turns a LevelConfig into a tile grid. Pure data in → grid out; the scene
//  is responsible for turning the grid into nodes.
//

import Foundation

enum WorldGenerator {

    /// Builds the solid/empty tile grid for a level, with a clean starting
    /// shaft carved directly under the base so the first dig always works.
    static func generate(_ level: LevelConfig) -> [[TileKind]] {
        var grid = Array(repeating: Array(repeating: TileKind.empty, count: level.cols),
                         count: level.totalRows)

        for row in level.skyRows..<level.totalRows {
            let depth = row - level.skyRows
            for col in 0..<level.cols {
                grid[row][col] = content(level, depth: depth)
            }
        }
        grid[level.skyRows][level.cols / 2] = .dirt
        return grid
    }

    private static func content(_ level: LevelConfig, depth: Int) -> TileKind {
        if Double.random(in: 0...1) < level.rock.chance(depth) { return .rock }
        if Double.random(in: 0...1) < level.lava.chance(depth) { return .lava }
        if Double.random(in: 0...1) < level.oreChance.value(depth),
           let ore = weightedOre(level, depth: depth) {
            return .ore(ore)
        }
        return .dirt
    }

    private static func weightedOre(_ level: LevelConfig, depth: Int) -> OreKind? {
        var weights: [(OreKind, Double)] = []
        for ow in level.ores where depth >= ow.kind.minDepth {
            let w = ow.weight(depth)
            if w > 0 { weights.append((ow.kind, w)) }
        }
        let total = weights.reduce(0) { $0 + $1.1 }
        guard total > 0 else { return nil }
        var roll = Double.random(in: 0..<total)
        for (kind, w) in weights {
            if roll < w { return kind }
            roll -= w
        }
        return weights.last?.0
    }
}
