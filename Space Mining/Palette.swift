//
//  Palette.swift
//  Space Mining
//
//  Small shared color helper for turning theme hex strings into SKColors
//  outside of TextureFactory (e.g. the level-select UI).
//

import SpriteKit

func hexColor(_ s: String) -> SKColor {
    var h = s
    if h.hasPrefix("#") { h.removeFirst() }
    var v: UInt64 = 0
    Scanner(string: h).scanHexInt64(&v)
    return SKColor(red: CGFloat((v >> 16) & 0xff) / 255,
                   green: CGFloat((v >> 8) & 0xff) / 255,
                   blue: CGFloat(v & 0xff) / 255, alpha: 1)
}
