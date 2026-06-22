//
//  LevelMapArt.swift
//  Space Mining
//
//  Procedural planet art for the "Choose Your Dig" level map — each level node
//  is a distinct shaded world (craters, terminator shading, glow), drawn with
//  Core Graphics to match the Deep Dig Level Map design. Also draws the drifting
//  background planets and the saucer-alien mascot.
//

import SpriteKit
import UIKit

final class LevelMapArt {

    private var cache: [String: SKTexture] = [:]

    // (top, mid, bot, radialBase, craters[(color, sizeRange, count)], glowCore?, glow)
    private struct Spec {
        let top, mid, bot: UIColor
        let radial: Bool
        let craters: [(UIColor, ClosedRange<CGFloat>, Int)]
        let glowCore: UIColor?
        let glow: UIColor
    }

    // MARK: Public

    func planet(_ id: String) -> SKTexture { cached("p-\(id)") { self.drawOrb(self.nodeSpec(id), px: 220) } }
    func bgPlanet(_ id: String) -> SKTexture { cached("bg-\(id)") { self.drawOrb(self.bgSpec(id), px: 240) } }
    func saucer() -> SKTexture { cached("saucer") { self.drawSaucer() } }

    private func cached(_ k: String, _ make: () -> SKTexture) -> SKTexture {
        if let t = cache[k] { return t }; let t = make(); cache[k] = t; return t
    }

    // MARK: Specs

    private func nodeSpec(_ id: String) -> Spec {
        switch id {
        case "crust":    return Spec(top: h("a596be"), mid: h("6a5c84"), bot: h("473a5e"), radial: false,
                                     craters: [(rgba(0,0,0,0.4), 5...8, 3), (rgba(255,255,255,0.16), 3...4, 1)],
                                     glowCore: nil, glow: h("ffc850"))
        case "bluestone":return Spec(top: h("7fd0f4"), mid: h("2f86c8"), bot: h("1c548e"), radial: false,
                                     craters: [(rgba(120,230,180,0.55), 4...7, 2), (rgba(255,255,255,0.45), 3...4, 1)],
                                     glowCore: nil, glow: h("5fc8ff"))
        case "echo":     return Spec(top: h("86ecb6"), mid: h("27a86c"), bot: h("177a4c"), radial: false,
                                     craters: [(rgba(20,90,55,0.55), 4...7, 2), (rgba(210,255,230,0.4), 3...4, 1)],
                                     glowCore: nil, glow: h("62f0a8"))
        case "rift":     return Spec(top: h("ffe7b0"), mid: h("ff9d3c"), bot: h("d65a1e"), radial: false,
                                     craters: [(rgba(120,30,0,0.5), 4...6, 2), (rgba(255,240,170,0.7), 3...4, 1), (rgba(255,120,30,0.7), 4...6, 1)],
                                     glowCore: nil, glow: h("ffaa3c"))
        case "magma":    return Spec(top: h("c66a4a"), mid: h("8a3322"), bot: h("5a1d14"), radial: false,
                                     craters: [(rgba(255,140,40,0.6), 3...5, 2), (rgba(60,8,4,0.5), 5...6, 1)],
                                     glowCore: nil, glow: h("ff5a32"))
        case "void":     return Spec(top: h("7a4fd6"), mid: h("3a2270"), bot: h("1d1238"), radial: true,
                                     craters: [(rgba(255,255,255,0.7), 1...2, 7), (rgba(200,160,255,0.5), 1...2, 5)],
                                     glowCore: h("dcb4ff"), glow: h("b58cff"))
        case "core":     return Spec(top: h("ffa6e4"), mid: h("9a4fd0"), bot: h("4a1f78"), radial: true,
                                     craters: [(rgba(255,255,255,0.5), 3...4, 2), (rgba(120,40,160,0.5), 5...6, 1), (rgba(255,180,240,0.55), 4...5, 1)],
                                     glowCore: h("fff0ff"), glow: h("b58cff"))
        default:         return nodeSpec("crust")
        }
    }

