//
//  GameScene+HUD.swift
//  Space Mining
//

import SpriteKit
import UIKit

extension GameScene {

    /// Translucent top/bottom bars so the world scrolls cleanly behind the UI.
    func buildHUDChrome() {
        let w = size.width
        let fill = SKColor(red: 0.03, green: 0.045, blue: 0.12, alpha: 0.82)
        let accent = SKColor(red: 0.37, green: 0.55, blue: 1, alpha: 0.28)

        let topH = safeTop() + 92
        let top = SKShapeNode(rect: CGRect(x: -w / 2, y: size.height / 2 - topH, width: w, height: topH + 80))
        top.fillColor = fill; top.strokeColor = .clear; top.zPosition = uiZ - 5
        uiLayer.addChild(top)
        let topEdge = SKSpriteNode(color: accent, size: CGSize(width: w, height: 1.5))
        topEdge.position = CGPoint(x: 0, y: size.height / 2 - topH)
        topEdge.zPosition = uiZ - 4
        uiLayer.addChild(topEdge)

        let botH = safeBottom() + 150
        let bot = SKShapeNode(rect: CGRect(x: -w / 2, y: -size.height / 2 - 80, width: w, height: botH + 80))
        bot.fillColor = fill; bot.strokeColor = .clear; bot.zPosition = uiZ - 5
        uiLayer.addChild(bot)
        let botEdge = SKSpriteNode(color: accent, size: CGSize(width: w, height: 1.5))
        botEdge.position = CGPoint(x: 0, y: -size.height / 2 + botH)
        botEdge.zPosition = uiZ - 4
        uiLayer.addChild(botEdge)
    }

    func buildHUD() {
        let topY = size.height / 2 - safeTop() - 14

        let coin = SKSpriteNode(imageNamed: "coin")
        coin.size = CGSize(width: 24, height: 24)
        coin.position = CGPoint(x: -size.width / 2 + 26, y: topY)
        coin.zPosition = uiZ
        uiLayer.addChild(coin)

        cashLabel = SKLabelNode(fontNamed: font)
        cashLabel.fontSize = 22
        cashLabel.fontColor = SKColor(red: 1, green: 0.85, blue: 0.3, alpha: 1)
        cashLabel.horizontalAlignmentMode = .left
        cashLabel.verticalAlignmentMode = .center
        cashLabel.position = CGPoint(x: -size.width / 2 + 44, y: topY)
        cashLabel.zPosition = uiZ
        uiLayer.addChild(cashLabel)

        depthLabel = SKLabelNode(fontNamed: font)
        depthLabel.fontSize = 18
        depthLabel.fontColor = .white
        depthLabel.horizontalAlignmentMode = .right
        depthLabel.verticalAlignmentMode = .center
        depthLabel.position = CGPoint(x: size.width / 2 - 16, y: topY)
        depthLabel.zPosition = uiZ
        uiLayer.addChild(depthLabel)

        // Fuel + hull bars
        let barW = size.width * 0.42
        let barY = topY - 30
        fuelBarBG = bar(width: barW, color: SKColor(white: 0.2, alpha: 1),
                        at: CGPoint(x: -size.width / 2 + 16 + barW / 2, y: barY))
        fuelBar = bar(width: barW, color: SKColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 1),
                      at: fuelBarBG.position)
        let fuelIcon = SKSpriteNode(imageNamed: "fuel-cell")
        let fpx = fuelIcon.texture?.size() ?? CGSize(width: 260, height: 324)
        fuelIcon.size = CGSize(width: 16 * fpx.width / fpx.height, height: 16)
        fuelIcon.position = CGPoint(x: -size.width / 2 + 16 + barW / 2, y: barY + 17)
        fuelIcon.zPosition = uiZ
        uiLayer.addChild(fuelIcon)

        hullBarBG = bar(width: barW, color: SKColor(white: 0.2, alpha: 1),
                        at: CGPoint(x: size.width / 2 - 16 - barW / 2, y: barY))
        hullBar = bar(width: barW, color: SKColor(red: 0.9, green: 0.35, blue: 0.4, alpha: 1),
                      at: hullBarBG.position)
        let hullIcon = SKLabelNode(text: "🛡️"); hullIcon.fontSize = 14
        hullIcon.verticalAlignmentMode = .center
        hullIcon.position = CGPoint(x: size.width / 2 - 16 - barW / 2, y: barY + 16)
        hullIcon.zPosition = uiZ
        uiLayer.addChild(hullIcon)

