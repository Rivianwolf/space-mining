//
//  Enemy.swift
//  Space Mining
//
//  Placeholder for the future enemies feature. A level can declare which
//  enemies spawn and how often; the gameplay behaviour will be added later.
//  This exists now so LevelConfig and the world generator already have the
//  hook in place and nothing in the data model has to change when we build it.
//

import Foundation

enum EnemyKind {
    case rockBeetle    // crawls tunnels, blocks the pod
    case lavaSlug      // lurks near lava pockets
    case voidWraith    // deep-only, drains fuel
}

/// How an enemy seeds into a world. Rate is spawns-per-100-ground-cells.
struct EnemySpawn {
    let kind: EnemyKind
    let minDepth: Int
    let rate: Double
}
