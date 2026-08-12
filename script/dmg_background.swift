#!/usr/bin/env swift
// Draws the Notive disk image background at 1x and 2x into one multi-representation TIFF.
// usage: swift script/dmg_background.swift <brand-assets-dir> <output.tiff>

import AppKit
import Foundation

let windowWidth: CGFloat = 760
let windowHeight: CGFloat = 520

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    FileHandle.standardError.write(Data("usage: dmg_background.swift <brand-assets-dir> <output.tiff>\n".utf8))
    exit(2)
}
let assetsDirectory = URL(fileURLWithPath: arguments[1], isDirectory: true)
let outputURL = URL(fileURLWithPath: arguments[2])

func brandImage(_ name: String) -> NSImage? {
    NSImage(contentsOf: assetsDirectory.appendingPathComponent(name))
}

func ivory(_ alpha: CGFloat) -> NSColor {
    NSColor(srgbRed: 232 / 255, green: 226 / 255, blue: 215 / 255, alpha: alpha)
}

let aubergine = NSColor(srgbRed: 67 / 255, green: 59 / 255, blue: 71 / 255, alpha: 1)
let sage = NSColor(srgbRed: 156 / 255, green: 184 / 255, blue: 158 / 255, alpha: 1)
let steel = NSColor(srgbRed: 127 / 255, green: 169 / 255, blue: 184 / 255, alpha: 1)
let lilac = NSColor(srgbRed: 155 / 255, green: 143 / 255, blue: 184 / 255, alpha: 1)

/// Converts a distance from the top edge into the bottom-left origin the drawing context uses.
func fromTop(_ distance: CGFloat) -> CGFloat { windowHeight - distance }

func draw(
    _ text: String,
    centeredAtX x: CGFloat,
    top: CGFloat,
    size: CGFloat,
    weight: NSFont.Weight,
    color: NSColor
) {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
    ]
    let string = NSAttributedString(string: text, attributes: attributes)
    let bounds = string.size()
    string.draw(at: NSPoint(x: x - bounds.width / 2, y: fromTop(top) - bounds.height))
}

func draw(
    _ text: String,
    leftAtX x: CGFloat,
    centerY: CGFloat,
    size: CGFloat,
    weight: NSFont.Weight,
    color: NSColor
) -> CGFloat {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
    ]
    let string = NSAttributedString(string: text, attributes: attributes)
    let bounds = string.size()
    string.draw(at: NSPoint(x: x, y: centerY - bounds.height / 2))
    return bounds.width
}

func drawRightAligned(
    _ text: String,
    rightAtX x: CGFloat,
    centerY: CGFloat,
    size: CGFloat,
    weight: NSFont.Weight,
    color: NSColor
) {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
    ]
    let string = NSAttributedString(string: text, attributes: attributes)
    let bounds = string.size()
    string.draw(at: NSPoint(x: x - bounds.width, y: centerY - bounds.height / 2))
}

func drawAtmosphere() {
    guard let image = brandImage("first-motive-atmosphere.png") else { return }
    let source = image.size
    guard source.width > 0, source.height > 0 else { return }
    // The calm middle band of the atmosphere: no source wordmark, no bright motifs behind the icons.
    let bandWidth = source.width * 0.41
    let bandOriginX = source.width * 0.2
    let scale = max(windowWidth / bandWidth, windowHeight / source.height)
    let bandHeight = min(source.height, windowHeight / scale)
    let band = NSRect(
        x: bandOriginX,
        y: (source.height - bandHeight) / 2,
        width: windowWidth / scale,
        height: bandHeight
    )
    image.draw(
        in: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
        from: band,
        operation: .sourceOver,
        fraction: 0.28
    )
}

func drawHighlight() {
    let gradient = NSGradient(colors: [ivory(0.05), ivory(0)])
    gradient?.draw(
        fromCenter: NSPoint(x: windowWidth / 2, y: fromTop(104)),
        radius: 0,
        toCenter: NSPoint(x: windowWidth / 2, y: fromTop(104)),
        radius: 430,
        options: []
    )
}

func drawWordmark() {
    guard let image = brandImage("first-motive-wordmark.png"), image.size.width > 0 else { return }
    let width: CGFloat = 238
    let height = width * image.size.height / image.size.width
    let rect = NSRect(x: (windowWidth - width) / 2, y: fromTop(56) - height, width: width, height: height)
    image.draw(in: rect, from: .zero, operation: .lighten, fraction: 1)
}