    private func bgSpec(_ id: String) -> Spec {
        switch id {
        case "gas":  return Spec(top: h("ffe1a8"), mid: h("e8a94e"), bot: h("9c6e3c"), radial: false,
                                 craters: [(rgba(120,70,30,0.4), 4...6, 3), (rgba(255,240,200,0.35), 3...4, 1)], glowCore: nil, glow: h("ffd296"))
        case "ice":  return Spec(top: h("dff6ff"), mid: h("8fd6f0"), bot: h("2f74b0"), radial: false,
                                 craters: [(rgba(255,255,255,0.5), 4...5, 2), (rgba(40,110,170,0.4), 4...5, 1)], glowCore: nil, glow: h("9fd6ff"))
        case "red":  return Spec(top: h("ffb27a"), mid: h("f0683c"), bot: h("c33a28"), radial: false,
                                 craters: [(rgba(120,20,10,0.45), 4...6, 2), (rgba(255,220,150,0.4), 3...4, 1)], glowCore: nil, glow: h("ff6e50"))
        default:     return Spec(top: h("7f8fd0"), mid: h("3a4488"), bot: h("262e62"), radial: true,
                                 craters: [(rgba(160,190,255,0.4), 4...5, 2), (rgba(20,30,70,0.5), 4...5, 1)], glowCore: nil, glow: h("78a0ff"))
        }
    }

    // MARK: Drawing

    private func drawOrb(_ s: Spec, px: CGFloat) -> SKTexture {
        render(CGSize(width: px, height: px)) { ctx in
            let c = CGPoint(x: px / 2, y: px / 2)
            let R = px * 0.40
            // outer glow
            self.radial(ctx, c, R * 1.5, s.glow.withAlphaComponent(0.4), s.glow.withAlphaComponent(0))

            ctx.saveGState()
            ctx.addEllipse(in: CGRect(x: c.x - R, y: c.y - R, width: 2 * R, height: 2 * R)); ctx.clip()
            // base
            if s.radial {
                self.radial(ctx, CGPoint(x: c.x - R * 0.12, y: c.y - R * 0.12), R * 1.4, s.top, s.bot)
            } else {
                self.vgrad3(ctx, CGRect(x: c.x - R, y: c.y - R, width: 2 * R, height: 2 * R), s.top, s.mid, s.bot)
            }
            // craters / surface speckles
            for (col, sr, count) in s.craters {
                for _ in 0..<count {
                    let a = CGFloat.random(in: 0...(2 * .pi)), d = CGFloat.random(in: 0...(R * 0.78))
                    let p = CGPoint(x: c.x + cos(a) * d, y: c.y + sin(a) * d)
                    let rr = CGFloat.random(in: sr)
                    ctx.setFillColor(col.cgColor)
                    ctx.fillEllipse(in: CGRect(x: p.x - rr, y: p.y - rr, width: 2 * rr, height: 2 * rr))
                }
            }
            if let gc = s.glowCore {
                self.radial(ctx, c, R * 0.5, gc.withAlphaComponent(0.95), gc.withAlphaComponent(0))
            }
            // terminator shading
            self.radial(ctx, CGPoint(x: c.x - R * 0.4, y: c.y - R * 0.48), R * 0.9,
                        UIColor(white: 1, alpha: 0.5), UIColor(white: 1, alpha: 0))
            self.radial(ctx, CGPoint(x: c.x + R * 0.44, y: c.y + R * 0.6), R * 1.1,
                        UIColor(white: 0, alpha: 0.5), UIColor(white: 0, alpha: 0))
            ctx.restoreGState()
        }
    }

