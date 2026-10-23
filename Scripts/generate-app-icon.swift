#!/usr/bin/env swift
// generate-app-icon.swift — the iPad app icon, drawn from zhen-app's mark.
//
// zhen-app's `Design/marks/03-z/icon-colour.svg` is four shapes on a rounded plate inset
// in a 1024 canvas, as a macOS icon is drawn. iPadOS wants the opposite: a full-bleed,
// opaque square that the system masks. So this draws the plate edge to edge and scales the
// glyph with it — the 824-point plate becomes the 1024 square, and every glyph coordinate
// moves by the same transform — then writes an opaque PNG.
//
// Usage: Scripts/generate-app-icon.swift Zhen/Assets.xcassets/AppIcon.appiconset/icon-1024.png

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let output = CommandLine.arguments.dropFirst().first
    ?? "Zhen/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
let size = 1024

// The mark's own numbers, from icon-colour.svg.
let plate = (origin: 100.0, side: 824.0)
let scale = Double(size) / plate.side
func x(_ value: Double) -> Double { (value - plate.origin) * scale }
// Core Graphics' origin is bottom-left; the SVG's is top-left.
func y(_ value: Double) -> Double { Double(size) - (value - plate.origin) * scale }

func colour(_ hex: UInt32) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: 1
    )
}

guard let context = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else { fatalError("no context") }

context.setFillColor(colour(0x323A44))
context.fill(CGRect(x: 0, y: 0, width: size, height: size))

context.setFillColor(colour(0xF4F5F6))
for top in [256.0, 640.0] {
    context.fill(CGRect(x: x(256), y: y(top + 128), width: 512 * scale, height: 128 * scale))
}

context.setFillColor(colour(0x8CCBB4))
context.beginPath()
context.move(to: CGPoint(x: x(608), y: y(384)))
context.addLine(to: CGPoint(x: x(768), y: y(384)))
context.addLine(to: CGPoint(x: x(416), y: y(640)))
context.addLine(to: CGPoint(x: x(256), y: y(640)))
context.closePath()
context.fillPath()

guard let image = context.makeImage(),
      let destination = CGImageDestinationCreateWithURL(
          URL(fileURLWithPath: output) as CFURL, UTType.png.identifier as CFString, 1, nil
      )
else { fatalError("cannot write \(output)") }
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("cannot write \(output)") }
print("wrote \(output)")
