//
//  GameScene+Rescue.swift
//  Space Mining
//
//  Out-of-fuel rescue: a tow-drone descends the dug shaft, magnet-clamps the
//  stranded pod, and hauls it back up to the surface, then ends the run with a
//  rescue modal (buy upgrades / retry / worlds). Cargo is the tow fee.
//  Mirrors the "Deep Dig Rescue Tow" design cutscene.
//

import SpriteKit

extension GameScene {

    private var red: SKColor { hexColor("#ff6b6b") }
    private var cyan: SKColor { hexColor("#5fe6ff") }
    private var amber: SKColor { hexColor("#ffb451") }
    private var green: SKColor { hexColor("#62f0a8") }

    // MARK: Sequence

    func startRescue() {
        rescuing = true
        isBusy = true
        heldButtons.removeAll(); updateButtonHighlights()
        pod.removeAllActions()        // cancel any in-flight dig + its completion
        cargo.removeAll()             // the haul is the rescue fee
        refreshHUD()

        // red distress light blinking on the pod
        let distress = SKShapeNode(circleOfRadius: tileSize * 0.1)
        distress.name = "distress"
        distress.fillColor = red; distress.strokeColor = .clear
        distress.glowWidth = tileSize * 0.1
        distress.position = CGPoint(x: 0, y: tileSize * 0.55)
        distress.zPosition = 1
        distress.run(.repeatForever(.sequence([.fadeAlpha(to: 0.15, duration: 0.25),
                                               .fadeAlpha(to: 1, duration: 0.25)])))
        pod.addChild(distress)

        showRescueCaption("📡 DISTRESS BEACON", "Out of fuel · \(maxDepthMeters)m", red)

        // tow-drone drops in from above and descends the shaft to the pod
        let drone = SKSpriteNode(imageNamed: "tow-drone")
        let dpx = drone.texture?.size() ?? CGSize(width: 300, height: 300)
        let dW = tileSize * 2.4
        drone.size = CGSize(width: dW, height: dW * dpx.height / dpx.width)
        drone.zPosition = 6
        drone.position = CGPoint(x: pod.position.x,
                                 y: cameraNode.position.y + size.height / 2 + tileSize * 2)
        addChild(drone)

        let descend = SKAction.move(to: CGPoint(x: pod.position.x, y: pod.position.y + tileSize * 2.3),
                                    duration: 1.3)
        descend.timingMode = .easeInEaseOut
        drone.run(.sequence([
            .wait(forDuration: 0.7),
            .run { [weak self] in self?.showRescueCaption("🛸 TOW-DRONE INBOUND", "Descending the shaft", self?.cyan ?? .cyan) },
            descend,
            .run { [weak self] in self?.rescueClampAndHaul(drone: drone) }
        ]))
    }

    private func rescueClampAndHaul(drone: SKSpriteNode) {
        showRescueCaption("🧲 CLAMP LOCKED", "Magnet engaged", amber)

        // clamp impact flash on the pod
        let flash = SKShapeNode(circleOfRadius: tileSize * 0.5)
        flash.fillColor = .white; flash.strokeColor = .clear; flash.blendMode = .add
        flash.position = CGPoint(x: pod.position.x, y: pod.position.y + tileSize * 0.4)
        flash.zPosition = 7
        addChild(flash)
        flash.run(.sequence([.group([.scale(to: 2, duration: 0.25), .fadeOut(withDuration: 0.25)]),
                             .removeFromParent()]))

        // cable strung between drone and pod (they now move in lockstep)
        let podTopY = pod.position.y + tileSize * 0.5
        let droneBotY = drone.position.y - drone.size.height * 0.35
        let cable = SKSpriteNode(color: hexColor("#7a86b4"),
                                 size: CGSize(width: 3, height: max(2, droneBotY - podTopY)))
        cable.position = CGPoint(x: pod.position.x, y: (podTopY + droneBotY) / 2)
        cable.zPosition = 5
        addChild(cable)

        // haul everyone straight up to the surface, in sync
        let rise = cellPosition(podCol, surfaceRow).y - pod.position.y
        let dur = min(3.0, max(1.4, abs(rise) / (tileSize * 18)))
        let up = SKAction.moveBy(x: 0, y: rise, duration: dur)
        up.timingMode = .easeInEaseOut

        run(.sequence([.wait(forDuration: 0.4),
                       .run { [weak self] in self?.showRescueCaption("⬆️ HAULING TO BASE", "Hang tight, miner", self?.cyan ?? .cyan) }]))
        pod.run(up)
        cable.run(up)
        drone.run(.sequence([up, .run { [weak self] in self?.rescueArrived(drone: drone, cable: cable) }]))
    }

    private func rescueArrived(drone: SKSpriteNode, cable: SKSpriteNode) {
        podRow = surfaceRow
        pod.childNode(withName: "distress")?.removeFromParent()
        cable.removeFromParent()
        drone.run(.sequence([.group([.moveBy(x: 0, y: tileSize * 4, duration: 0.7),
                                     .fadeOut(withDuration: 0.7)]),
                             .removeFromParent()]))
        arrivalSparkle(at: pod.position)
        showRescueCaption("✨ RESCUED!", "Welcome home", green)
        refreshHUD()
        run(.sequence([.wait(forDuration: 1.1), .run { [weak self] in self?.showRescueModal() }]))
    }

