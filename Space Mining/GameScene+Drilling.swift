//
//  GameScene+Drilling.swift
//  Space Mining
//

import SpriteKit
import UIKit

extension GameScene {

    func checkObjective() {
        guard !levelComplete else { return }
        let met: Bool
        switch level.objective {
        case .reachDepth(let m): met = maxDepthMeters >= m
        case .earnCash(let c):   met = cashEarned >= c
        case .collectOre(let n): met = oreCollectedTotal >= n
        }
        guard met else { return }
        levelComplete = true
        player.markCompleted(level.id, depthMeters: maxDepthMeters)
        showCompletionPopup()
    }

    /// The level that completing this one unlocks (nil if this is the last).
    func nextLevel() -> LevelConfig? {
        guard let i = Levels.all.firstIndex(where: { $0.id == level.id }) else { return nil }
        return i + 1 < Levels.all.count ? Levels.all[i + 1] : nil
    }

    /// Modal shown on success: choose to spend earnings in the shop or advance.
    func showCompletionPopup() {
        guard completionPanel == nil else { return }
        heldButtons.removeAll(); updateButtonHighlights()

        let panel = SKNode()
        panel.zPosition = uiZ + 20

        let dim = SKShapeNode(rect: CGRect(x: -size.width / 2, y: -size.height / 2,
                                           width: size.width, height: size.height))
        dim.fillColor = SKColor(white: 0, alpha: 0.78); dim.strokeColor = .clear
        panel.addChild(dim)

        let card = SKShapeNode(rectOf: CGSize(width: size.width * 0.82, height: 340), cornerRadius: 24)
        card.fillColor = SKColor(red: 0.06, green: 0.07, blue: 0.16, alpha: 1)
        card.strokeColor = SKColor(red: 0.37, green: 0.55, blue: 1, alpha: 0.5); card.lineWidth = 2
        panel.addChild(card)

        let emoji = SKLabelNode(text: "🎉"); emoji.fontSize = 50; emoji.verticalAlignmentMode = .center
        emoji.position = CGPoint(x: 0, y: 108); panel.addChild(emoji)

        let title = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
        title.text = "LEVEL COMPLETE!"; title.fontSize = 30
        title.fontColor = SKColor(red: 0.38, green: 0.94, blue: 0.66, alpha: 1)
        title.position = CGPoint(x: 0, y: 56); panel.addChild(title)

        let stats = SKLabelNode(fontNamed: font)
        stats.text = "\(level.name)  ·  reached \(maxDepthMeters)m"
        stats.fontSize = 15; stats.fontColor = SKColor(white: 0.85, alpha: 1)
        stats.position = CGPoint(x: 0, y: 22); panel.addChild(stats)

        panel.addChild(popupButton("🛒  Buy Upgrades", name: "cp_upgrades",
                                    color: SKColor(red: 0.2, green: 0.6, blue: 0.45, alpha: 1), y: -34))
        let nextText = nextLevel() != nil ? "Next Level  →" : "Back to Worlds"
        panel.addChild(popupButton(nextText, name: "cp_next",
                                    color: SKColor(red: 0.25, green: 0.45, blue: 0.85, alpha: 1), y: -100))

        uiLayer.addChild(panel)
        completionPanel = panel
        card.setScale(0.5); card.alpha = 0
        card.run(.group([.scale(to: 1, duration: 0.3), .fadeIn(withDuration: 0.3)]))
    }

    func popupButton(_ text: String, name: String, color: SKColor, y: CGFloat) -> SKShapeNode {
        let b = SKShapeNode(rectOf: CGSize(width: size.width * 0.6, height: 50), cornerRadius: 14)
        b.name = name; b.fillColor = color; b.strokeColor = .white; b.lineWidth = 2
        b.position = CGPoint(x: 0, y: y)
        let l = SKLabelNode(fontNamed: font)
        l.text = text; l.fontSize = 18; l.fontColor = .white
        l.verticalAlignmentMode = .center; l.name = name
        b.addChild(l)
        return b
    }

    func handleCompletionTap(_ p: CGPoint) {
        guard let panel = completionPanel else { return }
        var tapped: String?
        for node in panel.children where node.name != nil {
            if node.frame.contains(p) { tapped = node.name; break }
        }
        switch tapped {
        case "cp_next":
            advanceToNextLevel()
        case "cp_upgrades":
            completionPanel?.removeFromParent(); completionPanel = nil
            shopExit = .nextLevel
            openShop()
        case "rescue_upgrades":
            completionPanel?.removeFromParent(); completionPanel = nil
            shopExit = .retry
            openShop()
        case "cp_retry":
            retryLevel()
        case "cp_worlds":
            completionPanel?.removeFromParent(); completionPanel = nil
            goToLevelSelect()
        default:
            break
        }
    }

    /// Replay the current level from scratch (after a failed run).
    func retryLevel() {
        saveProgress()
        completionPanel?.removeFromParent(); completionPanel = nil
        let scene = GameScene(size: size)
        scene.level = level
        scene.scaleMode = .resizeFill
        view?.presentScene(scene, transition: SKTransition.crossFade(withDuration: 0.4))
    }

