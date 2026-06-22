//
//  LevelSelectScene.swift
//  Space Mining
//
//  "Choose Your Dig" — the level map. All seven worlds shown on one screen
//  along a winding path, each a distinct planet (completed = gold ring + stars,
//  current = white ring + pulse + PLAY, locked = padlock). Drifting background
//  planets, twinkling stars, and a saucer-alien mascot. Matches the Deep Dig
//  Level Map design (390×960 canvas, scaled to fit).
//

import SpriteKit
import UIKit

final class LevelSelectScene: SKScene {

    private let player = PlayerState.shared
    let art = LevelMapArt()
    private let font = "AvenirNext-Bold"

    var entering = false                        // an entrance transition is playing
    var s: CGFloat = 1                          // design→screen scale
    private struct Hit { let level: LevelConfig; let p: CGPoint; let r: CGFloat; let unlocked: Bool }
    private var hits: [Hit] = []

    // design-canvas node positions (x, y) top-left origin, 390×960
    private let pos: [(CGFloat, CGFloat)] = [
        (250, 865), (150, 745), (320, 625), (160, 500), (330, 375), (150, 255), (250, 135)
    ]

    override func didMove(to view: SKView) {
        backgroundColor = hexColor("#06091a")
        s = min(size.width / 480, size.height / 960)   // design canvas is 480×960
        buildBackground()
        buildPath()
        buildNodes()
        buildSaucer()
        buildHeader()
    }

    /// design point → screen point (y flipped to bottom-left origin)
    func P(_ dx: CGFloat, _ dy: CGFloat) -> CGPoint {
        CGPoint(x: size.width / 2 + (dx - 240) * s, y: size.height / 2 + (480 - dy) * s)
    }

    // MARK: Background

    private func buildBackground() {
        let bg = SKSpriteNode(color: .clear, size: size)
        bg.texture = bgTexture(); bg.size = size
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2); bg.zPosition = -20
        addChild(bg)

