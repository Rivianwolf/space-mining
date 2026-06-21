//
//  LevelSelectScene.swift
//  Space Mining
//
//  The world picker. Levels unlock in order; once completed they stay unlocked
//  and replayable. Tapping an unlocked world launches it.
//

import SpriteKit

final class LevelSelectScene: SKScene {

    private let player = PlayerState.shared
    private let font = "AvenirNext-Bold"
    private var cardLevels: [(rect: CGRect, level: LevelConfig, unlocked: Bool)] = []

    override func didMove(to view: SKView) {
        backgroundColor = hexColor(Levels.deepDig.theme.voidColor)
        let bgTex = TextureFactory(theme: Levels.deepDig.theme)
        let bg = SKSpriteNode(texture: bgTex.background(size: size))
        bg.size = size
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.zPosition = -10
        addChild(bg)

        let top = size.height - safeTop() - 40
        let title = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
        title.text = "DEEP DIG"
        title.fontSize = 44
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: top)
        addChild(title)

        let sub = SKLabelNode(fontNamed: font)
        sub.text = "Select a World"
        sub.fontSize = 16
        sub.fontColor = hexColor("#9fb0e8")
        sub.position = CGPoint(x: size.width / 2, y: top - 30)
        addChild(sub)

        layoutCards(topY: top - 78)
    }

    private func layoutCards(topY: CGFloat) {
        let cardH: CGFloat = 116
        let gap: CGFloat = 16
        let w = size.width * 0.88

        for (i, level) in Levels.all.enumerated() {
            let unlocked = player.isUnlocked(level)
            let completed = player.isCompleted(level.id)
            let cy = topY - CGFloat(i) * (cardH + gap) - cardH / 2
            let rect = CGRect(x: size.width / 2 - w / 2, y: cy - cardH / 2, width: w, height: cardH)
            cardLevels.append((rect, level, unlocked))

            let card = SKShapeNode(rect: CGRect(x: -w / 2, y: -cardH / 2, width: w, height: cardH), cornerRadius: 18)
            card.position = CGPoint(x: size.width / 2, y: cy)
            card.fillColor = unlocked ? hexColor(level.theme.skyTop).withAlphaComponent(0.9)
                                      : SKColor(white: 0.12, alpha: 0.92)
            card.strokeColor = completed ? hexColor("#62f0a8")
                              : unlocked ? .white : SKColor(white: 0.3, alpha: 1)
            card.lineWidth = completed ? 3 : 2
            addChild(card)

            // world color swatch (a little kite)
            let swatch = SKShapeNode(circleOfRadius: 22)
            swatch.fillColor = hexColor(level.theme.soilTop)
            swatch.strokeColor = hexColor(level.theme.skyGlow)
            swatch.lineWidth = 3
            swatch.position = CGPoint(x: -w / 2 + 40, y: 18)
            swatch.alpha = unlocked ? 1 : 0.4
            card.addChild(swatch)

            let name = SKLabelNode(fontNamed: font)
            name.text = unlocked ? level.name : "🔒 \(level.name)"
            name.fontSize = 22
            name.fontColor = unlocked ? .white : SKColor(white: 0.6, alpha: 1)
            name.horizontalAlignmentMode = .left
            name.verticalAlignmentMode = .center
            name.position = CGPoint(x: -w / 2 + 74, y: 26)
            card.addChild(name)

            let info = SKLabelNode(fontNamed: font)
            info.fontSize = 13
            info.horizontalAlignmentMode = .left
            info.verticalAlignmentMode = .center
            info.position = CGPoint(x: -w / 2 + 74, y: 2)
            if unlocked {
                info.text = "🎯 \(level.objective.label)"
                info.fontColor = hexColor("#cfe0ff")
            } else if case .afterLevel(let pid) = level.unlock {
                info.text = "Complete \(Levels.level(id: pid).name) to unlock"
                info.fontColor = SKColor(white: 0.6, alpha: 1)
            }
            card.addChild(info)

            let status = SKLabelNode(fontNamed: font)
            status.fontSize = 14
            status.horizontalAlignmentMode = .left
            status.verticalAlignmentMode = .center
            status.position = CGPoint(x: -w / 2 + 74, y: -22)
            if completed {
                status.text = "✓ Completed  ·  best \(player.bestDepth(level.id))m  ·  ▶ Replay"
                status.fontColor = hexColor("#62f0a8")
            } else if unlocked {
                status.text = "▶ Play"
                status.fontColor = hexColor("#5fe6ff")
            } else {
                status.text = ""
            }
            card.addChild(status)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let p = touches.first?.location(in: self) else { return }
        for entry in cardLevels where entry.unlocked && entry.rect.contains(p) {
            launch(entry.level)
            return
        }
    }

    private func launch(_ level: LevelConfig) {
        let scene = GameScene(size: size)
        scene.level = level
        scene.scaleMode = .resizeFill
        view?.presentScene(scene, transition: .doorsOpenHorizontal(withDuration: 0.4))
    }

    private func safeTop() -> CGFloat { view?.safeAreaInsets.top ?? 24 }
}