    /// Move on from a completed level — to the next world, or the picker if last.
    func advanceToNextLevel() {
        saveProgress()
        completionPanel?.removeFromParent(); completionPanel = nil
        if let next = nextLevel() {
            let scene = GameScene(size: size)
            scene.level = next
            scene.scaleMode = .resizeFill
            view?.presentScene(scene, transition: .doorsOpenHorizontal(withDuration: 0.45))
        } else {
            goToLevelSelect()
        }
    }

    func move(_ dir: Direction) {
        let tCol = podCol + dir.d.col
        let tRow = podRow + dir.d.row
        guard inRange(tCol, tRow) else { return }

        if dir == .left { facingLeft = true; pod.xScale = -1 }
        if dir == .right { facingLeft = false; pod.xScale = 1 }

        let target = grid[tRow][tCol]

        if case .empty = target {
            if dir == .up {
                guard fuel > 0 else { return }
                fuel = max(0, fuel - thrustCost)
                podFlame?.removeAllActions()
                podFlame?.run(.sequence([.fadeAlpha(to: 1, duration: 0.04),
                                         .wait(forDuration: moveDuration),
                                         .fadeOut(withDuration: 0.18)]))
            } else {
                fuel = max(0, fuel - 0.25)
            }
            animatePod(toCol: tCol, row: tRow, duration: moveDuration, dig: false)
            return
        }

        // Solid tile ahead. You can't drill straight up.
        guard dir != .up else { return }

        if case .rock = target, !canBreakRock {
            flashBanner("Need a stronger drill!")
            return
        }

        dig(col: tCol, row: tRow, dir: dir)
    }

    func dig(col: Int, row: Int, dir: Direction) {
        let depth = row - skyRows
        let kind = grid[row][col]
        let toughness = toughnessFor(kind, depth: depth)
        let digTime = max(0.07, 0.20 * toughness / drillSpeed)

        guard fuel > 0 else { return }
        fuel = max(0, fuel - (0.4 + toughness * 0.35))

        // Resolve tile effects.
        switch kind {
        case .lava:
            hull = max(0, hull - 14)
            screenFlash(SKColor(red: 1, green: 0.4, blue: 0.1, alpha: 0.35))
        case .ore(let o):
            if cargoCount < maxCargo {
                cargo[o, default: 0] += 1
                oreCollectedTotal += 1
                spawnFloatingText("+\(o.symbol)", at: cellPosition(col, row), color: o.color)
            } else {
                flashBanner("Cargo full!")
            }
        default:
            break
        }

        let p = cellPosition(col, row)
        startDrill(duration: digTime)
        drillWobble(duration: digTime, toughness: toughness)
        removeTile(col, row)
        spawnDigDebris(at: p, kind: kind, toward: dir)
        spawnDust(at: p)
        spawnSpark(at: p)
        animatePod(toCol: col, row: row, duration: digTime, dig: true)

        if hull <= 0 { /* handled after move via destroy check */ }
    }

    func toughnessFor(_ kind: TileKind, depth: Int) -> Double {
        switch kind {
        case .dirt:     return 1.0 + Double(depth) * 0.04
        case .ore:      return 1.3 + Double(depth) * 0.04
        case .lava:     return 1.2
        case .rock:     return 2.6 + Double(depth) * 0.05
        case .empty:    return 0
        }
    }

    func fall() {
        fallCells += 1
        animatePod(toCol: podCol, row: podRow + 1, duration: 0.07, dig: false)
    }

    func land() {
        if fallCells > 5 {
            let dmg = Double(fallCells - 5) * 6
            hull = max(0, hull - dmg)
            screenFlash(SKColor(white: 1, alpha: 0.25))
            if hull <= 0 { destroyPod(); fallCells = 0; return }
        }
        fallCells = 0
    }

    func animatePod(toCol col: Int, row: Int, duration: TimeInterval, dig: Bool) {
        isBusy = true
        let dest = cellPosition(col, row)
        let action = SKAction.move(to: dest, duration: duration)
        action.timingMode = dig ? .easeInEaseOut : .linear
        pod.run(action) { [weak self] in
            guard let self = self else { return }
            self.podCol = col
            self.podRow = row
            self.isBusy = false
            if self.hull <= 0 { self.destroyPod() }
            self.refreshHUD()
            if self.atSurface { self.saveProgress() }
        }
    }

    func removeTile(_ col: Int, _ row: Int) {
        grid[row][col] = .empty
        tileNodes[row][col]?.removeFromParent()
        tileNodes[row][col] = nil
    }

    func strand() {
        guard !respawning, !rescuing else { return }
        startRescue()
    }

    func destroyPod() {
        guard !respawning else { return }
        respawnWithMessage("💥 Pod destroyed!\nRebuilt at base — cargo lost.")
    }

    func respawnWithMessage(_ text: String) {
        respawning = true
        isBusy = true
        heldButtons.removeAll()
        updateButtonHighlights()

        cargo.removeAll()
        let label = SKLabelNode(fontNamed: font)
        label.text = text
        label.numberOfLines = 2
        label.fontSize = 22
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = 100
        label.preferredMaxLayoutWidth = size.width - 60
        uiLayer.addChild(label)

        run(.sequence([.wait(forDuration: 1.6), .run { [weak self] in
            guard let self = self else { return }
            label.removeFromParent()
            self.spawnAtBase()
            self.hull = self.maxHull
            self.fuel = self.maxFuel
            self.respawning = false
            self.isBusy = false
            self.updateCamera()
            self.refreshHUD()
            self.saveProgress()
        }]))
    }
}