        // drifting background planets (design positions)
        let bgPlanets: [(String, CGFloat, CGFloat, CGFloat)] = [
            ("gas", 22, 184, 152), ("ice", 384, 602, 108), ("red", 6, 834, 84), ("home", 317, 97, 78)
        ]
        for (id, dx, dy, dia) in bgPlanets {
            let sp = SKSpriteNode(texture: art.bgPlanet(id))
            let d = dia * s * 1.28
            sp.size = CGSize(width: d, height: d)
            sp.position = P(dx, dy); sp.zPosition = -10; sp.alpha = 0.62
            if id == "gas" || id == "home" { addRing(sp, radius: dia * s * 0.5, color: hexColor("#9fb6ff").withAlphaComponent(0.4), rot: -0.32) }
            sp.run(.repeatForever(.sequence([.moveBy(x: 14 * s, y: -10 * s, duration: 12),
                                             .moveBy(x: -14 * s, y: 10 * s, duration: 12)])))
            addChild(sp)
        }
    }

    private func bgTexture() -> SKTexture {
        let fmt = UIGraphicsImageRendererFormat.default(); fmt.scale = 1; fmt.opaque = true
        let img = UIGraphicsImageRenderer(size: size, format: fmt).image { ctx in
            let c = ctx.cgContext, cs = CGColorSpaceCreateDeviceRGB()
            if let g = CGGradient(colorsSpace: cs, colors: [hexColor("#0e1740").cgColor, hexColor("#05060f").cgColor] as CFArray, locations: [0, 0.7]) {
                c.drawRadialGradient(g, startCenter: CGPoint(x: size.width / 2, y: size.height),
                                     startRadius: 0, endCenter: CGPoint(x: size.width / 2, y: size.height),
                                     endRadius: size.height, options: [.drawsAfterEndLocation])
            }
            for _ in 0..<70 {
                let r = CGFloat.random(in: 0.5...1.7)
                c.setFillColor(UIColor(white: 1, alpha: .random(in: 0.2...0.9)).cgColor)
                c.fillEllipse(in: CGRect(x: .random(in: 0...size.width), y: .random(in: 0...size.height), width: 2 * r, height: 2 * r))
            }
        }
        return SKTexture(image: img)
    }

    private func addRing(_ node: SKNode, radius: CGFloat, color: SKColor, rot: CGFloat) {
        let ring = SKShapeNode(ellipseOf: CGSize(width: radius * 3.1, height: radius * 0.92))
        ring.strokeColor = color; ring.lineWidth = max(2, 4 * s); ring.fillColor = .clear
        ring.zRotation = rot; ring.zPosition = -0.5
        node.addChild(ring)
    }

    // MARK: Path

    private func buildPath() {
        // Curved "candy" Bézier trail through the node centers (design path data),
        // dotted beads; the traveled portion (up to the current stop) glows cyan.
        let seg: [(CGPoint, CGPoint, CGPoint, CGPoint)] = [
            (P(250, 865), P(250, 820), P(150, 790), P(150, 745)),
            (P(150, 745), P(150, 700), P(320, 670), P(320, 625)),
            (P(320, 625), P(320, 580), P(160, 545), P(160, 500)),
            (P(160, 500), P(160, 455), P(330, 420), P(330, 375)),
            (P(330, 375), P(330, 330), P(150, 300), P(150, 255)),
            (P(150, 255), P(150, 210), P(250, 180), P(250, 135))
        ]
        let curIdx = Levels.all.firstIndex { $0.id == currentLevel?.id } ?? Levels.all.count - 1

        let fmt = UIGraphicsImageRendererFormat.default(); fmt.scale = 2; fmt.opaque = false
        let img = UIGraphicsImageRenderer(size: size, format: fmt).image { rc in
            let ctx = rc.cgContext
            ctx.setLineCap(.round)
            let dash: [CGFloat] = [2 * s, 15 * s]
            func stroke(_ count: Int, _ color: UIColor, glow: Bool) {
                let path = CGMutablePath()
                path.move(to: seg[0].0)
                for i in 0..<count { path.addCurve(to: seg[i].3, control1: seg[i].1, control2: seg[i].2) }
                if glow { ctx.setShadow(offset: .zero, blur: 6 * s, color: color.cgColor) }
                ctx.addPath(path); ctx.setStrokeColor(color.cgColor)
                ctx.setLineWidth(7 * s); ctx.setLineDash(phase: 0, lengths: dash); ctx.strokePath()
                ctx.setShadow(offset: .zero, blur: 0, color: nil)
            }
            stroke(seg.count, hexColor("#96aaff").withAlphaComponent(0.28), glow: false)   // full faint trail
            if curIdx > 0 { stroke(curIdx, hexColor("#5fe6ff"), glow: true) }              // traveled glow
        }
        let trail = SKSpriteNode(texture: SKTexture(image: img))
        trail.size = size; trail.position = CGPoint(x: size.width / 2, y: size.height / 2)
        trail.zPosition = 0
        addChild(trail)
    }

    // MARK: Nodes

    private var currentLevel: LevelConfig? {
        Levels.all.first { player.isUnlocked($0) && !player.isCompleted($0.id) }
    }

    private func buildNodes() {
        let current = currentLevel
        for (i, level) in Levels.all.enumerated() {
            addNode(level, index: i + 1, design: pos[i], isCurrent: level.id == current?.id)
        }
    }

    private func addNode(_ level: LevelConfig, index: Int, design: (CGFloat, CGFloat), isCurrent: Bool) {
        let unlocked = player.isUnlocked(level)
        let completed = player.isCompleted(level.id)
        let dia = (isCurrent ? 82.0 : (level.isBoss ? 88.0 : (unlocked ? 64.0 : 60.0))) * s
        let R = dia / 2

        let node = SKNode()
        node.position = P(design.0, design.1); node.zPosition = 5
        addChild(node)
        hits.append(Hit(level: level, p: node.position, r: R + 12 * s, unlocked: unlocked))

        // Saturn rings for ocean/boss worlds
        if level.id == "bluestone" { addRing(node, radius: R, color: hexColor("#96d2ff").withAlphaComponent(0.55), rot: -0.35) }
        if level.id == "core" { addRing(node, radius: R, color: hexColor("#c896ff").withAlphaComponent(0.5), rot: -0.28) }

        if isCurrent { addPulseRings(node, R: R) }

        // planet
        let planet = SKSpriteNode(texture: art.planet(level.id))
        planet.size = CGSize(width: dia * 1.3, height: dia * 1.3)
        node.addChild(planet)

        if !unlocked {
            let shade = SKShapeNode(circleOfRadius: R)
            shade.fillColor = SKColor(red: 0.04, green: 0.05, blue: 0.12, alpha: 0.45); shade.strokeColor = .clear
            node.addChild(shade)
        }

        // border
        let border = SKShapeNode(circleOfRadius: R)
        border.fillColor = .clear; border.lineWidth = max(2.5, 4 * s)
        border.strokeColor = completed ? hexColor("#ffd574")
                           : isCurrent ? .white
                           : hexColor(level.nodeTint).withAlphaComponent(0.45)
        node.addChild(border)

        // center content
        if !unlocked {
            addLockBadge(node, R: R)
        } else if isCurrent {
            let glyph = SKSpriteNode(imageNamed: "drill-pod")
            glyph.size = CGSize(width: dia * 0.5, height: dia * 0.58)
            node.addChild(glyph)
        } else {
            let num = SKLabelNode(fontNamed: font)
            num.text = "\(index)"; num.fontSize = 24 * s; num.fontColor = .white
            num.verticalAlignmentMode = .center; num.horizontalAlignmentMode = .center
            node.addChild(num)
        }

        if completed { addStars(node, player.stars(level.id), y: R + (level.isBoss ? 30 : 18) * s) }
        if level.id == "crust" && completed { addMoon(node, R: R) }
        if level.isBoss { addBossTag(node, R: R) }
        if isCurrent { addPlayButton(node, R: R) }

        // label
        let label = SKLabelNode(fontNamed: font)
        label.text = isCurrent ? "\(level.name) · NOW" : level.name
        label.fontSize = 13 * s
        label.fontColor = isCurrent ? hexColor("#ffd574")
                        : unlocked ? hexColor("#cfe0ff") : hexColor("#9a8aad")
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: -R - 18 * s)
        node.addChild(label)
    }

    private func addPulseRings(_ node: SKNode, R: CGFloat) {
        for delay in [0.0, 0.9] {
            let ring = SKShapeNode(circleOfRadius: R + 6 * s)
            ring.strokeColor = hexColor("#ffd574"); ring.lineWidth = 3 * s; ring.fillColor = .clear
            ring.alpha = 0
            ring.run(.repeatForever(.sequence([
                .wait(forDuration: delay),
                .run { ring.setScale(1); ring.alpha = 0.8 },
                .group([.scale(to: 1.7, duration: 1.8), .fadeOut(withDuration: 1.8)]),
                .wait(forDuration: 1.8 - delay)
            ])))
            node.addChild(ring)
        }
    }

    private func addStars(_ node: SKNode, _ count: Int, y: CGFloat) {
        let row = SKNode(); row.position = CGPoint(x: 0, y: y)
        let gap: CGFloat = 16 * s
        for i in 0..<3 {
            let star = SKLabelNode(text: "⭐️")
            star.fontSize = (i == 1 ? 17 : 14) * s
            star.verticalAlignmentMode = .center
            star.position = CGPoint(x: CGFloat(i - 1) * gap, y: i == 1 ? 2 * s : 0)
            star.alpha = i < count ? 1 : 0.28
            row.addChild(star)
        }
        node.addChild(row)
    }

    private func addMoon(_ node: SKNode, R: CGFloat) {
        let orbit = SKNode()
        let moon = SKShapeNode(circleOfRadius: 6 * s)
        moon.fillColor = hexColor("#dbe2f3"); moon.strokeColor = .clear
        moon.position = CGPoint(x: 0, y: R + 10 * s)
        orbit.addChild(moon)
        orbit.run(.repeatForever(.rotate(byAngle: -2 * .pi, duration: 13)))
        node.addChild(orbit)
    }

    private func addBossTag(_ node: SKNode, R: CGFloat) {
        let tag = SKShapeNode(rectOf: CGSize(width: 50 * s, height: 18 * s), cornerRadius: 7 * s)
        tag.fillColor = hexColor("#7a4fd6"); tag.strokeColor = .clear
        tag.position = CGPoint(x: R * 0.7, y: R * 0.7)
        let t = SKLabelNode(fontNamed: font)
        t.text = "BOSS"; t.fontSize = 10 * s; t.fontColor = .white; t.verticalAlignmentMode = .center
        tag.addChild(t); node.addChild(tag)
    }

    private func addLockBadge(_ node: SKNode, R: CGFloat) {
        let badge = SKShapeNode(circleOfRadius: 12 * s)
        badge.fillColor = hexColor("#222a4e"); badge.strokeColor = hexColor("#475184"); badge.lineWidth = 2 * s
        badge.position = CGPoint(x: R * 0.7, y: -R * 0.7)
        let lock = SKLabelNode(text: "🔒"); lock.fontSize = 13 * s; lock.verticalAlignmentMode = .center
        badge.addChild(lock); node.addChild(badge)
    }

    private func addPlayButton(_ node: SKNode, R: CGFloat) {
        let btn = SKShapeNode(rectOf: CGSize(width: 92 * s, height: 32 * s), cornerRadius: 13 * s)
        btn.fillColor = hexColor("#ffb347"); btn.strokeColor = hexColor("#ffe2a0"); btn.lineWidth = 1.5 * s
        btn.position = CGPoint(x: 0, y: -R - 40 * s)
        let l = SKLabelNode(fontNamed: font)
        l.text = "PLAY ▶"; l.fontSize = 14 * s; l.fontColor = hexColor("#5a2c05"); l.verticalAlignmentMode = .center
        btn.addChild(l); node.addChild(btn)
    }

    // MARK: Mascot

    private func buildSaucer() {
        let saucer = SKSpriteNode(texture: art.saucer())
        saucer.size = CGSize(width: 120 * s, height: 90 * s)
        saucer.zPosition = -4
        let y = P(0, 233).y
        let bob = SKNode(); bob.position = CGPoint(x: 0, y: y)
        addChild(bob)
        bob.addChild(saucer)
        saucer.run(.repeatForever(.sequence([.moveBy(x: 0, y: 8 * s, duration: 1.6),
                                             .moveBy(x: 0, y: -8 * s, duration: 1.6)])))
        bob.position.x = -60
        bob.run(.repeatForever(.sequence([
            .moveTo(x: size.width + 60, duration: 15),
            .moveTo(x: -60, duration: 0)
        ])))
    }

    // MARK: Header

    private func buildHeader() {
        let barH = safeTop() + 56
        let bar = SKSpriteNode(color: hexColor("#070a1c").withAlphaComponent(0.85), size: CGSize(width: size.width, height: barH))
        bar.anchorPoint = CGPoint(x: 0.5, y: 1)
        bar.position = CGPoint(x: size.width / 2, y: size.height); bar.zPosition = 100
        addChild(bar)

        let y = size.height - safeTop() - 22

        let back = SKShapeNode(rectOf: CGSize(width: 40, height: 40), cornerRadius: 13)
        back.fillColor = hexColor("#070b1e").withAlphaComponent(0.6); back.strokeColor = hexColor("#96aaff").withAlphaComponent(0.22)
        back.position = CGPoint(x: 32, y: y); back.zPosition = 101
        let chev = SKLabelNode(fontNamed: font); chev.text = "‹"; chev.fontSize = 24; chev.fontColor = hexColor("#cfe0ff")
        chev.verticalAlignmentMode = .center; back.addChild(chev)
        addChild(back)

        let title = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
        title.text = "Choose Your Dig"; title.fontSize = 23; title.fontColor = hexColor("#eafcff")
        title.position = CGPoint(x: size.width / 2, y: y - 7); title.zPosition = 101
        addChild(title)

        let coin = SKSpriteNode(imageNamed: "coin"); coin.size = CGSize(width: 22, height: 22)
        coin.position = CGPoint(x: size.width - 92, y: y); coin.zPosition = 101; addChild(coin)
        let cash = SKLabelNode(fontNamed: font); cash.text = "\(player.cash)"; cash.fontSize = 16
        cash.fontColor = hexColor("#ffd574"); cash.horizontalAlignmentMode = .left; cash.verticalAlignmentMode = .center
        cash.position = CGPoint(x: size.width - 74, y: y); cash.zPosition = 101; addChild(cash)
    }

    // MARK: Taps

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !entering, let p = touches.first?.location(in: self) else { return }
        for h in hits where h.unlocked {
            if hypot(p.x - h.p.x, p.y - h.p.y) <= h.r + 24 { playEntrance(for: h.level, at: h.p); return }
        }
    }

    func launch(_ level: LevelConfig) {
        let scene = GameScene(size: size)
        scene.level = level
        scene.scaleMode = .resizeFill
        view?.presentScene(scene, transition: .doorsOpenHorizontal(withDuration: 0.4))
    }

    private func safeTop() -> CGFloat { view?.safeAreaInsets.top ?? 24 }
}
