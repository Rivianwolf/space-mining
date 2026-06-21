//
//  GameScene+Effects.swift
//  Space Mining
//

import SpriteKit
import UIKit

extension GameScene {

    func spawnFloatingText(_ text: String, at point: CGPoint, color: SKColor) {
        let l = SKLabelNode(fontNamed: font)
        l.text = text; l.fontSize = 18; l.fontColor = color
        l.position = point; l.zPosition = 30
        addChild(l)
        l.run(.sequence([.group([.moveBy(x: 0, y: 40, duration: 0.6), .fadeOut(withDuration: 0.6)]),
                         .removeFromParent()]))
    }

    /// The pod shudders rapidly side-to-side while cutting (Deep Dig style).
    func startDrill(duration: TimeInterval) {
        guard let bit = podSprite else { return }
        bit.removeAction(forKey: "vib")
        let amp = tileSize * 0.035
        let v = SKAction.sequence([.moveBy(x: amp, y: 0, duration: 0.018),
                                   .moveBy(x: -2 * amp, y: 0, duration: 0.036),
                                   .moveBy(x: amp, y: 0, duration: 0.018)])
        bit.run(.sequence([.repeat(v, count: max(2, Int(duration / 0.072))),
                           .run { [weak bit] in bit?.position.x = 0 }]), withKey: "vib")
    }

    /// Rumbles the whole pod while drilling — harder tiles shake more.
    func drillWobble(duration: TimeInterval, toughness: Double) {
        let amp = min(0.05, 0.02 + toughness * 0.008)
        pod.removeAction(forKey: "wob")
        pod.run(.repeat(.sequence([.rotate(toAngle: amp, duration: 0.04),
                                   .rotate(toAngle: -amp, duration: 0.08),
                                   .rotate(toAngle: 0, duration: 0.04)]),
                        count: max(1, Int(duration / 0.16))), withKey: "wob")
    }

    func debrisColor(_ kind: TileKind) -> SKColor {
        switch kind {
        case .rock: return SKColor(red: 0.40, green: 0.41, blue: 0.46, alpha: 1)
        case .lava: return SKColor(red: 1.0, green: 0.5, blue: 0.15, alpha: 1)
        default:    return SKColor(red: 0.50, green: 0.35, blue: 0.24, alpha: 1)
        }
    }

    /// Chunks of debris fly out of the cut, biased away from the dig direction.
    func spawnDigDebris(at point: CGPoint, kind: TileKind, toward dir: Direction) {
        let col = debrisColor(kind)
        let eject: CGFloat
        switch dir {
        case .down:  eject = .pi / 2     // up, back at the pod
        case .left:  eject = 0           // to the right
        case .right: eject = .pi         // to the left
        case .up:    eject = -.pi / 2
        }
        for _ in 0..<8 {
            let r = CGFloat.random(in: 2...4.5)
            let chunk = SKShapeNode(rectOf: CGSize(width: r * 1.6, height: r * 1.6), cornerRadius: 1.2)
            chunk.fillColor = col.withAlphaComponent(CGFloat.random(in: 0.7...1))
            chunk.strokeColor = .clear
            chunk.position = point; chunk.zPosition = 6
            chunk.zRotation = CGFloat.random(in: 0...3)
            addChild(chunk)
            let ang = eject + CGFloat.random(in: -0.9...0.9)
            let dist = CGFloat.random(in: 14...38)
            chunk.run(.sequence([.group([.moveBy(x: cos(ang) * dist, y: sin(ang) * dist + 8, duration: 0.4),
                                         .rotate(byAngle: CGFloat.random(in: -4...4), duration: 0.4),
                                         .fadeOut(withDuration: 0.4)]),
                                 .removeFromParent()]))
        }
        if case .ore(let o) = kind {
            for _ in 0..<5 {
                let sp = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...2.6))
                sp.fillColor = o.color; sp.strokeColor = .clear; sp.blendMode = .add
                sp.position = point; sp.zPosition = 7
                addChild(sp)
                let a = CGFloat.random(in: 0...(2 * .pi)), d = CGFloat.random(in: 10...30)
                sp.run(.sequence([.group([.moveBy(x: cos(a) * d, y: sin(a) * d, duration: 0.45),
                                          .fadeOut(withDuration: 0.45)]), .removeFromParent()]))
            }
        }
    }

    /// Soft purple dust puffs kicked up by the drill.
    func spawnDust(at point: CGPoint) {
        let purples = [SKColor(red: 0.42, green: 0.37, blue: 0.53, alpha: 1),
                       SKColor(red: 0.35, green: 0.31, blue: 0.47, alpha: 1)]
        for _ in 0..<5 {
            let d = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...6))
            d.fillColor = purples.randomElement()!
            d.strokeColor = .clear; d.alpha = 0.85
            d.position = point; d.zPosition = 5.5
            addChild(d)
            let dir: CGFloat = Bool.random() ? 1 : -1
            d.run(.sequence([.group([.moveBy(x: dir * CGFloat.random(in: 8...26),
                                             y: CGFloat.random(in: 6...22), duration: 0.5),
                                     .scale(to: 0.3, duration: 0.5),
                                     .fadeOut(withDuration: 0.5)]),
                             .removeFromParent()]))
        }
    }

    /// A quick additive flash where the drill bites the tile.
    func spawnSpark(at point: CGPoint) {
        let f = SKShapeNode(circleOfRadius: tileSize * 0.16)
        f.fillColor = SKColor(red: 1, green: 0.95, blue: 0.7, alpha: 0.9)
        f.strokeColor = .clear; f.blendMode = .add
        f.position = point; f.zPosition = 8
        addChild(f)
        f.run(.sequence([.group([.scale(to: 2.0, duration: 0.16), .fadeOut(withDuration: 0.16)]),
                         .removeFromParent()]))
    }

    func flashBanner(_ text: String) {
        banner?.removeFromParent()
        let l = SKLabelNode(fontNamed: font)
        l.text = text; l.fontSize = 18; l.fontColor = SKColor(red: 1, green: 0.7, blue: 0.4, alpha: 1)
        l.verticalAlignmentMode = .center
        l.position = CGPoint(x: 0, y: -size.height / 2 + safeBottom() + 175)
        l.zPosition = uiZ + 5
        uiLayer.addChild(l)
        banner = l
        l.run(.sequence([.wait(forDuration: 0.9), .fadeOut(withDuration: 0.3), .removeFromParent()]))
    }

    func screenFlash(_ color: SKColor) {
        let f = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        f.fillColor = color; f.strokeColor = .clear; f.zPosition = uiZ + 40
        uiLayer.addChild(f)
        f.run(.sequence([.fadeOut(withDuration: 0.3), .removeFromParent()]))
    }
}
