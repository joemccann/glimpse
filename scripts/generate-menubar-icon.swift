#!/usr/bin/env swift
import AppKit
import Foundation

// Get the script's directory and resolve relative to project root
let scriptPath = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let projectRoot = scriptPath.deletingLastPathComponent()
let outputDir = projectRoot.appendingPathComponent("Glimpse/Glimpse/Resources/Assets.xcassets/MenuBarIcon.imageset").path
let sizes: [(String, CGFloat)] = [
    ("menubar.png", 18),
    ("menubar@2x.png", 36),
    ("menubar@3x.png", 54)
]

// Ensure directory exists
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

for (filename, size) in sizes {
    let imageSize = NSSize(width: size, height: size)
    let image = NSImage(size: imageSize)

    image.lockFocus()

    let ctx = NSGraphicsContext.current!.cgContext
    ctx.setShouldAntialias(true)

    let w = size
    let h = size
    let padding = w * 0.12
    let lineWidth = size * 0.09

    // Faceted gem shape (matching app icon aesthetic)
    // More angular, geometric design
    let path = NSBezierPath()

    // Top point
    let top = NSPoint(x: w / 2, y: h - padding)
    // Upper left facet
    let upperLeft = NSPoint(x: padding + w * 0.08, y: h * 0.62)
    // Lower left
    let left = NSPoint(x: padding, y: h * 0.42)
    // Bottom point
    let bottom = NSPoint(x: w / 2, y: padding)
    // Lower right
    let right = NSPoint(x: w - padding, y: h * 0.42)
    // Upper right facet
    let upperRight = NSPoint(x: w - padding - w * 0.08, y: h * 0.62)

    // Draw outer gem shape
    path.move(to: top)
    path.line(to: upperRight)
    path.line(to: right)
    path.line(to: bottom)
    path.line(to: left)
    path.line(to: upperLeft)
    path.close()

    NSColor.black.setStroke()
    path.lineWidth = lineWidth
    path.lineJoinStyle = .miter
    path.stroke()

    // Inner facet line (crown to pavilion)
    let innerPath = NSBezierPath()
    innerPath.move(to: upperLeft)
    innerPath.line(to: upperRight)

    innerPath.lineWidth = lineWidth * 0.7
    NSColor.black.setStroke()
    innerPath.stroke()

    image.unlockFocus()

    if let tiffData = image.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        let url = URL(fileURLWithPath: "\(outputDir)/\(filename)")
        try? pngData.write(to: url)
    }
}

// Update Contents.json
let jsonContent = """
{
  "images" : [
    {
      "filename" : "menubar.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "menubar@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "menubar@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "preserves-vector-representation" : true,
    "template-rendering-intent" : "template"
  }
}
"""

try? jsonContent.write(toFile: "\(outputDir)/Contents.json", atomically: true, encoding: .utf8)

print("Menu bar icons generated in \(outputDir)")