    private func drawSaucer() -> SKTexture {
        let w: CGFloat = 200, hgt: CGFloat = 150
        return render(CGSize(width: w, height: hgt)) { ctx in
            let cx = w / 2
            // under-glow
            self.radial(ctx, CGPoint(x: cx, y: hgt * 0.62), 60, h("5fe6ff").withAlphaComponent(0.5), h("5fe6ff").withAlphaComponent(0))
            // hull
            let hull = CGRect(x: cx - 84, y: hgt * 0.5, width: 168, height: 48)
            ctx.saveGState(); ctx.addEllipse(in: hull); ctx.clip()
            self.vgrad3(ctx, hull, h("eef1fa"), h("b3bedd"), h("7b88b4"))
            ctx.restoreGState()
            ctx.addEllipse(in: hull); ctx.setStrokeColor(h("5b6890").cgColor); ctx.setLineWidth(3); ctx.strokePath()
            // hull lights
            for (i, col) in [h("5fe6ff"), h("ffd574"), h("ff7bb0")].enumerated() {
                let x = cx - 48 + CGFloat(i) * 48
                self.radial(ctx, CGPoint(x: x, y: hgt * 0.56), 9, col, col.withAlphaComponent(0))
                ctx.setFillColor(col.cgColor); ctx.fillEllipse(in: CGRect(x: x - 5, y: hgt * 0.56 - 5, width: 10, height: 10))
            }
            // dome
            let domeC = CGPoint(x: cx, y: hgt * 0.42), domeR: CGFloat = 44
            ctx.saveGState()
            ctx.addEllipse(in: CGRect(x: domeC.x - domeR, y: domeC.y - domeR * 0.85, width: 2 * domeR, height: domeR * 1.7)); ctx.clip()
            self.radial(ctx, CGPoint(x: domeC.x - 12, y: domeC.y - 14), domeR * 1.4,
                        h("c3f5ff").withAlphaComponent(0.7), h("5fc8ff").withAlphaComponent(0.25))
            ctx.restoreGState()
            // alien head
            let head = CGRect(x: cx - 20, y: hgt * 0.30, width: 40, height: 36)
            ctx.saveGState(); ctx.addEllipse(in: head); ctx.clip()
            self.radial(ctx, CGPoint(x: head.midX - 5, y: head.minY + 10), 36, h("9af0c6"), h("27935f"))
            ctx.restoreGState()
            // eyes
            ctx.setFillColor(h("11203a").cgColor)
            for dx in [-10.0, 10.0] as [CGFloat] {
                ctx.fillEllipse(in: CGRect(x: cx + dx - 6, y: head.minY + 12, width: 12, height: 15))
            }
            ctx.setFillColor(UIColor.white.cgColor)
            for dx in [-10.0, 10.0] as [CGFloat] {
                ctx.fillEllipse(in: CGRect(x: cx + dx - 3, y: head.minY + 22, width: 4, height: 4))
            }
            // antenna
            ctx.setStrokeColor(h("3fbe82").cgColor); ctx.setLineWidth(3)
            ctx.beginPath(); ctx.move(to: CGPoint(x: cx, y: head.minY)); ctx.addLine(to: CGPoint(x: cx, y: head.minY - 12)); ctx.strokePath()
            self.radial(ctx, CGPoint(x: cx, y: head.minY - 15), 8, h("5fe6ff"), h("5fe6ff").withAlphaComponent(0))
        }
    }

    // MARK: Helpers

    private func render(_ size: CGSize, _ draw: (CGContext) -> Void) -> SKTexture {
        let fmt = UIGraphicsImageRendererFormat.default(); fmt.scale = 1; fmt.opaque = false
        let img = UIGraphicsImageRenderer(size: size, format: fmt).image { c in draw(c.cgContext) }
        let t = SKTexture(image: img); t.filteringMode = .linear; return t
    }
    private func h(_ s: String) -> UIColor { hexColor(s) }
    private func rgba(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat) -> UIColor {
        UIColor(red: r / 255, green: g / 255, blue: b / 255, alpha: a)
    }
    private func vgrad3(_ ctx: CGContext, _ rect: CGRect, _ a: UIColor, _ b: UIColor, _ c: UIColor) {
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let g = CGGradient(colorsSpace: cs, colors: [a.cgColor, b.cgColor, c.cgColor] as CFArray,
                                 locations: [0, 0.5, 1]) else { return }
        ctx.drawLinearGradient(g, start: CGPoint(x: rect.midX, y: rect.minY),
                               end: CGPoint(x: rect.midX, y: rect.maxY), options: [])
    }
    private func radial(_ ctx: CGContext, _ center: CGPoint, _ r: CGFloat, _ inner: UIColor, _ outer: UIColor) {
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let g = CGGradient(colorsSpace: cs, colors: [inner.cgColor, outer.cgColor] as CFArray,
                                 locations: [0, 1]) else { return }
        ctx.drawRadialGradient(g, startCenter: center, startRadius: 0, endCenter: center, endRadius: r,
                               options: [.drawsBeforeStartLocation])
    }
}
