// Generates the DockAnchor app icon PNGs into an .iconset directory.
// The glyph mirrors the menu-bar status icon ("menubar.dock.rectangle"):
// a rounded screen with a menu-bar line near the top and a dock pill near
// the bottom, in white on a blue gradient.
//
// Usage: swift generate-icon.swift <output-iconset-dir>

import AppKit
import Foundation

let args = CommandLine.arguments
guard args.count >= 2 else {
    FileHandle.standardError.write("usage: generate-icon.swift <iconset-dir>\n".data(using: .utf8)!)
    exit(1)
}
let outDir = args[1]
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func drawIcon(size: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: size, height: size)

    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx
    let cg = ctx.cgContext
    let s = CGFloat(size)

    // Rounded-rect background filling the macOS icon "grid" with a small margin.
    let margin = s * 0.085
    let bgRect = CGRect(x: margin, y: margin, width: s - 2 * margin, height: s - 2 * margin)
    let bgCorner = bgRect.width * 0.2237
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: bgCorner, cornerHeight: bgCorner, transform: nil)

    cg.saveGState()
    cg.addPath(bgPath)
    cg.clip()
    let colors = [
        NSColor(srgbRed: 0.24, green: 0.52, blue: 0.99, alpha: 1).cgColor,
        NSColor(srgbRed: 0.09, green: 0.28, blue: 0.86, alpha: 1).cgColor,
    ] as CFArray
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors,
        locations: [0, 1]
    )!
    cg.drawLinearGradient(gradient, start: CGPoint(x: 0, y: s), end: CGPoint(x: 0, y: 0), options: [])
    cg.restoreGState()

    // White glyph: a rounded "screen" rectangle, a menu-bar line, a dock pill.
    let white = NSColor.white.cgColor
    let w = s * 0.50
    let h = s * 0.40
    let gx = (s - w) / 2
    let gy = (s - h) / 2
    let glyphRect = CGRect(x: gx, y: gy, width: w, height: h)
    let glyphCorner = h * 0.16
    let stroke = s * 0.030

    // Screen outline.
    let screenPath = CGPath(
        roundedRect: glyphRect.insetBy(dx: stroke / 2, dy: stroke / 2),
        cornerWidth: glyphCorner, cornerHeight: glyphCorner, transform: nil
    )
    cg.setStrokeColor(white)
    cg.setLineWidth(stroke)
    cg.addPath(screenPath)
    cg.strokePath()

    let innerInset = w * 0.13

    // Menu-bar line near the top (y is up; top = larger y).
    let barHeight = h * 0.085
    let barY = glyphRect.maxY - h * 0.22
    let barRect = CGRect(
        x: glyphRect.minX + innerInset,
        y: barY,
        width: w - 2 * innerInset,
        height: barHeight
    )
    cg.setFillColor(white)
    cg.addPath(CGPath(roundedRect: barRect, cornerWidth: barHeight / 2, cornerHeight: barHeight / 2, transform: nil))
    cg.fillPath()

    // Dock pill near the bottom.
    let dockWidth = w * 0.52
    let dockHeight = h * 0.135
    let dockRect = CGRect(
        x: glyphRect.midX - dockWidth / 2,
        y: glyphRect.minY + h * 0.13,
        width: dockWidth,
        height: dockHeight
    )
    cg.addPath(CGPath(roundedRect: dockRect, cornerWidth: dockHeight / 2, cornerHeight: dockHeight / 2, transform: nil))
    cg.fillPath()

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

// (filename, pixel size) entries required by .iconset.
let entries: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

for (name, size) in entries {
    let data = drawIcon(size: size)
    let path = (outDir as NSString).appendingPathComponent(name)
    try! data.write(to: URL(fileURLWithPath: path))
}

print("Wrote \(entries.count) PNGs to \(outDir)")
