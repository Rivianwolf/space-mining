//
//  TextureFactory.swift
//  Space Mining
//

import SpriteKit
import UIKit

// MARK: - Procedural art
//
// All sprites are drawn at load time with Core Graphics and cached as
// SKTextures — no external image files needed. This gives shaded, beveled
// tiles, faceted gems, a glowing lava, a metallic pod and a space backdrop.

final class TextureFactory {

    private var cache: [String: SKTexture] = [:]
    private let theme: Theme

    init(theme: Theme = Levels.deepDig.theme) { self.theme = theme }

    // MARK: Public accessors (cached)

    func dirt(band: Int, variant: Int) -> SKTexture {
        cached("dirt-\(band)-\(variant)") { self.drawDirt(band: band) }
    }
    func rock() -> SKTexture { cached("rock") { self.drawRock() } }
    func lava(frame: Int) -> SKTexture { cached("lava-\(frame)") { self.drawLava(bright: frame == 1) } }
    func gem(_ k: OreKind) -> SKTexture { cached("gem-\(k)") { self.drawGem(k) } }
    func pod() -> SKTexture { cached("pod") { self.drawPod() } }
    func drill() -> SKTexture { cached("drill") { self.drawDrill() } }
    func thruster() -> SKTexture { cached("thruster") { self.drawThruster() } }
    func base() -> SKTexture { cached("base") { self.drawBase() } }
    func background(size: CGSize) -> SKTexture { cached("bg") { self.drawBackground(size) } }
    func vignette(size: CGSize) -> SKTexture { cached("vig") { self.drawVignette(size) } }

    private func cached(_ key: String, _ make: () -> SKTexture) -> SKTexture {
        if let t = cache[key] { return t }
        let t = make(); cache[key] = t; return t
    }

    // MARK: Rendering helpers

    private func render(_ size: CGSize, _ draw: (CGContext) -> Void) -> SKTexture {
        let fmt = UIGraphicsImageRendererFormat.default()
        fmt.scale = 1
        fmt.opaque = false
        let img = UIGraphicsImageRenderer(size: size, format: fmt).image { ctx in draw(ctx.cgContext) }
        let t = SKTexture(image: img)
        t.filteringMode = .linear
        return t
    }

    // Deep Dig palette helper.
    private func hex(_ s: String) -> UIColor {
        var h = s; if h.hasPrefix("#") { h.removeFirst() }
        var v: UInt64 = 0; Scanner(string: h).scanHexInt64(&v)
        return UIColor(red: CGFloat((v >> 16) & 0xff) / 255,
                       green: CGFloat((v >> 8) & 0xff) / 255,
                       blue: CGFloat(v & 0xff) / 255, alpha: 1)
    }

