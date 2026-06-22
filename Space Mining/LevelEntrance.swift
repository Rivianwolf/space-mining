//
//  LevelEntrance.swift
//  Space Mining
//
//  Per-world entrance transitions on the level map. Tapping a world plays a
//  themed dive: the chosen planet expands from the node to engulf the screen
//  (`diveExpand`), with a world-specific accent (rocks, ripples, sonar pings,
//  embers, cracks, warp stars, ring collapse + flash), then the level loads.
//  Mirrors the Deep Dig Level Map design's ENTRANCE sections.
//

import SpriteKit

extension LevelSelectScene {

    func playEntrance(for level: LevelConfig, at p: CGPoint) {
        guard !entering else { return }
        entering = true

        let overlay = SKNode()
        overlay.zPosition = 200
        addChild(overlay)

        accents(for: level, at: p, in: overlay)

        // The chosen planet dives in and expands to swallow the screen.
        let planet = SKSpriteNode(texture: art.planet(level.id))
        let d = 120 * s
        planet.size = CGSize(width: d, height: d)
        planet.position = p
        planet.zPosition = 6
        planet.setScale(0.12)
        overlay.addChild(planet)
        planet.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 5)))

        let target = (hypot(size.width, size.height) * 2.4) / d
        let expand = SKAction.scale(to: target, duration: 0.82)
        expand.timingMode = .easeIn
        planet.run(.sequence([.wait(forDuration: 0.18), expand,
                              .run { [weak self] in self?.launch(level) }]))
    }

    // MARK: Per-world accents

    private func accents(for level: LevelConfig, at p: CGPoint, in o: SKNode) {
        switch level.id {
        case "crust":     rockFall(in: o)
        case "bluestone": rings(at: p, in: o, color: hexColor("#b4f0ff"), count: 3, to: 3.4, dur: 1.0, glow: true); bubbles(at: p, in: o)
        case "echo":      rings(at: p, in: o, color: hexColor("#8cffc8"), count: 4, to: 3.6, dur: 0.9, glow: true)
        case "rift":      embers(at: p, in: o, color: hexColor("#ff8a2e"))
        case "magma":     cracks(in: o); embers(at: p, in: o, color: hexColor("#ff6a2e"))
        case "void":      warp(at: p, in: o)
        case "core":      ringsCollapse(at: p, in: o); flash(in: o)
        default:          break
        }
    }

    private func rings(at p: CGPoint, in o: SKNode, color: SKColor, count: Int, to: CGFloat, dur: TimeInterval, glow: Bool) {
        for i in 0..<count {
            let r = SKShapeNode(circleOfRadius: 50 * s)
            r.strokeColor = color; r.lineWidth = 4 * s; r.fillColor = .clear
            if glow { r.glowWidth = 4 * s }
            r.position = p; r.setScale(0.15); r.zPosition = 4
            o.addChild(r)
            r.run(.sequence([.wait(forDuration: Double(i) * 0.25),
                             .group([.scale(to: to, duration: dur), .fadeOut(withDuration: dur)]),
                             .removeFromParent()]))
        }
    }

    private func ringsCollapse(at p: CGPoint, in o: SKNode) {
        for i in 0..<3 {
            let r = SKShapeNode(circleOfRadius: 70 * s)
            r.strokeColor = hexColor("#ffaaeb"); r.lineWidth = 4 * s; r.fillColor = .clear
            r.glowWidth = 4 * s; r.position = p; r.setScale(2.8); r.alpha = 0; r.zPosition = 4
            o.addChild(r)
            r.run(.sequence([.wait(forDuration: Double(i) * 0.3),
                             .group([.scale(to: 0.2, duration: 0.7),
                                     .sequence([.fadeAlpha(to: 1, duration: 0.2), .fadeOut(withDuration: 0.5)])]),
                             .removeFromParent()]))
        }
    }

    private func bubbles(at p: CGPoint, in o: SKNode) {
        for i in 0..<5 {
            let b = SKShapeNode(circleOfRadius: CGFloat.random(in: 4...7) * s)
            b.fillColor = .white; b.alpha = 0.85; b.strokeColor = .clear
            b.position = CGPoint(x: p.x + .random(in: -40...40) * s, y: p.y - 45 * s); b.zPosition = 4
            o.addChild(b)
            b.run(.sequence([.wait(forDuration: Double(i) * 0.12),
                             .group([.moveBy(x: 0, y: 95 * s, duration: 0.9), .fadeOut(withDuration: 0.9)]),
                             .removeFromParent()]))
        }
    }

    private func embers(at p: CGPoint, in o: SKNode, color: SKColor) {
        for i in 0..<9 {
            let e = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...5) * s)
            e.fillColor = color; e.strokeColor = .clear; e.glowWidth = 4 * s
            e.position = CGPoint(x: p.x + .random(in: -30...30) * s, y: p.y); e.zPosition = 4
            o.addChild(e)
            e.run(.sequence([.wait(forDuration: Double(i) * 0.06),
                             .group([.moveBy(x: .random(in: -20...20) * s, y: .random(in: 60...110) * s, duration: 0.8),
                                     .fadeOut(withDuration: 0.8)]),
                             .removeFromParent()]))
        }
    }

    private func rockFall(in o: SKNode) {
        for i in 0..<7 {
            let sz = CGFloat.random(in: 14...28) * s
            let rock = SKShapeNode(rectOf: CGSize(width: sz, height: sz * 0.9), cornerRadius: sz * 0.32)
            rock.fillColor = hexColor("#6a5c84"); rock.strokeColor = hexColor("#3e3450"); rock.lineWidth = 2
            rock.position = CGPoint(x: .random(in: 0...size.width), y: size.height + 30); rock.zPosition = 4
            o.addChild(rock)
            rock.run(.sequence([.wait(forDuration: Double(i) * 0.08),
                                .group([.moveBy(x: 0, y: -(size.height + 80), duration: 0.95),
                                        .rotate(byAngle: .random(in: -3...3), duration: 0.95)]),
                                .removeFromParent()]))
        }
    }

    private func cracks(in o: SKNode) {
        let xs: [CGFloat] = [0.22, 0.46, 0.70, 0.86]
        for (i, fx) in xs.enumerated() {
            let line = SKSpriteNode(color: hexColor("#ff5a1e"), size: CGSize(width: 4 * s, height: size.height))
            line.anchorPoint = CGPoint(x: 0.5, y: 1)
            line.position = CGPoint(x: size.width * fx, y: size.height); line.zPosition = 4
            line.yScale = 0; line.alpha = 0
            o.addChild(line)
            line.run(.sequence([.wait(forDuration: Double(i) * 0.1),
                                .group([.scaleY(to: 1, duration: 0.45), .fadeAlpha(to: 0.9, duration: 0.2)]),
                                .fadeOut(withDuration: 0.4), .removeFromParent()]))
        }
    }

    private func warp(at p: CGPoint, in o: SKNode) {
        for i in 0..<22 {
            let a = CGFloat.random(in: 0...(2 * .pi))
            let star = SKShapeNode(circleOfRadius: 1.6 * s)
            star.fillColor = .white; star.strokeColor = .clear
            star.position = p; star.zPosition = 4
            o.addChild(star)
            let dist = CGFloat.random(in: 120...340) * s
            star.run(.sequence([.wait(forDuration: Double(i) * 0.02),
                                .group([.move(to: CGPoint(x: p.x + cos(a) * dist, y: p.y + sin(a) * dist), duration: 0.6),
                                        .scale(to: 3.5, duration: 0.6), .fadeOut(withDuration: 0.6)]),
                                .removeFromParent()]))
        }
    }

    private func flash(in o: SKNode) {
        let f = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        f.fillColor = .white; f.strokeColor = .clear; f.alpha = 0; f.zPosition = 5; f.blendMode = .add
        o.addChild(f)
        f.run(.sequence([.wait(forDuration: 0.5), .fadeAlpha(to: 0.85, duration: 0.3)]))
    }
}