    private func arrivalSparkle(at point: CGPoint) {
        for i in 0..<14 {
            let a = CGFloat(i) / 14 * 2 * .pi
            let s = SKShapeNode(circleOfRadius: tileSize * 0.08)
            s.fillColor = i % 2 == 0 ? green : cyan
            s.strokeColor = .clear; s.blendMode = .add
            s.position = point; s.zPosition = 8
            addChild(s)
            let d = tileSize * 2
            s.run(.sequence([.group([.moveBy(x: cos(a) * d, y: sin(a) * d, duration: 0.6),
                                     .fadeOut(withDuration: 0.6), .scale(to: 0.2, duration: 0.6)]),
                             .removeFromParent()]))
        }
    }

    // MARK: Caption + modal

    func showRescueCaption(_ title: String, _ sub: String, _ color: SKColor) {
        uiLayer.childNode(withName: "rescueCaption")?.removeFromParent()
        let node = SKNode()
        node.name = "rescueCaption"
        node.zPosition = uiZ + 10
        node.position = CGPoint(x: 0, y: size.height * 0.26)

        let pill = SKShapeNode(rectOf: CGSize(width: size.width * 0.78, height: 56), cornerRadius: 18)
        pill.fillColor = SKColor(red: 0.03, green: 0.045, blue: 0.12, alpha: 0.85)
        pill.strokeColor = color.withAlphaComponent(0.55); pill.lineWidth = 1.5
        node.addChild(pill)

        let t = SKLabelNode(fontNamed: font)
        t.text = title; t.fontSize = 19; t.fontColor = color
        t.verticalAlignmentMode = .center; t.position = CGPoint(x: 0, y: 8)
        node.addChild(t)

        let s = SKLabelNode(fontNamed: font)
        s.text = sub.uppercased(); s.fontSize = 10; s.fontColor = hexColor("#9fb0e8")
        s.verticalAlignmentMode = .center; s.position = CGPoint(x: 0, y: -13)
        node.addChild(s)

        uiLayer.addChild(node)
        node.alpha = 0
        node.run(.fadeIn(withDuration: 0.2))
    }

    func showRescueModal() {
        guard completionPanel == nil else { return }
        rescuing = false                                   // modal now guards the loop
        uiLayer.childNode(withName: "rescueCaption")?
            .run(.sequence([.fadeOut(withDuration: 0.3), .removeFromParent()]))

        let panel = SKNode()
        panel.zPosition = uiZ + 20

        let dim = SKShapeNode(rect: CGRect(x: -size.width / 2, y: -size.height / 2,
                                           width: size.width, height: size.height))
        dim.fillColor = SKColor(white: 0, alpha: 0.78); dim.strokeColor = .clear
        panel.addChild(dim)

        let card = SKShapeNode(rectOf: CGSize(width: size.width * 0.82, height: 384), cornerRadius: 24)
        card.fillColor = SKColor(red: 0.06, green: 0.07, blue: 0.16, alpha: 1)
        card.strokeColor = red.withAlphaComponent(0.5); card.lineWidth = 2
        panel.addChild(card)

        let emoji = SKLabelNode(text: "⛽️"); emoji.fontSize = 46; emoji.verticalAlignmentMode = .center
        emoji.position = CGPoint(x: 0, y: 130); panel.addChild(emoji)

        let title = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
        title.text = "OUT OF FUEL"; title.fontSize = 30; title.fontColor = red
        title.position = CGPoint(x: 0, y: 80); panel.addChild(title)

        let sub = SKLabelNode(fontNamed: font)
        sub.text = "Rescued by tow-drone · reached \(maxDepthMeters)m"
        sub.fontSize = 14; sub.fontColor = SKColor(white: 0.85, alpha: 1)
        sub.position = CGPoint(x: 0, y: 50); panel.addChild(sub)

        let fee = SKLabelNode(fontNamed: font)
        fee.text = "Cargo handed over as the tow fee"
        fee.fontSize = 12; fee.fontColor = hexColor("#9fb0e8")
        fee.position = CGPoint(x: 0, y: 30); panel.addChild(fee)

        panel.addChild(popupButton("🛒  Buy Upgrades", name: "rescue_upgrades",
                                    color: SKColor(red: 0.2, green: 0.6, blue: 0.45, alpha: 1), y: -24))
        panel.addChild(popupButton("🔁  Retry Level", name: "cp_retry",
                                    color: SKColor(red: 0.25, green: 0.45, blue: 0.85, alpha: 1), y: -88))
        panel.addChild(popupButton("🪐  Worlds", name: "cp_worlds",
                                    color: SKColor(white: 0.32, alpha: 1), y: -152))

        uiLayer.addChild(panel)
        completionPanel = panel
        card.setScale(0.5); card.alpha = 0
        card.run(.group([.scale(to: 1, duration: 0.3), .fadeIn(withDuration: 0.3)]))
    }
}