    private func comps(_ c: UIColor) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }
    private func mix(_ a: UIColor, _ b: UIColor, _ t: CGFloat) -> UIColor {
        let x = comps(a), y = comps(b)
        return UIColor(red: x.0 + (y.0 - x.0) * t, green: x.1 + (y.1 - x.1) * t,
                       blue: x.2 + (y.2 - x.2) * t, alpha: x.3 + (y.3 - x.3) * t)
    }
    private func lighten(_ c: UIColor, _ t: CGFloat) -> UIColor { mix(c, .white, t) }
    private func darken(_ c: UIColor, _ t: CGFloat) -> UIColor { mix(c, .black, t) }

    private func vgrad(_ ctx: CGContext, _ rect: CGRect, _ top: UIColor, _ bottom: UIColor) {
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let g = CGGradient(colorsSpace: cs, colors: [top.cgColor, bottom.cgColor] as CFArray,
                                 locations: [0, 1]) else { return }
        ctx.saveGState(); ctx.clip(to: rect)
        ctx.drawLinearGradient(g, start: CGPoint(x: rect.midX, y: rect.minY),
                               end: CGPoint(x: rect.midX, y: rect.maxY), options: [])
        ctx.restoreGState()
    }
    private func radial(_ ctx: CGContext, center: CGPoint, radius: CGFloat, inner: UIColor, outer: UIColor) {
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let g = CGGradient(colorsSpace: cs, colors: [inner.cgColor, outer.cgColor] as CFArray,
                                 locations: [0, 1]) else { return }
        ctx.drawRadialGradient(g, startCenter: center, startRadius: 0,
                               endCenter: center, endRadius: radius, options: [.drawsBeforeStartLocation])
    }
    private func bevel(_ ctx: CGContext, _ s: CGFloat) {
        vgrad(ctx, CGRect(x: 0, y: 0, width: s, height: s * 0.16),
              UIColor(white: 1, alpha: 0.16), UIColor(white: 1, alpha: 0))
        vgrad(ctx, CGRect(x: 0, y: s * 0.84, width: s, height: s * 0.16),
              UIColor(white: 0, alpha: 0), UIColor(white: 0, alpha: 0.28))
        ctx.setStrokeColor(UIColor(white: 0, alpha: 0.38).cgColor)
        ctx.setLineWidth(2)
        ctx.stroke(CGRect(x: 0, y: 0, width: s, height: s).insetBy(dx: 1, dy: 1))
    }

    // MARK: Tiles

    private func drawDirt(band: Int) -> SKTexture {
        let s: CGFloat = 128
        // Depth layers come from the level theme: soil → stone → rock → bedrock.
        let layer = theme.bands[min(3, max(0, band))]
        let (top, bot) = (hex(layer.0), hex(layer.1))
        return render(CGSize(width: s, height: s)) { ctx in
            self.vgrad(ctx, CGRect(x: 0, y: 0, width: s, height: s), top, bot)
            // speckles — cool white / blue flecks + dark pits, matching the bible
            for _ in 0..<44 {
                let x = CGFloat.random(in: 0...s), y = CGFloat.random(in: 0...s)
                let r = CGFloat.random(in: 1.2...3.4)
                let roll = Int.random(in: 0..<3)
                let c: UIColor = roll == 0 ? UIColor(white: 1, alpha: 0.10)
                              : roll == 1 ? self.hex("#a0c8ff").withAlphaComponent(0.10)
                                          : UIColor(white: 0, alpha: 0.22)
                ctx.setFillColor(c.cgColor)
                ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r))
            }
            for _ in 0..<4 {
                let x = CGFloat.random(in: 8...(s - 18)), y = CGFloat.random(in: 8...(s - 18))
                let w = CGFloat.random(in: 9...16)
                ctx.setFillColor(self.lighten(top, 0.12).withAlphaComponent(0.5).cgColor)
                ctx.addPath(CGPath(roundedRect: CGRect(x: x, y: y, width: w, height: w * 0.7),
                                   cornerWidth: 3, cornerHeight: 3, transform: nil))
                ctx.fillPath()
            }
            self.bevel(ctx, s)
        }
    }

    private func drawRock() -> SKTexture {
        let s: CGFloat = 128
        return render(CGSize(width: s, height: s)) { ctx in
            let top = self.hex(self.theme.hazardRockTop)
            let bot = self.hex(self.theme.hazardRockBot)
            self.vgrad(ctx, CGRect(x: 0, y: 0, width: s, height: s), top, bot)
            for _ in 0..<28 {
                let x = CGFloat.random(in: 0...s), y = CGFloat.random(in: 0...s), r = CGFloat.random(in: 1...3)
                ctx.setFillColor((Bool.random() ? self.lighten(top, 0.2) : self.darken(bot, 0.25))
                    .withAlphaComponent(0.5).cgColor)
                ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r))
            }
            ctx.setLineWidth(2.5)
            for _ in 0..<3 {
                ctx.setStrokeColor(UIColor(white: 0, alpha: 0.4).cgColor)
                var p = CGPoint(x: CGFloat.random(in: 10...(s - 10)), y: CGFloat.random(in: 0...20))
                ctx.beginPath(); ctx.move(to: p)
                for _ in 0..<Int.random(in: 3...5) {
                    p = CGPoint(x: p.x + CGFloat.random(in: -20...20), y: p.y + CGFloat.random(in: 18...34))
                    ctx.addLine(to: p)
                }
                ctx.strokePath()
            }
            self.bevel(ctx, s)
        }
    }

    private func drawLava(bright: Bool) -> SKTexture {
        let s: CGFloat = 128
        return render(CGSize(width: s, height: s)) { ctx in
            self.vgrad(ctx, CGRect(x: 0, y: 0, width: s, height: s),
                       UIColor(red: 0.20, green: 0.08, blue: 0.06, alpha: 1),
                       UIColor(red: 0.10, green: 0.04, blue: 0.03, alpha: 1))
            let glow: CGFloat = bright ? 1.0 : 0.65
            for _ in 0..<3 {
                let c = CGPoint(x: CGFloat.random(in: 20...(s - 20)), y: CGFloat.random(in: 20...(s - 20)))
                self.radial(ctx, center: c, radius: CGFloat.random(in: 14...26),
                            inner: UIColor(red: 1, green: 0.9, blue: 0.4, alpha: glow),
                            outer: UIColor(red: 0.9, green: 0.3, blue: 0.05, alpha: 0))
            }
            ctx.setShadow(offset: .zero, blur: bright ? 8 : 4,
                          color: UIColor(red: 1, green: 0.5, blue: 0.1, alpha: 0.9).cgColor)
            ctx.setStrokeColor(UIColor(red: 1, green: 0.7, blue: 0.2, alpha: glow).cgColor)
            ctx.setLineWidth(bright ? 3 : 2)
            for _ in 0..<3 {
                var p = CGPoint(x: CGFloat.random(in: 0...s), y: CGFloat.random(in: 0...30))
                ctx.beginPath(); ctx.move(to: p)
                for _ in 0..<4 {
                    p = CGPoint(x: p.x + CGFloat.random(in: -22...22), y: p.y + CGFloat.random(in: 20...32))
                    ctx.addLine(to: p)
                }
                ctx.strokePath()
            }
            ctx.setShadow(offset: .zero, blur: 0)
            ctx.setStrokeColor(UIColor(white: 0, alpha: 0.4).cgColor)
            ctx.setLineWidth(2)
            ctx.stroke(CGRect(x: 0, y: 0, width: s, height: s).insetBy(dx: 1, dy: 1))
        }
    }

    // MARK: Gems

    /// (light, mid, dark, top, shade, glow) per ore — from the Deep Dig art bible.
    private func gemPalette(_ k: OreKind) -> (UIColor, UIColor, UIColor, UIColor, UIColor, UIColor) {
        switch k {
        case .emerald:  return (hex("#bff7d8"), hex("#54e39a"), hex("#1f9e63"), hex("#d9fcea"),
                                UIColor(red: 0.03, green: 0.24, blue: 0.16, alpha: 0.25), hex("#62f0a8"))
        case .ruby:     return (hex("#ffc2dd"), hex("#ff6fa9"), hex("#cf3f78"), hex("#ffd9e9"),
                                UIColor(red: 0.27, green: 0.05, blue: 0.16, alpha: 0.22), hex("#ff7bb0"))
        case .gold:     return (hex("#ffe9a8"), hex("#ffb33c"), hex("#d6841a"), hex("#fff1c2"),
                                UIColor(red: 0.27, green: 0.16, blue: 0.03, alpha: 0.22), hex("#ffc850"))
        case .bronzium: return (hex("#f4cf9a"), hex("#d68a3a"), hex("#9c5f1c"), hex("#ffe6c2"),
                                UIColor(red: 0.25, green: 0.14, blue: 0.04, alpha: 0.25), hex("#e8a85a"))
        case .silverium:return (hex("#eef3ff"), hex("#aab6dc"), hex("#6c79ac"), hex("#ffffff"),
                                UIColor(red: 0.08, green: 0.12, blue: 0.24, alpha: 0.20), hex("#c8d4ff"))
        case .diamond:  return (hex("#e6fcff"), hex("#5fe6ff"), hex("#1f7fb8"), hex("#ffffff"),
                                UIColor(red: 0.04, green: 0.20, blue: 0.32, alpha: 0.20), hex("#5fe6ff"))
        case .fossil:   return (hex("#e0ccff"), hex("#a877ff"), hex("#6f3fd6"), hex("#efe4ff"),
                                UIColor(red: 0.16, green: 0.05, blue: 0.27, alpha: 0.25), hex("#b58cff"))
        }
    }

    private func drawGem(_ k: OreKind) -> SKTexture {
        let s: CGFloat = 128
        let (light, mid, dark, top, shade, glow) = gemPalette(k)
        return render(CGSize(width: s, height: s)) { ctx in
            let cx = s / 2
            let gw = s * 0.56, gh = s * 0.78
            let topY = s * 0.11
            let midY = topY + gh * 0.35
            let botY = topY + gh
            let pTop = CGPoint(x: cx, y: topY)
            let pRight = CGPoint(x: cx + gw / 2, y: midY)
            let pBot = CGPoint(x: cx, y: botY)
            let pLeft = CGPoint(x: cx - gw / 2, y: midY)
            let pMid = CGPoint(x: cx, y: midY)

            // glow halo
            self.radial(ctx, center: CGPoint(x: cx, y: (topY + botY) / 2), radius: s * 0.5,
                        inner: glow.withAlphaComponent(0.6), outer: glow.withAlphaComponent(0))

            // body (kite) with diagonal light→mid→dark gradient
            let kite = CGMutablePath()
            kite.addLines(between: [pTop, pRight, pBot, pLeft]); kite.closeSubpath()
            ctx.saveGState(); ctx.addPath(kite); ctx.clip()
            let cs = CGColorSpaceCreateDeviceRGB()
            if let g = CGGradient(colorsSpace: cs, colors: [light.cgColor, mid.cgColor, dark.cgColor] as CFArray,
                                  locations: [0, 0.55, 1]) {
                ctx.drawLinearGradient(g, start: CGPoint(x: gw * 0.1, y: topY),
                                       end: CGPoint(x: gw, y: botY), options: [])
            }
            ctx.restoreGState()

            // top facet (bright)
            let tf = CGMutablePath(); tf.addLines(between: [pTop, pRight, pLeft]); tf.closeSubpath()
            ctx.addPath(tf); ctx.setFillColor(top.withAlphaComponent(0.85).cgColor); ctx.fillPath()
            // lower-left facet (shade)
            let lf = CGMutablePath(); lf.addLines(between: [pLeft, pMid, pBot]); lf.closeSubpath()
            ctx.addPath(lf); ctx.setFillColor(shade.cgColor); ctx.fillPath()
            // center highlight seam
            ctx.setStrokeColor(UIColor(white: 1, alpha: 0.5).cgColor); ctx.setLineWidth(2)
            ctx.beginPath(); ctx.move(to: pTop); ctx.addLine(to: pBot); ctx.strokePath()
            // outline
            ctx.addPath(kite); ctx.setStrokeColor(dark.withAlphaComponent(0.9).cgColor)
            ctx.setLineWidth(2); ctx.strokePath()
        }
    }

    // MARK: Pod

    private func drawPod() -> SKTexture {
        let s: CGFloat = 256
        let pod1 = hex("#ffe2a0"), pod2 = hex("#ffb451"), pod3 = hex("#ff9128"), stroke = hex("#c66a16")
        return render(CGSize(width: s, height: s)) { ctx in
            let cx = s / 2

            // antenna stalk (beacon light is a separate blinking node)
            ctx.setFillColor(stroke.cgColor)
            ctx.fill(CGRect(x: cx - 2, y: s * 0.10, width: 4, height: s * 0.10))

            // side fins
            for sgn in [-1.0, 1.0] as [CGFloat] {
                let fin = CGMutablePath()
                let baseX = cx + sgn * s * 0.27
                fin.move(to: CGPoint(x: baseX, y: s * 0.50))
                fin.addLine(to: CGPoint(x: baseX + sgn * s * 0.10, y: s * 0.55))
                fin.addLine(to: CGPoint(x: baseX, y: s * 0.70))
                fin.closeSubpath()
                ctx.saveGState(); ctx.addPath(fin); ctx.clip()
                self.vgrad(ctx, CGRect(x: cx - s * 0.4, y: s * 0.5, width: s * 0.8, height: s * 0.25), pod2, self.hex("#e07d1e"))
                ctx.restoreGState()
            }

            // body
            let bodyRect = CGRect(x: s * 0.27, y: s * 0.20, width: s * 0.46, height: s * 0.54)
            let bodyPath = CGPath(roundedRect: bodyRect, cornerWidth: s * 0.20, cornerHeight: s * 0.18, transform: nil)
            ctx.saveGState(); ctx.addPath(bodyPath); ctx.clip()
            let cs = CGColorSpaceCreateDeviceRGB()
            if let g = CGGradient(colorsSpace: cs, colors: [pod1.cgColor, pod2.cgColor, pod3.cgColor] as CFArray,
                                  locations: [0, 0.46, 1]) {
                ctx.drawLinearGradient(g, start: CGPoint(x: cx, y: bodyRect.minY),
                                       end: CGPoint(x: cx, y: bodyRect.maxY), options: [])
            }
            // inner top sheen + bottom warm shadow
            self.vgrad(ctx, CGRect(x: bodyRect.minX, y: bodyRect.minY, width: bodyRect.width, height: 10),
                       UIColor(white: 1, alpha: 0.5), UIColor(white: 1, alpha: 0))
            self.vgrad(ctx, CGRect(x: bodyRect.minX, y: bodyRect.maxY - 26, width: bodyRect.width, height: 26),
                       self.hex("#aa4b0a").withAlphaComponent(0), self.hex("#aa4b0a").withAlphaComponent(0.35))
            ctx.restoreGState()
            ctx.addPath(bodyPath); ctx.setStrokeColor(stroke.cgColor); ctx.setLineWidth(5); ctx.strokePath()

            // glass dome
            let domeR = s * 0.135
            let domeC = CGPoint(x: cx, y: s * 0.38)
            ctx.saveGState()
            ctx.addEllipse(in: CGRect(x: domeC.x - domeR, y: domeC.y - domeR, width: 2 * domeR, height: 2 * domeR))
            ctx.clip()
            self.radial(ctx, center: CGPoint(x: domeC.x - domeR * 0.35, y: domeC.y - domeR * 0.4), radius: domeR * 1.8,
                        inner: self.hex("#e6fcff"), outer: self.hex("#1f7fb8"))
            ctx.restoreGState()
            ctx.addEllipse(in: CGRect(x: domeC.x - domeR, y: domeC.y - domeR, width: 2 * domeR, height: 2 * domeR))
            ctx.setStrokeColor(stroke.cgColor); ctx.setLineWidth(4); ctx.strokePath()
            ctx.setFillColor(UIColor(white: 1, alpha: 0.8).cgColor)
            ctx.fillEllipse(in: CGRect(x: domeC.x - domeR * 0.6, y: domeC.y - domeR * 0.55,
                                       width: domeR * 0.5, height: domeR * 0.34))

            // steel bumper bar
            let bar = CGRect(x: cx - s * 0.20, y: s * 0.70, width: s * 0.40, height: s * 0.055)
            ctx.saveGState()
            ctx.addPath(CGPath(roundedRect: bar, cornerWidth: 6, cornerHeight: 6, transform: nil)); ctx.clip()
            self.vgrad(ctx, bar, self.hex("#c2cbe6"), self.hex("#8a96bd"))
            ctx.restoreGState()
            ctx.addPath(CGPath(roundedRect: bar, cornerWidth: 6, cornerHeight: 6, transform: nil))
            ctx.setStrokeColor(self.hex("#6c79ac").cgColor); ctx.setLineWidth(2.5); ctx.strokePath()
        }
    }

    /// Steel-striped drill bit (downward triangle) — vibrates horizontally while digging.
    private func drawDrill() -> SKTexture {
        let s: CGFloat = 128
        return render(CGSize(width: s, height: s)) { ctx in
            let tri = CGMutablePath()
            tri.move(to: CGPoint(x: s * 0.14, y: s * 0.06))
            tri.addLine(to: CGPoint(x: s * 0.86, y: s * 0.06))
            tri.addLine(to: CGPoint(x: s * 0.5, y: s * 0.98))
            tri.closeSubpath()

            ctx.saveGState(); ctx.addPath(tri); ctx.clip()
            ctx.setFillColor(self.hex("#9aa6cc").cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: s, height: s))
            // diagonal auger stripes (≈125°)
            ctx.setStrokeColor(self.hex("#dde3f2").cgColor); ctx.setLineWidth(s * 0.085)
            var d = -s
            while d < s * 1.4 {
                ctx.beginPath()
                ctx.move(to: CGPoint(x: d, y: -s * 0.1))
                ctx.addLine(to: CGPoint(x: d + s * 0.7, y: s * 1.1))
                ctx.strokePath()
                d += s * 0.2
            }
            ctx.restoreGState()
            ctx.addPath(tri); ctx.setStrokeColor(self.hex("#6c79ac").cgColor); ctx.setLineWidth(3); ctx.strokePath()
            // hot tip glow
            self.radial(ctx, center: CGPoint(x: s * 0.5, y: s * 0.92), radius: s * 0.18,
                        inner: UIColor(white: 1, alpha: 0.55), outer: UIColor(white: 1, alpha: 0))
        }
    }

    private func drawThruster() -> SKTexture {
        let s: CGFloat = 128
        return render(CGSize(width: s, height: s)) { ctx in
            self.radial(ctx, center: CGPoint(x: s / 2, y: s * 0.4), radius: s * 0.45,
                        inner: UIColor(red: 1, green: 1, blue: 0.7, alpha: 0.95),
                        outer: UIColor(red: 1, green: 0.4, blue: 0.05, alpha: 0))
            let flame = CGMutablePath()
            flame.move(to: CGPoint(x: s * 0.32, y: s * 0.2))
            flame.addLine(to: CGPoint(x: s * 0.68, y: s * 0.2))
            flame.addLine(to: CGPoint(x: s * 0.5, y: s * 0.95))
            flame.closeSubpath()
            ctx.saveGState(); ctx.addPath(flame); ctx.clip()
            self.vgrad(ctx, CGRect(x: 0, y: s * 0.2, width: s, height: s * 0.75),
                       UIColor(red: 1, green: 0.95, blue: 0.6, alpha: 0.95),
                       UIColor(red: 1, green: 0.35, blue: 0.05, alpha: 0.25))
            ctx.restoreGState()
        }
    }

    // MARK: Base + background

    private func drawBase() -> SKTexture {
        let w: CGFloat = 320, h: CGFloat = 160
        return render(CGSize(width: w, height: h)) { ctx in
            let padTopY = h * 0.45
            let pad = CGMutablePath()
            pad.move(to: CGPoint(x: w * 0.08, y: padTopY))
            pad.addLine(to: CGPoint(x: w * 0.92, y: padTopY))
            pad.addLine(to: CGPoint(x: w * 0.82, y: h * 0.72))
            pad.addLine(to: CGPoint(x: w * 0.18, y: h * 0.72))
            pad.closeSubpath()

            // legs
            ctx.setFillColor(UIColor(white: 0.35, alpha: 1).cgColor)
            ctx.fill(CGRect(x: w * 0.20, y: h * 0.66, width: 10, height: h * 0.26))
            ctx.fill(CGRect(x: w * 0.76, y: h * 0.66, width: 10, height: h * 0.26))

            ctx.saveGState(); ctx.addPath(pad); ctx.clip()
            self.vgrad(ctx, CGRect(x: 0, y: padTopY, width: w, height: h * 0.3),
                       UIColor(white: 0.58, alpha: 1), UIColor(white: 0.3, alpha: 1))
            ctx.setStrokeColor(UIColor(red: 1, green: 0.8, blue: 0.1, alpha: 0.9).cgColor)
            ctx.setLineWidth(8)
            var x = w * 0.05
            while x < w {
                ctx.beginPath(); ctx.move(to: CGPoint(x: x, y: padTopY))
                ctx.addLine(to: CGPoint(x: x - 22, y: h * 0.72)); ctx.strokePath()
                x += 28
            }
            ctx.restoreGState()
            ctx.addPath(pad); ctx.setStrokeColor(UIColor(white: 0.2, alpha: 1).cgColor); ctx.setLineWidth(3); ctx.strokePath()

            // habitat dome
            let dc = CGPoint(x: w * 0.35, y: padTopY)
            let dr = w * 0.13
            ctx.saveGState()
            ctx.addRect(CGRect(x: dc.x - dr, y: dc.y - dr, width: 2 * dr, height: dr)); ctx.clip()
            self.radial(ctx, center: CGPoint(x: dc.x - dr * 0.3, y: dc.y - dr * 0.3), radius: dr * 1.7,
                        inner: UIColor(red: 0.85, green: 0.97, blue: 1, alpha: 1),
                        outer: UIColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1))
            ctx.restoreGState()
            ctx.addRect(CGRect(x: dc.x - dr, y: dc.y - dr, width: 2 * dr, height: dr))
            ctx.setStrokeColor(UIColor(white: 1, alpha: 0.85).cgColor); ctx.setLineWidth(2); ctx.strokePath()

            // antenna + beacon
            ctx.setStrokeColor(UIColor(white: 0.8, alpha: 1).cgColor); ctx.setLineWidth(3)
            ctx.beginPath(); ctx.move(to: CGPoint(x: w * 0.64, y: padTopY))
            ctx.addLine(to: CGPoint(x: w * 0.64, y: h * 0.12)); ctx.strokePath()
            ctx.setFillColor(UIColor(red: 1, green: 0.4, blue: 0.4, alpha: 1).cgColor)
            ctx.fillEllipse(in: CGRect(x: w * 0.625, y: h * 0.07, width: 11, height: 11))
        }
    }

    private func drawBackground(_ size: CGSize) -> SKTexture {
        render(size) { ctx in
            // sky → deep void, with a warm glow up top (radial 120% 90% at 50% 0%)
            self.vgrad(ctx, CGRect(origin: .zero, size: size),
                       self.hex(self.theme.skyTop), self.hex(self.theme.voidColor))
            self.radial(ctx, center: CGPoint(x: size.width * 0.5, y: size.height * 0.02),
                        radius: size.height * 0.55,
                        inner: self.hex(self.theme.skyGlow).withAlphaComponent(0.9),
                        outer: self.hex(self.theme.skyGlow).withAlphaComponent(0))
            for _ in 0..<130 {
                let x = CGFloat.random(in: 0...size.width), y = CGFloat.random(in: 0...size.height)
                let r = CGFloat.random(in: 0.5...1.7)
                ctx.setFillColor(UIColor(white: 1, alpha: CGFloat.random(in: 0.25...0.9)).cgColor)
                ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r))
            }
        }
    }

    private func drawVignette(_ size: CGSize) -> SKTexture {
        render(size) { ctx in
            self.radial(ctx, center: CGPoint(x: size.width * 0.5, y: size.height * 0.42),
                        radius: max(size.width, size.height) * 0.62,
                        inner: self.hex("#040610").withAlphaComponent(0),
                        outer: self.hex("#040610").withAlphaComponent(0.55))
        }
    }
}