        cargoLabel = SKLabelNode(fontNamed: font)
        cargoLabel.fontSize = 15
        cargoLabel.fontColor = SKColor(white: 0.9, alpha: 1)
        cargoLabel.verticalAlignmentMode = .center
        cargoLabel.position = CGPoint(x: 0, y: barY - 22)
        cargoLabel.zPosition = uiZ
        uiLayer.addChild(cargoLabel)
    }

    func bar(width: CGFloat, color: SKColor, at pos: CGPoint) -> SKShapeNode {
        let b = SKShapeNode(rectOf: CGSize(width: width, height: 12), cornerRadius: 6)
        b.fillColor = color
        b.strokeColor = .clear
        b.position = pos
        b.zPosition = uiZ
        uiLayer.addChild(b)
        return b
    }

    func refreshHUD() {
        cashLabel.text = "\(cash)"
        depthLabel.text = "⛏ \((podRow - surfaceRow) * 10)m"
        cargoLabel.text = "📦 \(cargoCount)/\(maxCargo)   value \(cargoValue)💰"

        let fW = (fuelBarBG.frame.width)
        fuelBar.xScale = CGFloat(max(0, min(1, fuel / maxFuel)))
        fuelBar.position.x = fuelBarBG.position.x - fW / 2 + fW * fuelBar.xScale / 2
        fuelBar.fillColor = fuel / maxFuel < 0.25
            ? SKColor(red: 0.95, green: 0.6, blue: 0.2, alpha: 1)
            : SKColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 1)

        let hW = hullBarBG.frame.width
        hullBar.xScale = CGFloat(max(0, min(1, hull / maxHull)))
        hullBar.position.x = hullBarBG.position.x - hW / 2 + hW * hullBar.xScale / 2

        shopButton.isHidden = !atSurface || shopOpen
    }

    func buildControls() {
        let bottomY = -size.height / 2 + safeBottom() + 56
        let r = min(tileSize * 0.95, 38)

        controlButtons[.left]  = controlButton("◀", at: CGPoint(x: -size.width / 2 + r + 14, y: bottomY), radius: r)
        controlButtons[.right] = controlButton("▶", at: CGPoint(x: -size.width / 2 + r * 3 + 26, y: bottomY), radius: r)
        controlButtons[.down]  = controlButton("🔽", at: CGPoint(x: size.width / 2 - r - 14, y: bottomY), radius: r)
        controlButtons[.up]    = controlButton("🔼", at: CGPoint(x: size.width / 2 - r * 3 - 26, y: bottomY), radius: r)

        // Shop button (centered, floating above the control row, only at surface)
        shopButton = SKNode()
        let sb = SKShapeNode(rectOf: CGSize(width: 172, height: 46), cornerRadius: 14)
        sb.fillColor = SKColor(red: 0.2, green: 0.6, blue: 0.45, alpha: 1)
        sb.strokeColor = .white
        sb.lineWidth = 2
        shopButton.addChild(sb)
        let sl = SKLabelNode(fontNamed: font)
        sl.text = "🛒 Base Shop"; sl.fontSize = 16; sl.fontColor = .white
        sl.verticalAlignmentMode = .center
        shopButton.addChild(sl)
        shopButton.position = CGPoint(x: 0, y: bottomY + 70)
        shopButton.zPosition = uiZ
        uiLayer.addChild(shopButton)
    }

    func controlButton(_ label: String, at pos: CGPoint, radius: CGFloat) -> SKShapeNode {
        let b = SKShapeNode(circleOfRadius: radius)
        b.fillColor = SKColor(white: 0.25, alpha: 0.85)
        b.strokeColor = SKColor(white: 0.7, alpha: 0.9)
        b.lineWidth = 2
        b.position = pos
        b.zPosition = uiZ
        uiLayer.addChild(b)
        let l = SKLabelNode(text: label)
        l.fontSize = radius
        l.verticalAlignmentMode = .center
        l.horizontalAlignmentMode = .center
        b.addChild(l)
        return b
    }

    func updateButtonHighlights() {
        let held = Set(heldButtons.values)
        for (dir, b) in controlButtons {
            b.fillColor = held.contains(dir)
                ? SKColor(white: 0.55, alpha: 0.95)
                : SKColor(white: 0.25, alpha: 0.85)
        }
    }
}
