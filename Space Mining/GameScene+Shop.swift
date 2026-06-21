//
//  GameScene+Shop.swift
//  Space Mining
//

import SpriteKit
import UIKit

extension GameScene {

    func openShop() {
        guard shopPanel == nil else { return }
        shopOpen = true
        heldButtons.removeAll()
        updateButtonHighlights()
        buildShop()
        refreshHUD()
    }

    func closeShop() {
        shopPanel?.removeFromParent()
        shopPanel = nil
        shopOpen = false
        saveProgress()
        refreshHUD()
    }

    func goToLevelSelect() {
        saveProgress()
        let menu = LevelSelectScene(size: size)
        menu.scaleMode = .resizeFill
        view?.presentScene(menu, transition: .doorsCloseHorizontal(withDuration: 0.4))
    }

    func buildShop() {
        shopPanel?.removeFromParent()
        let panel = SKNode()
        panel.zPosition = 60

        let dim = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        dim.fillColor = SKColor(white: 0, alpha: 0.8)
        dim.strokeColor = .clear
        panel.addChild(dim)

        let header = SKLabelNode(fontNamed: font)
        header.text = "🛰️ Base Shop"
        header.fontSize = 24
        header.fontColor = .white
        header.position = CGPoint(x: 0, y: size.height / 2 - safeTop() - 40)
        panel.addChild(header)

        let cashRow = SKLabelNode(fontNamed: font)
        cashRow.text = "You have 💰 \(cash)"
        cashRow.fontSize = 17
        cashRow.fontColor = SKColor(red: 1, green: 0.85, blue: 0.3, alpha: 1)
        cashRow.position = CGPoint(x: 0, y: header.position.y - 30)
        panel.addChild(cashRow)

        let rowH: CGFloat = 46
        var y = cashRow.position.y - 44

        addShopRow(panel, name: "sell_all",
                   title: "Sell cargo", detail: "+\(cargoValue) 💰",
                   enabled: cargoValue > 0, y: y, color: SKColor(red: 0.2, green: 0.5, blue: 0.7, alpha: 1)); y -= rowH

        let refuelCost = Int(ceil((maxFuel - fuel) * 2))
        addShopRow(panel, name: "refuel",
                   title: "Refuel tank", detail: refuelCost > 0 ? "\(refuelCost) 💰" : "full",
                   enabled: refuelCost > 0 && cash >= refuelCost, y: y,
                   color: SKColor(red: 0.25, green: 0.6, blue: 0.4, alpha: 1)); y -= rowH

        let repairCost = Int(ceil((maxHull - hull) * 3))
        addShopRow(panel, name: "repair",
                   title: "Repair hull", detail: repairCost > 0 ? "\(repairCost) 💰" : "full",
                   enabled: repairCost > 0 && cash >= repairCost, y: y,
                   color: SKColor(red: 0.7, green: 0.4, blue: 0.3, alpha: 1)); y -= rowH + 6

        y = addUpgradeRow(panel, name: "up_drill",  emoji: "⛏",  label: "Drill",  level: drillLevel - 1, cost: upgradeCost(drillLevel - 1, base: 130), y: y, rowH: rowH)
        y = addUpgradeRow(panel, name: "up_fuel",   emoji: "⛽️", label: "Fuel Tank", level: fuelLevel, cost: upgradeCost(fuelLevel, base: 90), y: y, rowH: rowH)
        y = addUpgradeRow(panel, name: "up_cargo",  emoji: "📦", label: "Cargo Bay", level: cargoLevel, cost: upgradeCost(cargoLevel, base: 90), y: y, rowH: rowH)
        y = addUpgradeRow(panel, name: "up_hull",   emoji: "🛡️", label: "Hull", level: hullLevel, cost: upgradeCost(hullLevel, base: 110), y: y, rowH: rowH)
        y = addUpgradeRow(panel, name: "up_engine", emoji: "🚀", label: "Engine", level: engineLevel, cost: upgradeCost(engineLevel, base: 110), y: y, rowH: rowH)

        let btnY = -size.height / 2 + safeBottom() + 40
        let levels = SKShapeNode(rectOf: CGSize(width: 150, height: 48), cornerRadius: 14)
        levels.name = "level_select"
        levels.fillColor = SKColor(red: 0.25, green: 0.3, blue: 0.55, alpha: 1)
        levels.strokeColor = .white; levels.lineWidth = 2
        levels.position = CGPoint(x: -size.width * 0.23, y: btnY)
        panel.addChild(levels)
        let ll = SKLabelNode(fontNamed: font)
        ll.text = "🪐 Worlds"; ll.fontSize = 17; ll.fontColor = .white
        ll.verticalAlignmentMode = .center; ll.name = "level_select"
        levels.addChild(ll)

        let close = SKShapeNode(rectOf: CGSize(width: 150, height: 48), cornerRadius: 14)
        close.name = "close_shop"
        close.fillColor = SKColor(red: 0.6, green: 0.25, blue: 0.3, alpha: 1)
        close.strokeColor = .white
        close.lineWidth = 2
        close.position = CGPoint(x: size.width * 0.23, y: btnY)
        panel.addChild(close)
        let cl = SKLabelNode(fontNamed: font)
        switch shopExit {
        case .resume:    cl.text = "Launch! 🚀"
        case .nextLevel: cl.text = "🚀 Next Level →"
        case .retry:     cl.text = "🔁 Retry Level →"
        }
        cl.fontSize = 16; cl.fontColor = .white
        cl.verticalAlignmentMode = .center; cl.name = "close_shop"
        close.addChild(cl)

        uiLayer.addChild(panel)
        shopPanel = panel
    }

