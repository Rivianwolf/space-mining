//
//  PlayerState.swift
//  Space Mining
//
//  Persistent progression that lives across levels: cash, pod upgrades, and
//  per-level progress (unlocked / completed / best depth). Completed levels
//  stay unlocked and replayable.
//

import Foundation

final class PlayerState {

    static let shared = PlayerState()

    // Economy + pod upgrades (shared across all levels)
    var cash = 0
    var drillLevel = 1
    var fuelLevel = 0
    var cargoLevel = 0
    var hullLevel = 0
    var engineLevel = 0

    struct Progress {
        var completed = false
        var bestDepth = 0
        var stars = 0          // 0–3, best earned
    }
    private(set) var progress: [String: Progress] = [:]

    private let d = UserDefaults.standard

    init() { load() }

    // MARK: Level gating

    func isUnlocked(_ level: LevelConfig) -> Bool {
        switch level.unlock {
        case .always: return true
        case .afterLevel(let id): return progress[id]?.completed == true
        }
    }

    func isCompleted(_ id: String) -> Bool { progress[id]?.completed == true }
    func bestDepth(_ id: String) -> Int { progress[id]?.bestDepth ?? 0 }
    func stars(_ id: String) -> Int { progress[id]?.stars ?? 0 }

    func recordDepth(_ id: String, meters: Int) {
        var p = progress[id] ?? Progress()
        if meters > p.bestDepth { p.bestDepth = meters; progress[id] = p; save() }
    }

    func markCompleted(_ id: String, depthMeters: Int, stars: Int) {
        var p = progress[id] ?? Progress()
        p.completed = true
        p.bestDepth = max(p.bestDepth, depthMeters)
        p.stars = max(p.stars, stars)
        progress[id] = p
        save()
    }

    // MARK: Persistence

    func save() {
        d.set(cash, forKey: "ps_cash")
        d.set(drillLevel, forKey: "ps_drill")
        d.set(fuelLevel, forKey: "ps_fuel")
        d.set(cargoLevel, forKey: "ps_cargo")
        d.set(hullLevel, forKey: "ps_hull")
        d.set(engineLevel, forKey: "ps_engine")
        d.set(progress.filter { $0.value.completed }.map { $0.key }, forKey: "ps_completed")
        for (id, p) in progress {
            d.set(p.bestDepth, forKey: "ps_depth_\(id)")
            d.set(p.stars, forKey: "ps_stars_\(id)")
        }
    }

    func load() {
        guard d.object(forKey: "ps_drill") != nil else { return }
        cash = d.integer(forKey: "ps_cash")
        drillLevel = max(1, d.integer(forKey: "ps_drill"))
        fuelLevel = d.integer(forKey: "ps_fuel")
        cargoLevel = d.integer(forKey: "ps_cargo")
        hullLevel = d.integer(forKey: "ps_hull")
        engineLevel = d.integer(forKey: "ps_engine")
        let done = (d.array(forKey: "ps_completed") as? [String]) ?? []
        for lv in Levels.all {
            var p = Progress()
            p.completed = done.contains(lv.id)
            p.bestDepth = d.integer(forKey: "ps_depth_\(lv.id)")
            p.stars = d.integer(forKey: "ps_stars_\(lv.id)")
            if p.completed || p.bestDepth > 0 { progress[lv.id] = p }
        }
    }
}