func drawWaveform(centerX: CGFloat, centerY: CGFloat) {
    let heights: [CGFloat] = [16, 26, 38, 44, 38, 26, 16]
    let barWidth: CGFloat = 5
    let gap: CGFloat = 7
    let totalWidth = CGFloat(heights.count) * barWidth + CGFloat(heights.count - 1) * gap
    var x = centerX - totalWidth / 2
    for (index, height) in heights.enumerated() {
        let color: NSColor
        switch index {
        case 3: color = lilac
        case 2, 4: color = ivory(0.5)
        default: color = steel
        }
        let rect = NSRect(x: x, y: centerY - height / 2, width: barWidth, height: height)
        color.setFill()
        NSBezierPath(roundedRect: rect, xRadius: barWidth / 2, yRadius: barWidth / 2).fill()
        x += barWidth + gap
    }
}

func drawDropZone(centerX: CGFloat, centerY: CGFloat) {
    let side: CGFloat = 136
    let rect = NSRect(x: centerX - side / 2, y: centerY - side / 2, width: side, height: side)
    ivory(0.04).setFill()
    let plate = NSBezierPath(roundedRect: rect, xRadius: 28, yRadius: 28)
    plate.fill()
    let outline = NSBezierPath(roundedRect: rect.insetBy(dx: 1.25, dy: 1.25), xRadius: 27, yRadius: 27)
    outline.lineWidth = 2.5
    outline.setLineDash([7, 6], count: 2, phase: 0)
    ivory(0.28).setStroke()
    outline.stroke()
}

func drawLock(originX: CGFloat, centerY: CGFloat, color: NSColor) {
    color.setStroke()
    let body = NSBezierPath(
        roundedRect: NSRect(x: originX, y: centerY - 5, width: 11, height: 8),
        xRadius: 1.6,
        yRadius: 1.6
    )
    body.lineWidth = 1.4
    body.stroke()
    let shackle = NSBezierPath()
    shackle.appendArc(
        withCenter: NSPoint(x: originX + 5.5, y: centerY + 3),
        radius: 3.4,
        startAngle: 0,
        endAngle: 180
    )
    shackle.lineWidth = 1.4
    shackle.stroke()
}

func drawFooter() {
    let height: CGFloat = 34
    NSColor(calibratedWhite: 0, alpha: 0.22).setFill()
    NSRect(x: 0, y: 0, width: windowWidth, height: height).fill()
    ivory(0.16).setFill()
    NSRect(x: 0, y: height - 1, width: windowWidth, height: 1).fill()

    let centerY = height / 2
    drawLock(originX: 18, centerY: centerY, color: ivory(0.45))
    _ = draw(
        "Private by design — everything Notive records stays on this Mac.",
        leftAtX: 36,
        centerY: centerY,
        size: 11,
        weight: .medium,
        color: ivory(0.45)
    )
    drawRightAligned(
        "Internal build · Ubundi & First Motive",
        rightAtX: windowWidth - 18,
        centerY: centerY,
        size: 11,
        weight: .medium,
        color: ivory(0.45)
    )
}

func drawBackground() {
    aubergine.setFill()
    NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight).fill()
    drawAtmosphere()
    drawHighlight()
    drawWordmark()
    draw(
        "Drag Notive into Applications to install",
        centeredAtX: windowWidth / 2,
        top: 148,
        size: 14,
        weight: .semibold,
        color: ivory(0.72)
    )
    let rowCenterY = fromTop(268)
    drawWaveform(centerX: windowWidth / 2, centerY: rowCenterY)
    drawDropZone(centerX: 545.5, centerY: rowCenterY)
    drawFooter()
}

func representation(scale: Int) -> NSBitmapImageRep? {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(windowWidth) * scale,
        pixelsHigh: Int(windowHeight) * scale,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { return nil }
    rep.size = NSSize(width: windowWidth, height: windowHeight)
    guard let context = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    drawBackground()
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

guard let oneX = representation(scale: 1), let twoX = representation(scale: 2) else {
    FileHandle.standardError.write(Data("Could not create the background bitmaps.\n".utf8))
    exit(1)
}
guard let data = NSBitmapImageRep.representationOfImageReps(
    in: [oneX, twoX],
    using: .tiff,
    properties: [.compressionMethod: NSBitmapImageRep.TIFFCompression.lzw.rawValue]
) else {
    FileHandle.standardError.write(Data("Could not encode the background image.\n".utf8))
    exit(1)
}
try data.write(to: outputURL)
