//
//  GameScene+World.swift
//  Space Mining
//

import SpriteKit
import UIKit

extension GameScene {

    func buildBackground() {
        let bg = SKSpriteNode(texture: tex.background(size: size))
        bg.size = size
        bg.zPosition = -30
        cameraNode.addChild(bg)
    }

    /// Edge-darkening overlay above the terrain but below the pod and HUD.
    func buildVignette() {
        let vig = SKSpriteNode(texture: tex.vignette(size: size))
        vig.size = size
        vig.zPosition = 4
        cameraNode.addChild(vig)
    }

    func buildSky() {
        // A few brighter twinkling stars sit in the sky for a touch of life.
        for _ in 0..<22 {
            let s = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.8...1.8))
            s.fillColor = .white
            s.strokeColor = .clear
            s.alpha = CGFloat.random(in: 0.3...0.9)
            s.position = CGPoint(x: CGFloat.random(in: 0...size.width),
                                 y: CGFloat.random(in: (-CGFloat(skyRows) * tileSize)...0))
            s.zPosition = -9
            s.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.2, duration: Double.random(in: 0.8...2.0)),
                .fadeAlpha(to: 0.9, duration: Double.random(in: 0.8...2.0))
            ])))
            addChild(s)
        }
    }

    func generateWorld() {
        grid = WorldGenerator.generate(level)
        tileNodes = Array(repeating: Array(repeating: nil, count: cols), count: totalRows)
        for row in 0..<totalRows {
            for col in 0..<cols where grid[row][col].solid {
                addTileNode(col, row)
            }
        }
    }

    /// Base terrain tile: a designed sprite when the level provides one, else
    /// the procedural theme-colored tile.
    func dirtTile(band: Int) -> SKSpriteNode {
        if let names = level.theme.tileAssets {
            return SKSpriteNode(imageNamed: names[min(3, max(0, band))])
        }
        return SKSpriteNode(texture: tex.dirt(band: band, variant: Int.random(in: 0..<3)))
    }

    func addTileNode(_ col: Int, _ row: Int) {
        let depth = row - skyRows
        let band = depthBand(depth)
        let node: SKSpriteNode

        switch grid[row][col] {
        case .rock:
            node = SKSpriteNode(texture: tex.rock())
        case .lava:
            node = SKSpriteNode(texture: tex.lava(frame: 0))
            node.run(.repeatForever(.animate(with: [tex.lava(frame: 0), tex.lava(frame: 1)],
                                             timePerFrame: 0.45, resize: false, restore: true)))
        case .ore(let o):
            node = dirtTile(band: band)
            node.zPosition = 0.1
            let gem = SKSpriteNode(imageNamed: o.asset)
            // Fit the (non-square) mineral sprite inside the tile without distorting it.
            let px = gem.texture?.size() ?? CGSize(width: 1, height: 1)
            let scale = (tileSize * 0.82) / max(px.width, px.height)
            gem.size = CGSize(width: px.width * scale, height: px.height * scale)
            gem.zPosition = 0.2
            gem.run(.repeatForever(.sequence([.fadeAlpha(to: 0.82, duration: 0.9),
                                              .fadeAlpha(to: 1.0, duration: 0.9)])))
            node.addChild(gem)
        default:
            node = dirtTile(band: band)
        }

        node.size = CGSize(width: tileSize, height: tileSize)
        node.position = cellPosition(col, row)
        addChild(node)
        tileNodes[row][col] = node
    }

    func buildBase() {
        let base = SKSpriteNode(texture: tex.base())
        base.size = CGSize(width: tileSize * 3.3, height: tileSize * 1.65)
        base.position = CGPoint(x: cellPosition(cols / 2, surfaceRow).x,
                                y: cellPosition(cols / 2, surfaceRow).y + tileSize * 0.18)
        base.zPosition = 0.3
        addChild(base)
    }

    func buildPod() {
        pod = SKNode()
        pod.zPosition = 5

        let flame = SKSpriteNode(texture: tex.thruster())
        flame.size = CGSize(width: tileSize * 0.55, height: tileSize * 0.55)
        flame.position = CGPoint(x: 0, y: -tileSize * 0.82)
        flame.alpha = 0
        flame.zPosition = -1
        pod.addChild(flame)
        podFlame = flame

        // The designed pod sprite is the whole rig — body, glass dome, antenna
        // beacon and the striped drill in one piece. We shudder it while digging.
        let sprite = SKSpriteNode(imageNamed: "drill-pod")
        let px = sprite.texture?.size() ?? CGSize(width: 482, height: 679)
        let scale = (tileSize * 1.6) / px.height
        sprite.size = CGSize(width: px.width * scale, height: px.height * scale)
        sprite.position = CGPoint(x: 0, y: tileSize * 0.28)   // body centered, drill pokes below
        pod.addChild(sprite)
        podSprite = sprite

        addChild(pod)
    }
}