    func upgradeCost(_ level: Int, base: Int) -> Int? {
        let maxLevel = 6
        if level >= maxLevel { return nil }
        return Int(Double(base) * pow(1.8, Double(level)))
    }

    @discardableResult
    func addShopRow(_ panel: SKNode, name: String, title: String, detail: String,
                            enabled: Bool, y: CGFloat, color: SKColor) -> SKShapeNode {
        let row = SKShapeNode(rectOf: CGSize(width: size.width * 0.9, height: 40), cornerRadius: 10)
        row.name = name
        row.fillColor = enabled ? color : SKColor(white: 0.2, alpha: 1)
        row.strokeColor = enabled ? .white : SKColor(white: 0.35, alpha: 1)
        row.lineWidth = enabled ? 2 : 1
        row.alpha = enabled ? 1 : 0.6
        row.position = CGPoint(x: 0, y: y)
        panel.addChild(row)

        let t = SKLabelNode(fontNamed: font)
        t.text = title; t.fontSize = 16; t.fontColor = .white
        t.horizontalAlignmentMode = .left; t.verticalAlignmentMode = .center
        t.position = CGPoint(x: -row.frame.width / 2 + 16, y: 0); t.name = name
        row.addChild(t)

        let d = SKLabelNode(fontNamed: font)
        d.text = detail; d.fontSize = 16; d.fontColor = .white
        d.horizontalAlignmentMode = .right; d.verticalAlignmentMode = .center
        d.position = CGPoint(x: row.frame.width / 2 - 16, y: 0); d.name = name
        row.addChild(d)
        return row
    }

    func addUpgradeRow(_ panel: SKNode, name: String, emoji: String, label: String,
                               level: Int, cost: Int?, y: CGFloat, rowH: CGFloat) -> CGFloat {
        let detail: String
        let enabled: Bool
        if let cost = cost {
            detail = "Lv\(level + 1) · \(cost) 💰"
            enabled = cash >= cost
        } else {
            detail = "MAX"
            enabled = false
        }
        addShopRow(panel, name: name, title: "\(emoji) \(label)", detail: detail,
                   enabled: enabled, y: y, color: SKColor(red: 0.35, green: 0.3, blue: 0.55, alpha: 1))
        return y - rowH
    }

    func handleShopTap(_ p: CGPoint) {
        guard let panel = shopPanel else { return }
        var tapped: String?
        for node in panel.children where node.name != nil {
            if node.frame.contains(p) { tapped = node.name; break }
        }
        guard let name = tapped else { return }

        switch name {
        case "close_shop":
            switch shopExit {
            case .resume:    closeShop()
            case .nextLevel: advanceToNextLevel()
            case .retry:     retryLevel()
            }
            return
        case "level_select": goToLevelSelect(); return
        case "sell_all":
            guard cargoValue > 0 else { return }
            cashEarned += cargoValue; cash += cargoValue; cargo.removeAll()
        case "refuel":
            let cost = Int(ceil((maxFuel - fuel) * 2))
            guard cost > 0, cash >= cost else { return }
            cash -= cost; fuel = maxFuel
        case "repair":
            let cost = Int(ceil((maxHull - hull) * 3))
            guard cost > 0, cash >= cost else { return }
            cash -= cost; hull = maxHull
        case "up_drill":  buyUpgrade(level: drillLevel - 1, base: 130) { self.drillLevel += 1 }
        case "up_fuel":   buyUpgrade(level: fuelLevel, base: 90) { self.fuelLevel += 1; self.fuel = self.maxFuel }
        case "up_cargo":  buyUpgrade(level: cargoLevel, base: 90) { self.cargoLevel += 1 }
        case "up_hull":   buyUpgrade(level: hullLevel, base: 110) { self.hullLevel += 1; self.hull = self.maxHull }
        case "up_engine": buyUpgrade(level: engineLevel, base: 110) { self.engineLevel += 1 }
        default: return
        }
        buildShop()        // rebuild with updated numbers
        refreshHUD()
    }

    func buyUpgrade(level: Int, base: Int, apply: () -> Void) {
        guard let cost = upgradeCost(level, base: base), cash >= cost else { return }
        cash -= cost
        apply()
    }
}
